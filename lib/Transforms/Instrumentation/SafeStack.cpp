//===-- SafeStack.cpp - Safe Stack Insertion ------------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This pass splits the stack into the safe stack (kept as-is for LLVM backend)
// and the unsafe stack (explicitly allocated and managed through the runtime
// support library).
//
//===----------------------------------------------------------------------===//

#define DEBUG_TYPE "safestack"
#include "llvm/Transforms/Instrumentation.h"
#include "llvm/ADT/Statistic.h"
#include "llvm/ADT/Triple.h"
#include "llvm/Analysis/AliasAnalysis.h"
#include "llvm/Analysis/TargetTransformInfo.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DataLayout.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/DIBuilder.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/Module.h"
#include "llvm/Pass.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Debug.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/raw_os_ostream.h"
#include "llvm/Transforms/Utils/Local.h"
#include "llvm/Transforms/Utils/ModuleUtils.h"

using namespace llvm;

namespace llvm {

STATISTIC(NumFunctions, "Total number of functions");
STATISTIC(NumUnsafeStackFunctions, "Number of functions with unsafe stack");
STATISTIC(NumUnsafeStackRestorePointsFunctions,
          "Number of functions that use setjmp or exceptions");

STATISTIC(NumAllocas, "Total number of allocas");
STATISTIC(NumUnsafeStaticAllocas, "Number of unsafe static allocas");
STATISTIC(NumUnsafeDynamicAllocas, "Number of unsafe dynamic allocas");
STATISTIC(NumUnsafeStackRestorePoints, "Number of setjmps and landingpads");

} // namespace llvm

namespace {

/// Check whether a given alloca instructino (AI) should be put on the safe
/// stack or not. The function analyzes all uses of AI and checks whether it is
/// only accessed in a memory safe way (as decided statically).
bool IsSafeStackAlloca(const AllocaInst *AI, const DataLayout *) {
  // Go through all uses of this alloca and check whether all accesses to the
  // allocated object are statically known to be memory safe and, hence, the
  // object can be placed on the safe stack.

  SmallPtrSet<const Value*, 16> Visited;
  SmallVector<const Instruction*, 8> WorkList;
  WorkList.push_back(AI);

  // A DFS search through all uses of the alloca in bitcasts/PHI/GEPs/etc.
  while (!WorkList.empty()) {
    const Instruction *V = WorkList.pop_back_val();
    for (const Use &UI : V->uses()) {
      const Instruction *I = cast<const Instruction>(UI.getUser());
      assert(V == UI.get());

      switch (I->getOpcode()) {
      case Instruction::Load:
        // Loading from a pointer is safe
        break;
      case Instruction::VAArg:
        // "va-arg" from a pointer is safe
        break;
      case Instruction::Store:
        if (V == I->getOperand(0))
          // Stored the pointer - conservatively assume it may be unsafe
          return false;
        // Storing to the pointee is safe
        break;

      case Instruction::GetElementPtr:
        if (!cast<const GetElementPtrInst>(I)->hasAllConstantIndices())
          // GEP with non-constant indices can lead to memory errors
          return false;

        // We assume that GEP on static alloca with constant indices is safe,
        // otherwise a compiler would detect it and warn during compilation.

        if (!isa<const ConstantInt>(AI->getArraySize()))
          // However, if the array size itself is not constant, the access
          // might still be unsafe at runtime.
          return false;

        /* fallthough */

      case Instruction::BitCast:
      case Instruction::IntToPtr:
      case Instruction::PHI:
      case Instruction::PtrToInt:
      case Instruction::Select:
        // The object can be safe or not, depending on how the result of the
        // BitCast/PHI/Select/GEP/etc. is used.
        if (Visited.insert(I).second)
          WorkList.push_back(cast<const Instruction>(I));
        break;

      case Instruction::Call:
      case Instruction::Invoke: {
        ImmutableCallSite CS(I);

        // Given we don't care about information leak attacks at this point,
        // the object is considered safe if a pointer to it is passed to a
        // function that only reads memory nor returns any value. This function
        // can neither do unsafe writes itself nor capture the pointer (or
        // return it) to do unsafe writes to it elsewhere. The function also
        // shouldn't unwind (a readonly function can leak bits by throwing an
        // exception or not depending on the input value).
        if (CS.onlyReadsMemory() /* && CS.doesNotThrow()*/ &&
            I->getType()->isVoidTy())
          continue;

        // LLVM 'nocapture' attribute is only set for arguments whose address
        // is not stored, passed around, or used in any other non-trivial way.
        // We assume that passing a pointer to an object as a 'nocapture'
        // argument is safe.
        // FIXME: a more precise solution would require an interprocedural
        // analysis here, which would look at all uses of an argument inside
        // the function being called.
        ImmutableCallSite::arg_iterator B = CS.arg_begin(), E = CS.arg_end();
        for (ImmutableCallSite::arg_iterator A = B; A != E; ++A)
          if (A->get() == V && !CS.doesNotCapture(A - B))
            // The parameter is not marked 'nocapture' - unsafe
            return false;
        continue;
      }

      default:
        // The object is unsafe if it is used in any other way.
        return false;
      }
    }
  }

  // All uses of the alloca are safe, we can place it on the safe stack.
  return true;
}

/// The SafeStack pass splits the stack of each function into the
/// safe stack, which is only accessed through memory safe dereferences
/// (as determined statically), and the unsafe stack, which contains all
/// local variables that are accessed in unsafe ways.
class SafeStack : public ModulePass {
  const DataLayout *DL;

  AliasAnalysis *AA;

  Type *StackPtrTy;
  Type *IntPtrTy;
  Type *Int32Ty;
  Type *Int8Ty;

  bool haveFunctionsWithSafeStack(Module &M) {
    for (Function &F : M) {
      if (F.hasFnAttribute(Attribute::SafeStack))
        return true;
    }
    return false;
  }

  bool runOnFunction(Function &F);

  Constant *getOrCreateUnsafeStackPtr(Function &F);

public:
  static char ID; // Pass identification, replacement for typeid.
  SafeStack(): ModulePass(ID), DL(nullptr) {
    initializeSafeStackPass(*PassRegistry::getPassRegistry());
  }

  virtual void getAnalysisUsage(AnalysisUsage &AU) const {
    AU.addRequired<AliasAnalysis>();
    AU.addRequired<TargetTransformInfoWrapperPass>();
  }

  virtual bool runOnModule(Module &M) {
    DEBUG(dbgs() << "[SafeStack] Module: "
                 << M.getModuleIdentifier() << "\n");

    // Does the module have any functions that require safe stack?
    if (!haveFunctionsWithSafeStack(M)) {
      DEBUG(dbgs() << "[SafeStack] no functions to instrument\n");
      return false; // Nothing to do
    }

    AA = &getAnalysis<AliasAnalysis>();

    DL = &M.getDataLayout();

    StackPtrTy = Type::getInt8PtrTy(M.getContext());
    IntPtrTy = DL->getIntPtrType(M.getContext());
    Int32Ty = Type::getInt32Ty(M.getContext());
    Int8Ty = Type::getInt8Ty(M.getContext());

    // Add safe stack instrumentation to all functions that need it
    for (Function &F : M) {
      DEBUG(dbgs() << "[SafeStack] Function: " << F.getName() << "\n");

      if (!F.hasFnAttribute(Attribute::SafeStack)) {
        DEBUG(dbgs() << "[SafeStack]     safestack is not requested"
                        " for this function\n");
        continue;
      }

      if (F.isDeclaration()) {
        DEBUG(dbgs() << "[SafeStack]     function definition"
                        " is not available\n");
        continue;
      }

      {
        // Make sure the regular stack protector won't run on this function
        // (safestack attribute takes precedence)
        AttrBuilder B;
        B.addAttribute(Attribute::StackProtect)
            .addAttribute(Attribute::StackProtectReq)
            .addAttribute(Attribute::StackProtectStrong);
        F.removeAttributes(AttributeSet::FunctionIndex, AttributeSet::get(
              F.getContext(), AttributeSet::FunctionIndex, B));
      }

      if (AA->onlyReadsMemory(&F)) {
        // XXX: we don't protect against information leak attacks for now
        DEBUG(dbgs() << "[SafeStack]     function only reads memory\n");
        continue;
      }

      runOnFunction(F);
      DEBUG(dbgs() << "[SafeStack]     safestack applied\n");
    }

    return true;
  }
}; // class SafeStack

Constant *SafeStack::getOrCreateUnsafeStackPtr(Function &F) {
  const TargetTransformInfo *TTI =
      &getAnalysis<TargetTransformInfoWrapperPass>().getTTI(F);

  // Check where the unsafe stack pointer is stored on this architecture
  unsigned AddressSpace, Offset;
  if (TTI->getUnsafeStackPtrLocation(AddressSpace, Offset)) {
    // The unsafe stack pointer is stored at a fixed location
    // (usually in the thread control block)
    Constant *OffsetVal = ConstantInt::get(Int32Ty, Offset);
    return ConstantExpr::getIntToPtr(
        OffsetVal, Int8Ty->getPointerTo()->getPointerTo(AddressSpace));
  } else {
    // The unsafe stack pointer is stored in a global variable with a magic name
    // FIXME: share this constant between LLVM and compiler-rt
    // FIXME: make the name start with "llvm."
    static const char* unsafe_stack_ptr_var = "__safestack_unsafe_stack_ptr";

    auto UnsafeStackPtr = dyn_cast_or_null<GlobalVariable>(
          F.getParent()->getNamedValue(unsafe_stack_ptr_var));

    if (!UnsafeStackPtr) {
      // The global variable is not defined yet, define it ourselves
      UnsafeStackPtr = new GlobalVariable(
          /*Module=*/*F.getParent(), /*Type=*/Int8Ty->getPointerTo(),
          /*isConstant=*/false, /*Linkage=*/GlobalValue::ExternalLinkage,
          /*Initializer=*/0, /*Name=*/unsafe_stack_ptr_var,
          /*InsertBefore=*/nullptr,
          /*ThreadLocalMode=*/GlobalValue::InitialExecTLSModel);
    } else {
      // The variable exists, check its type and attributes
      if (UnsafeStackPtr->getValueType() != Int8Ty->getPointerTo()) {
        report_fatal_error(Twine(unsafe_stack_ptr_var) +
                           " must have void* type");
      }

      if (!UnsafeStackPtr->isThreadLocal()) {
        report_fatal_error(Twine(unsafe_stack_ptr_var) +
                           " must be thread-local");
      }
    }

    return UnsafeStackPtr;
  }
}

bool SafeStack::runOnFunction(Function &F) {
  ++NumFunctions;

  unsigned StackAlignment = 16;
  Constant *UnsafeStackPtr = getOrCreateUnsafeStackPtr(F);

  SmallVector<AllocaInst*, 16> StaticAllocas;
  SmallVector<AllocaInst*, 4> DynamicAllocas;
  SmallVector<ReturnInst*, 4> Returns;

  // Collect all points where stack gets unwound and needs to be restored
  // This is only necessary because the runtime (setjmp and unwind code) is
  // not aware of the unsafe stack and won't unwind/restore it prorerly.
  // To work around this problem without changing the runtime, we insert
  // instrumentation to restore the unsafe stack pointer when necessary.
  SmallVector<Instruction*, 4> StackRestorePoints;

  // Find all static and dynamic alloca instructions that must be moved to the
  // unsafe stack, all return instructions and stack restore points
  for (inst_iterator It = inst_begin(&F), Ie = inst_end(&F); It != Ie; ++It) {
    Instruction *I = &*It;

    if (AllocaInst *AI = dyn_cast<AllocaInst>(I)) {
      ++NumAllocas;

      if (IsSafeStackAlloca(AI, DL))
        continue;

      if (AI->isStaticAlloca()) {
        ++NumUnsafeStaticAllocas;
        StaticAllocas.push_back(AI);
      } else {
        ++NumUnsafeDynamicAllocas;
        DynamicAllocas.push_back(AI);
      }

    } else if (ReturnInst *RI = dyn_cast<ReturnInst>(I)) {
      Returns.push_back(RI);

    } else if (CallInst *CI = dyn_cast<CallInst>(I)) {
      // setjmps require stack restore
      if (CI->getCalledFunction() && CI->canReturnTwice())
          //CI->getCalledFunction()->getName() == "_setjmp")
        StackRestorePoints.push_back(CI);

    } else if (LandingPadInst *LP = dyn_cast<LandingPadInst>(I)) {
      // Excpetion landing pads require stack restore
      StackRestorePoints.push_back(LP);
    }
  }

  if (StaticAllocas.empty() && DynamicAllocas.empty() &&
      StackRestorePoints.empty())
    return false; // Nothing to do in this function

  if (!StaticAllocas.empty() || !DynamicAllocas.empty())
    ++NumUnsafeStackFunctions; // This function has the unsafe stack

  if (!StackRestorePoints.empty())
    ++NumUnsafeStackRestorePointsFunctions;

  DIBuilder DIB(*F.getParent());
  IRBuilder<> IRB(F.getEntryBlock().getFirstInsertionPt());

  // The top of the unsafe stack after all unsafe static allocas are allocated
  Value *StaticTop = NULL;

  if (!StaticAllocas.empty()) {
    // We explicitly compute and set the unsafe stack layout for all unsafe
    // static alloca instructions. We save the unsafe "base pointer" in the
    // prologue into a local variable and restore it in the epilogue.

    // Load the current stack pointer (we'll also use it as a base pointer)
    // FIXME: use a dedicated register for it ?
    Instruction *BasePointer = IRB.CreateLoad(UnsafeStackPtr, false,
                                              "unsafe_stack_ptr");
    assert(BasePointer->getType() == StackPtrTy);

    for (ReturnInst *RI : Returns) {
      IRB.SetInsertPoint(RI);
      IRB.CreateStore(BasePointer, UnsafeStackPtr);
    }

    // Compute maximum alignment among static objects on the unsafe stack
    unsigned MaxAlignment = 0;
    for (AllocaInst *AI : StaticAllocas) {
      Type *Ty = AI->getAllocatedType();
      unsigned Align =
        std::max((unsigned)DL->getPrefTypeAlignment(Ty), AI->getAlignment());
      if (Align > MaxAlignment)
        MaxAlignment = Align;
    }

    if (MaxAlignment > StackAlignment) {
      // Re-align the base pointer according to the max requested alignment
      assert(isPowerOf2_32(MaxAlignment));
      IRB.SetInsertPoint(cast<Instruction>(BasePointer->getNextNode()));
      BasePointer = cast<Instruction>(IRB.CreateIntToPtr(
          IRB.CreateAnd(IRB.CreatePtrToInt(BasePointer, IntPtrTy),
                        ConstantInt::get(IntPtrTy, ~uint64_t(MaxAlignment-1))),
          StackPtrTy));
    }

    // Allocate space for every unsafe static AllocaInst on the unsafe stack
    int64_t StaticOffset = 0; // Current stack top
    for (AllocaInst *AI : StaticAllocas) {
      IRB.SetInsertPoint(AI);

      ConstantInt *CArraySize = cast<ConstantInt>(AI->getArraySize());
      Type *Ty = AI->getAllocatedType();

      uint64_t Size = DL->getTypeAllocSize(Ty) * CArraySize->getZExtValue();
      if (Size == 0) Size = 1; // Don't create zero-sized stack objects.

      // Ensure the object is properly aligned
      unsigned Align =
        std::max((unsigned)DL->getPrefTypeAlignment(Ty), AI->getAlignment());

      // Add alignment
      // NOTE: we ensure that BasePointer itself is aligned to >= Align
      StaticOffset += Size;
      StaticOffset = (StaticOffset + Align - 1) / Align * Align;

      Value *Off = IRB.CreateGEP(BasePointer, // BasePointer is i8*
                      ConstantInt::get(Int32Ty, -StaticOffset));
      Value *NewAI = IRB.CreateBitCast(Off, AI->getType(), AI->getName());
      if (AI->hasName() && isa<Instruction>(NewAI))
        cast<Instruction>(NewAI)->takeName(AI);

      // Replace alloc with the new location
      replaceDbgDeclareForAlloca(AI, NewAI, DIB, /*Deref=*/true);
      AI->replaceAllUsesWith(NewAI);
      AI->eraseFromParent();
    }

    // Re-align BasePointer so that our callees would see it aligned as expected
    // FIXME: no need to update BasePointer in leaf functions
    StaticOffset = (StaticOffset + StackAlignment - 1)
                    / StackAlignment * StackAlignment;

    // Update shadow stack pointer in the function epilogue
    IRB.SetInsertPoint(cast<Instruction>(BasePointer->getNextNode()));

    StaticTop = IRB.CreateGEP(BasePointer,
           ConstantInt::get(Int32Ty, -StaticOffset), "unsafe_stack_static_top");
    IRB.CreateStore(StaticTop, UnsafeStackPtr);
  }

  IRB.SetInsertPoint(
          StaticTop ? cast<Instruction>(StaticTop)->getNextNode()
                    : (Instruction*) F.getEntryBlock().getFirstInsertionPt());

  // Safe stack object that stores the current unsafe stack top. It is updated
  // as unsafe dynamic (non-constant-sized) allocas are allocated and freed.
  // This is only needed if we need to restore stack pointer after longjmp
  // or exceptions.
  // FIXME: a better alternative might be to store the unsafe stack pointer
  // before setjmp / invoke instructions.
  AllocaInst *DynamicTop = NULL;

  if (!StackRestorePoints.empty()) {
    // We need the current value of the shadow stack pointer to restore
    // after longjmp or exception catching.

    // FIXME: in the future, this should be handled by the longjmp/exception
    // runtime itself

    if (!DynamicAllocas.empty()) {
      // If we also have dynamic alloca's, the stack pointer value changes
      // throughout the function. For now we store it in an allca.
      DynamicTop = IRB.CreateAlloca(StackPtrTy, 0, "unsafe_stack_dynamic_ptr");
    }

    if (!StaticTop) {
      // We need to original unsafe stack pointer value, even if there are
      // no unsafe static allocas
      StaticTop = IRB.CreateLoad(UnsafeStackPtr, false, "unsafe_stack_ptr");
    }

    if (!DynamicAllocas.empty()) {
      IRB.CreateStore(StaticTop, DynamicTop);
    }
  }

  // Handle dynamic alloca now
  for (AllocaInst *AI : DynamicAllocas) {
    IRB.SetInsertPoint(AI);

    // Compute the new SP value (after AI)
    Value *ArraySize = AI->getArraySize();
    if (ArraySize->getType() != IntPtrTy)
      ArraySize = IRB.CreateIntCast(ArraySize, IntPtrTy, false);

    Type *Ty = AI->getAllocatedType();
    uint64_t TySize = DL->getTypeAllocSize(Ty);
    Value *Size = IRB.CreateMul(ArraySize, ConstantInt::get(IntPtrTy, TySize));

    Value *SP = IRB.CreatePtrToInt(IRB.CreateLoad(UnsafeStackPtr), IntPtrTy);
    SP = IRB.CreateSub(SP, Size);

    // Align the SP value to satisfy the AllocaInst, type and stack alignments
    unsigned Align = std::max(
      std::max((unsigned)DL->getPrefTypeAlignment(Ty), AI->getAlignment()),
      (unsigned) StackAlignment);

    assert(isPowerOf2_32(Align));
    Value *NewTop = IRB.CreateIntToPtr(
        IRB.CreateAnd(SP, ConstantInt::get(IntPtrTy, ~uint64_t(Align-1))),
        StackPtrTy);

    // Save the stack pointer
    IRB.CreateStore(NewTop, UnsafeStackPtr);
    if (DynamicTop) {
      IRB.CreateStore(NewTop, DynamicTop);
    }

    Value *NewAI = IRB.CreateIntToPtr(SP, AI->getType());
    if (AI->hasName() && isa<Instruction>(NewAI))
      NewAI->takeName(AI);

    replaceDbgDeclareForAlloca(AI, NewAI, DIB, /*Deref=*/true);
    AI->replaceAllUsesWith(NewAI);
    AI->eraseFromParent();
  }

  if (!DynamicAllocas.empty()) {
    // Now go through the instructions again, replacing stacksave/stackrestore
    for (inst_iterator It = inst_begin(&F), Ie = inst_end(&F); It != Ie;) {
      Instruction *I = &*(It++);
      IntrinsicInst *II = dyn_cast<IntrinsicInst>(I);
      if (!II)
        continue;

      if (II->getIntrinsicID() == Intrinsic::stacksave) {
        IRB.SetInsertPoint(II);
        Instruction *LI = IRB.CreateLoad(UnsafeStackPtr);
        LI->takeName(II);
        II->replaceAllUsesWith(LI);
        II->eraseFromParent();
      } else if (II->getIntrinsicID() == Intrinsic::stackrestore) {
        IRB.SetInsertPoint(II);
        Instruction *SI = IRB.CreateStore(II->getArgOperand(0), UnsafeStackPtr);
        SI->takeName(II);
        assert(II->use_empty());
        II->eraseFromParent();
      }
    }
  }

  // Restore current stack pointer after longjmp/exception catch
  for (Instruction *I : StackRestorePoints) {
    ++NumUnsafeStackRestorePoints;

    IRB.SetInsertPoint(cast<Instruction>(I->getNextNode()));
    Value *CurrentTop = DynamicTop ? IRB.CreateLoad(DynamicTop) : StaticTop;
    IRB.CreateStore(CurrentTop, UnsafeStackPtr);
  }

  return true;
}

} // end anonymous namespace

char SafeStack::ID = 0;
INITIALIZE_PASS_BEGIN(SafeStack, "safe-stack",
                      "Safe Stack instrumentation pass", false, false)
INITIALIZE_PASS_DEPENDENCY(TargetTransformInfoWrapperPass)
INITIALIZE_PASS_END(SafeStack, "safe-stack",
                    "Safe Stack instrumentation pass", false, false)


ModulePass *llvm::createSafeStackPass() {
  return new SafeStack();
}
