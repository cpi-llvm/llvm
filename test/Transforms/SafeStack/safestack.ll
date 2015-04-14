; RUN: opt -safe-stack -S -mtriple=i386-pc-linux-gnu < %s -o - | FileCheck --check-prefix=CHECK --check-prefix=LINUX --check-prefix=LINUX-I386 %s
; RUN: opt -safe-stack -S -mtriple=x86_64-pc-linux-gnu < %s -o - | FileCheck --check-prefix=CHECK --check-prefix=LINUX --check-prefix=LINUX-X64 %s
; RUN: opt -safe-stack -S -mtriple=x86_64-apple-darwin < %s -o - | FileCheck --check-prefix=CHECK --check-prefix=DARWIN-X64 %s

%struct.foo = type { [16 x i8] }
%struct.foo.0 = type { [4 x i8] }
%struct.pair = type { i32, i32 }
%struct.nest = type { %struct.pair, %struct.pair }
%struct.vec = type { <4 x i32> }
%class.A = type { [2 x i8] }
%struct.deep = type { %union.anon }
%union.anon = type { %struct.anon }
%struct.anon = type { %struct.anon.0 }
%struct.anon.0 = type { %union.anon.1 }
%union.anon.1 = type { [2 x i8] }
%struct.small = type { i8 }

@.str = private unnamed_addr constant [4 x i8] c"%s\0A\00", align 1

; test0: no safestack attribute
; Requires no protector.

; CHECK-LABEL: @test0(
define void @test0(i8* %a) nounwind uwtable {
entry:
  ; CHECK-NOT: __safestack_unsafe_stack_ptr
  ; CHECK-NOT: addrspace
  %a.addr = alloca i8*, align 8
  %buf = alloca [16 x i8], align 16
  store i8* %a, i8** %a.addr, align 8
  %arraydecay = getelementptr inbounds [16 x i8], [16 x i8]* %buf, i32 0, i32 0
  %0 = load i8*, i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %arraydecay1 = getelementptr inbounds [16 x i8], [16 x i8]* %buf, i32 0, i32 0
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay1)
  ret void
}

; array of [16 x i8]

; CHECK-LABEL: @test1(
define void @test1(i8* %a) nounwind uwtable safestack {
entry:
  ; LINUX: %[[USP:.*]] = load i8*, i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: %[[USP:.*]] = load i8*, i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[USST:.*]] = getelementptr i8, i8* %[[USP]], i32 -16

  ; LINUX: store i8* %[[USST]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USST]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[AADDR:.*]] = alloca i8*, align 8
  %a.addr = alloca i8*, align 8

  ; CHECK: %[[BUFPTR:.*]] = getelementptr i8, i8* %[[USP]], i32 -16
  ; CHECK: %[[BUFPTR2:.*]] = bitcast i8* %[[BUFPTR]] to [16 x i8]*
  %buf = alloca [16 x i8], align 16

  ; CHECK: store i8* {{.*}}, i8** %[[AADDR]], align 8
  store i8* %a, i8** %a.addr, align 8

  ; CHECK: %[[GEP:.*]] = getelementptr inbounds [16 x i8], [16 x i8]* %[[BUFPTR2]], i32 0, i32 0
  %gep = getelementptr inbounds [16 x i8], [16 x i8]* %buf, i32 0, i32 0

  ; CHECK: %[[A2:.*]] = load i8*, i8** %[[AADDR]], align 8
  %a2 = load i8*, i8** %a.addr, align 8

  ; CHECK: call i8* @strcpy(i8* %[[GEP]], i8* %[[A2]])
  %call = call i8* @strcpy(i8* %gep, i8* %a2)

  ; LINUX: store i8* %[[USP]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USP]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)
  ret void
}

; struct { [16 x i8] }

; CHECK-LABEL: @test2(
define void @test2(i8* %a) nounwind uwtable safestack {
entry:
  ; LINUX: %[[USP:.*]] = load i8*, i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: %[[USP:.*]] = load i8*, i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[USST:.*]] = getelementptr i8, i8* %[[USP]], i32 -16

  ; LINUX: store i8* %[[USST]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USST]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[AADDR:.*]] = alloca i8*, align 8
  %a.addr = alloca i8*, align 8

  ; CHECK: %[[BUFPTR:.*]] = getelementptr i8, i8* %[[USP]], i32 -16
  ; CHECK: %[[BUFPTR2:.*]] = bitcast i8* %[[BUFPTR]] to %struct.foo*
  %buf = alloca %struct.foo, align 1

  ; CHECK: store i8* {{.*}}, i8** %[[AADDR]], align 8
  store i8* %a, i8** %a.addr, align 8

  ; CHECK: %[[GEP:.*]] = getelementptr inbounds %struct.foo, %struct.foo* %[[BUFPTR2]], i32 0, i32 0, i32 0
  %gep = getelementptr inbounds %struct.foo, %struct.foo* %buf, i32 0, i32 0, i32 0

  ; CHECK: %[[A:.*]] = load i8*, i8** %[[AADDR]], align 8
  %a2 = load i8*, i8** %a.addr, align 8

  ; CHECK: call i8* @strcpy(i8* %[[GEP]], i8* %[[A2]])
  %call = call i8* @strcpy(i8* %gep, i8* %a2)

  ; LINUX: store i8* %[[USP]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USP]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)
  ret void
}

; array [4 x i8]
; Requires protector.

; CHECK-LABEL: @test3(
define void @test3(i8* %a) nounwind uwtable safestack {
entry:
  ; LINUX: %[[USP:.*]] = load i8*, i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: %[[USP:.*]] = load i8*, i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[USST:.*]] = getelementptr i8, i8* %[[USP]], i32 -16

  ; LINUX: store i8* %[[USST]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USST]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)

  ; CHECK: %[[AADDR:.*]] = alloca i8*, align 8
  %a.addr = alloca i8*, align 8

  ; CHECK: %[[BUFPTR:.*]] = getelementptr i8, i8* %[[USP]], i32 -4
  ; CHECK: %[[BUFPTR2:.*]] = bitcast i8* %[[BUFPTR]] to [4 x i8]*
  %buf = alloca [4 x i8], align 1

  ; CHECK: store i8* {{.*}}, i8** %[[AADDR]], align 8
  store i8* %a, i8** %a.addr, align 8

  ; CHECK: %[[GEP:.*]] = getelementptr inbounds [4 x i8], [4 x i8]* %[[BUFPTR2]], i32 0, i32 0
  %gep = getelementptr inbounds [4 x i8], [4 x i8]* %buf, i32 0, i32 0

  ; CHECK: %[[A2:.*]] = load i8*, i8** %[[AADDR]], align 8
  %a2 = load i8*, i8** %a.addr, align 8

  ; CHECK: call i8* @strcpy(i8* %[[GEP]], i8* %[[A2]])
  %call = call i8* @strcpy(i8* %gep, i8* %a2)

  ; LINUX: store i8* %[[USP]], i8** @__safestack_unsafe_stack_ptr
  ; DARWIN-X64: store i8* %[[USP]], i8* addrspace(256)* inttoptr (i32 1536 to i8* addrspace(256)*)
  ret void
}

; no arrays / no nested arrays
; Requires no protector.

; CHECK-LABEL: @test4(
define void @test4(i8* %a) nounwind uwtable safestack {
entry:
  ; CHECK-NOT: __safestack_unsafe_stack_ptr
  ; CHECK-NOT: addrspace
  %a.addr = alloca i8*, align 8
  store i8* %a, i8** %a.addr, align 8
  %0 = load i8*, i8** %a.addr, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i8* %0)
  ret void
}

; Address-of local taken (j = &a)
; Requires protector.

; CHECK-LABEL: @test5(
define void @test5() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %retval = alloca i32, align 4
  %a = alloca i32, align 4
  %j = alloca i32*, align 8
  store i32 0, i32* %retval
  %0 = load i32, i32* %a, align 4
  %add = add nsw i32 %0, 1
  store i32 %add, i32* %a, align 4
  store i32* %a, i32** %j, align 8
  ret void
}

; PtrToInt Cast
; Requires no protector.

; CHECK-LABEL: @test6(
define void @test6() nounwind uwtable safestack {
entry:
  ; LINUX-NOT: __safestack_unsafe_stack_ptr
  ; DARWIN-X64-NOT: addrspace
  %a = alloca i32, align 4
  %0 = ptrtoint i32* %a to i64
  ret void
}

; Passing addr-of to function call
; Requires protector.
; CHECK-LABEL: @test7(
define void @test7() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %b = alloca i32, align 4
  call void @funcall(i32* %b) nounwind
  ret void
}

; test8:  Addr-of in select instruction
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test8(
define void @test8() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %x = alloca double, align 8
  %call = call double @testi_aux() nounwind
  store double %call, double* %x, align 8
  %cmp2 = fcmp ogt double %call, 0.000000e+00
  %y.1 = select i1 %cmp2, double* %x, double* null
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), double* %y.1)
  ret void
}

; test9: Addr-of in phi instruction
; Requires protector.
; CHECK-LABEL: @test9(
define void @test9() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %x = alloca double, align 8
  %call = call double @testi_aux() nounwind
  store double %call, double* %x, align 8
  %cmp = fcmp ogt double %call, 3.140000e+00
  br i1 %cmp, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %call1 = call double @testi_aux() nounwind
  store double %call1, double* %x, align 8
  br label %if.end4

if.else:                                          ; preds = %entry
  %cmp2 = fcmp ogt double %call, 1.000000e+00
  br i1 %cmp2, label %if.then3, label %if.end4

if.then3:                                         ; preds = %if.else
  br label %if.end4

if.end4:                                          ; preds = %if.else, %if.then3, %if.then
  %y.0 = phi double* [ null, %if.then ], [ %x, %if.then3 ], [ null, %if.else ]
  %call5 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), double* %y.0) nounwind
  ret void
}

; test10: Addr-of struct element. (GEP followed by store).
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test10(
define void @test10() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair, %struct.pair* %c, i32 0, i32 1
  store i32* %y, i32** %b, align 8
  %0 = load i32*, i32** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32* %0)
  ret void
}

; test11: Addr-of struct element, GEP followed by ptrtoint.
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test11(
define void @test11() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair, %struct.pair* %c, i32 0, i32 1
  %0 = ptrtoint i32* %y to i64
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i64 %0)
  ret void
}

; test12: Addr-of struct element, GEP followed by callinst.
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test12(
define void @test12() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %c = alloca %struct.pair, align 4
  %y = getelementptr inbounds %struct.pair, %struct.pair* %c, i64 0, i32 1
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32* %y) nounwind
  ret void
}

; test13: Addr-of a local, optimized into a GEP (e.g., &a - 12)
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test13(
define void @test13() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32, align 4
  %add.ptr5 = getelementptr inbounds i32, i32* %a, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), i32* %add.ptr5) nounwind
  ret void
}

; test14: Addr-of a local cast to a ptr of a different type
;           (e.g., int a; ... ; float *b = &a;)
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test14(
define void @test14() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32, align 4
  %b = alloca float*, align 8
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  store float* %0, float** %b, align 8
  %1 = load float*, float** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), float* %1)
  ret void
}

; test15: Addr-of a local cast to a ptr of a different type (optimized)
;           (e.g., int a; ... ; float *b = &a;)
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test15(
define void @test15() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32, align 4
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  call void @funfloat(float* %0) nounwind
  ret void
}

; test16: Addr-of a vector nested in a struct
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test16(
define void @test16() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %c = alloca %struct.vec, align 16
  %y = getelementptr inbounds %struct.vec, %struct.vec* %c, i64 0, i32 0
  %add.ptr = getelementptr inbounds <4 x i32>, <4 x i32>* %y, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i64 0, i64 0), <4 x i32>* %add.ptr) nounwind
  ret void
}

; test17: Addr-of a variable passed into an invoke instruction.
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test17(
define i32 @test17() uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32, align 4
  %exn.slot = alloca i8*
  %ehselector.slot = alloca i32
  store i32 0, i32* %a, align 4
  invoke void @_Z3exceptPi(i32* %a)
          to label %invoke.cont unwind label %lpad

invoke.cont:
  ret i32 0

lpad:
  %0 = landingpad { i8*, i32 } personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*)
          catch i8* null
  ret i32 0
}

; test18: Addr-of a struct element passed into an invoke instruction.
;           (GEP followed by an invoke)
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test18(
define i32 @test18() uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %c = alloca %struct.pair, align 4
  %exn.slot = alloca i8*
  %ehselector.slot = alloca i32
  %a = getelementptr inbounds %struct.pair, %struct.pair* %c, i32 0, i32 0
  store i32 0, i32* %a, align 4
  %a1 = getelementptr inbounds %struct.pair, %struct.pair* %c, i32 0, i32 0
  invoke void @_Z3exceptPi(i32* %a1)
          to label %invoke.cont unwind label %lpad

invoke.cont:
  ret i32 0

lpad:
  %0 = landingpad { i8*, i32 } personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*)
          catch i8* null
  ret i32 0
}

; test19: Addr-of a pointer
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test19(
define void @test19() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32*, align 8
  %b = alloca i32**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  store i32** %a, i32*** %b, align 8
  %0 = load i32**, i32*** %b, align 8
  call void @funcall2(i32** %0)
  ret void
}

; test20: Addr-of a casted pointer
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test20(
define void @test20() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %a = alloca i32*, align 8
  %b = alloca float**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  %0 = bitcast i32** %a to float**
  store float** %0, float*** %b, align 8
  %1 = load float**, float*** %b, align 8
  call void @funfloat2(float** %1)
  ret void
}

; test21: [2 x i8] in a class
;          safestack attribute
; Requires no protector.
; CHECK-LABEL: @test21(
define signext i8 @test21() nounwind uwtable safestack {
entry:
  ; LINUX-NOT: __safestack_unsafe_stack_ptr
  ; DARWIN-X64-NOT: addrspace
  %a = alloca %class.A, align 1
  %array = getelementptr inbounds %class.A, %class.A* %a, i32 0, i32 0
  %arrayidx = getelementptr inbounds [2 x i8], [2 x i8]* %array, i32 0, i64 0
  %0 = load i8, i8* %arrayidx, align 1
  ret i8 %0
}

; test22: [2 x i8] nested in several layers of structs and unions
;          safestack attribute
; Requires no protector.
; CHECK-LABEL: @test22(
define signext i8 @test22() nounwind uwtable safestack {
entry:
  ; LINUX-NOT: __safestack_unsafe_stack_ptr
  ; DARWIN-X64-NOT: addrspace
  %x = alloca %struct.deep, align 1
  %b = getelementptr inbounds %struct.deep, %struct.deep* %x, i32 0, i32 0
  %c = bitcast %union.anon* %b to %struct.anon*
  %d = getelementptr inbounds %struct.anon, %struct.anon* %c, i32 0, i32 0
  %e = getelementptr inbounds %struct.anon.0, %struct.anon.0* %d, i32 0, i32 0
  %array = bitcast %union.anon.1* %e to [2 x i8]*
  %arrayidx = getelementptr inbounds [2 x i8], [2 x i8]* %array, i32 0, i64 0
  %0 = load i8, i8* %arrayidx, align 1
  ret i8 %0
}

; test23: Variable sized alloca
;          safestack attribute
; Requires protector.
; CHECK-LABEL: @test23(
define void @test23(i32 %n) nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %n.addr = alloca i32, align 4
  %a = alloca i32*, align 8
  store i32 %n, i32* %n.addr, align 4
  %0 = load i32, i32* %n.addr, align 4
  %conv = sext i32 %0 to i64
  %1 = alloca i8, i64 %conv
  %2 = bitcast i8* %1 to i32*
  store i32* %2, i32** %a, align 8
  ret void
}

; test24: array of [4 x i32]
;          safestack attribute
; Requires no protector, constant index.
; CHECK-LABEL: @test24(
define i32 @test24() nounwind uwtable safestack {
entry:
  ; LINUX-NOT: __safestack_unsafe_stack_ptr
  ; DARWIN-X64-NOT: addrspace
  %a = alloca [4 x i32], align 16
  %arrayidx = getelementptr inbounds [4 x i32], [4 x i32]* %a, i32 0, i64 0
  %0 = load i32, i32* %arrayidx, align 4
  ret i32 %0
}

; test26: Nested structure, no arrays, no address-of expressions.
;         Verify that the resulting gep-of-gep does not incorrectly trigger
;         a safe stack protector.
;         safestack attribute
; Requires no protector.
; CHECK-LABEL: @test25(
define void @test25() nounwind uwtable safestack {
entry:
  ; LINUX-NOT: __safestack_unsafe_stack_ptr
  ; DARWIN-X64-NOT: addrspace
  %c = alloca %struct.nest, align 4
  %b = getelementptr inbounds %struct.nest, %struct.nest* %c, i32 0, i32 1
  %_a = getelementptr inbounds %struct.pair, %struct.pair* %b, i32 0, i32 0
  %0 = load i32, i32* %_a, align 4
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %0)
  ret void
}

; test27: Address-of a structure taken in a function with a loop where
;         the alloca is an incoming value to a PHI node and a use of that PHI
;         node is also an incoming value.
;         Verify that the address-of analysis does not get stuck in infinite
;         recursion when chasing the alloca through the PHI nodes.
; Requires protector.
; CHECK-LABEL: @test26(
define i32 @test26(i32 %arg) nounwind uwtable safestack {
bb:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %tmp = alloca %struct.small*, align 8
  %tmp1 = call i32 (...)* @dummy(%struct.small** %tmp) nounwind
  %tmp2 = load %struct.small*, %struct.small** %tmp, align 8
  %tmp3 = ptrtoint %struct.small* %tmp2 to i64
  %tmp4 = trunc i64 %tmp3 to i32
  %tmp5 = icmp sgt i32 %tmp4, 0
  br i1 %tmp5, label %bb6, label %bb21

bb6:                                              ; preds = %bb17, %bb
  %tmp7 = phi %struct.small* [ %tmp19, %bb17 ], [ %tmp2, %bb ]
  %tmp8 = phi i64 [ %tmp20, %bb17 ], [ 1, %bb ]
  %tmp9 = phi i32 [ %tmp14, %bb17 ], [ %tmp1, %bb ]
  %tmp10 = getelementptr inbounds %struct.small, %struct.small* %tmp7, i64 0, i32 0
  %tmp11 = load i8, i8* %tmp10, align 1
  %tmp12 = icmp eq i8 %tmp11, 1
  %tmp13 = add nsw i32 %tmp9, 8
  %tmp14 = select i1 %tmp12, i32 %tmp13, i32 %tmp9
  %tmp15 = trunc i64 %tmp8 to i32
  %tmp16 = icmp eq i32 %tmp15, %tmp4
  br i1 %tmp16, label %bb21, label %bb17

bb17:                                             ; preds = %bb6
  %tmp18 = getelementptr inbounds %struct.small*, %struct.small** %tmp, i64 %tmp8
  %tmp19 = load %struct.small*, %struct.small** %tmp18, align 8
  %tmp20 = add i64 %tmp8, 1
  br label %bb6

bb21:                                             ; preds = %bb6, %bb
  %tmp22 = phi i32 [ %tmp1, %bb ], [ %tmp14, %bb6 ]
  %tmp23 = call i32 (...)* @dummy(i32 %tmp22) nounwind
  ret i32 undef
}

%struct.__jmp_buf_tag = type { [8 x i64], i32, %struct.__sigset_t }
%struct.__sigset_t = type { [16 x i64] }
@buf = internal global [1 x %struct.__jmp_buf_tag] zeroinitializer, align 16

; test28: setjmp/longjmp test.
; Requires protector.
; CHECK-LABEL: @test27(
define i32 @test27() nounwind uwtable safestack {
entry:
  ; LINUX: __safestack_unsafe_stack_ptr
  ; DARWIN-X64: addrspace
  %retval = alloca i32, align 4
  %x = alloca i32, align 4
  store i32 0, i32* %retval
  store i32 42, i32* %x, align 4
  %call = call i32 @_setjmp(%struct.__jmp_buf_tag* getelementptr inbounds ([1 x %struct.__jmp_buf_tag], [1 x %struct.__jmp_buf_tag]* @buf, i32 0, i32 0)) #3
  %tobool = icmp ne i32 %call, 0
  br i1 %tobool, label %if.else, label %if.then
if.then:                                          ; preds = %entry
  call void @funcall(i32* %x)
  br label %if.end
if.else:                                          ; preds = %entry
  call i32 (...)* @dummy()
  br label %if.end
if.end:                                           ; preds = %if.else, %if.then
  ret i32 0
}

declare i32 @_setjmp(%struct.__jmp_buf_tag*)

declare double @testi_aux()
declare i8* @strcpy(i8*, i8*)
declare i32 @printf(i8*, ...)
declare void @funcall(i32*)
declare void @funcall2(i32**)
declare void @funfloat(float*)
declare void @funfloat2(float**)
declare void @_Z3exceptPi(i32*)
declare i32 @__gxx_personality_v0(...)
declare i32* @getp()
declare i32 @dummy(...)
