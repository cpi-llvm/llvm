; RUN: llc -mtriple=i386-pc-linux-gnu < %s -o - | FileCheck --check-prefix=LINUX-I386 %s
; RUN: llc -mtriple=x86_64-pc-linux-gnu < %s -o - | FileCheck --check-prefix=LINUX-X64 %s
; RUN: llc -mtriple=x86_64-apple-darwin < %s -o - | FileCheck --check-prefix=DARWIN-X64 %s

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

; test1a: array of [16 x i8] 
;         no safestack attribute
; Requires no protector.
define void @test1a(i8* %a) nounwind uwtable {
entry:
; LINUX-I386: test1a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test1a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test1a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %buf = alloca [16 x i8], align 16
  store i8* %a, i8** %a.addr, align 8
  %arraydecay = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %arraydecay1 = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay1)
  ret void
}

; test1b: array of [16 x i8] 
;         safestack attribute
; Requires protector.
define void @test1b(i8* %a) nounwind uwtable safestack {
entry:
; LINUX-I386: test1b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test1b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test1b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %buf = alloca [16 x i8], align 16
  store i8* %a, i8** %a.addr, align 8
  %arraydecay = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %arraydecay1 = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay1)
  ret void
}

; test2a: struct { [16 x i8] }
;         no safestack attribute
; Requires no protector.
define void @test2a(i8* %a) nounwind uwtable {
entry:
; LINUX-I386: test2a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test2a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test2a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %b = alloca %struct.foo, align 1
  store i8* %a, i8** %a.addr, align 8
  %buf = getelementptr inbounds %struct.foo* %b, i32 0, i32 0
  %arraydecay = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %buf1 = getelementptr inbounds %struct.foo* %b, i32 0, i32 0
  %arraydecay2 = getelementptr inbounds [16 x i8]* %buf1, i32 0, i32 0
  %call3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay2)
  ret void
}

; test2b: struct { [16 x i8] }
;          safestack attribute
; Requires protector.
define void @test2b(i8* %a) nounwind uwtable safestack {
entry:
; LINUX-I386: test2b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test2b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test2b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %b = alloca %struct.foo, align 1
  store i8* %a, i8** %a.addr, align 8
  %buf = getelementptr inbounds %struct.foo* %b, i32 0, i32 0
  %arraydecay = getelementptr inbounds [16 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %buf1 = getelementptr inbounds %struct.foo* %b, i32 0, i32 0
  %arraydecay2 = getelementptr inbounds [16 x i8]* %buf1, i32 0, i32 0
  %call3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay2)
  ret void
}

; test3a:  array of [4 x i8]
;          no safestack attribute
; Requires no protector.
define void @test3a(i8* %a) nounwind uwtable {
entry:
; LINUX-I386: test3a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test3a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test3a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %buf = alloca [4 x i8], align 1
  store i8* %a, i8** %a.addr, align 8
  %arraydecay = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %arraydecay1 = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay1)
  ret void
}

; test3b:  array [4 x i8]
;          safestack attribute
; Requires protector.
define void @test3b(i8* %a) nounwind uwtable safestack {
entry:
; LINUX-I386: test3b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test3b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test3b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %buf = alloca [4 x i8], align 1
  store i8* %a, i8** %a.addr, align 8
  %arraydecay = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %arraydecay1 = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay1)
  ret void
}

; test4a:  struct { [4 x i8] }
;          no safestack attribute
; Requires no protector.
define void @test4a(i8* %a) nounwind uwtable {
entry:
; LINUX-I386: test4a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test4a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test4a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %b = alloca %struct.foo.0, align 1
  store i8* %a, i8** %a.addr, align 8
  %buf = getelementptr inbounds %struct.foo.0* %b, i32 0, i32 0
  %arraydecay = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %buf1 = getelementptr inbounds %struct.foo.0* %b, i32 0, i32 0
  %arraydecay2 = getelementptr inbounds [4 x i8]* %buf1, i32 0, i32 0
  %call3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay2)
  ret void
}

; test4b:  struct { [4 x i8] }
;          safestack attribute
; Requires protector.
define void @test4b(i8* %a) nounwind uwtable safestack {
entry:
; LINUX-I386: test4b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test4b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test4b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  %b = alloca %struct.foo.0, align 1
  store i8* %a, i8** %a.addr, align 8
  %buf = getelementptr inbounds %struct.foo.0* %b, i32 0, i32 0
  %arraydecay = getelementptr inbounds [4 x i8]* %buf, i32 0, i32 0
  %0 = load i8** %a.addr, align 8
  %call = call i8* @strcpy(i8* %arraydecay, i8* %0)
  %buf1 = getelementptr inbounds %struct.foo.0* %b, i32 0, i32 0
  %arraydecay2 = getelementptr inbounds [4 x i8]* %buf1, i32 0, i32 0
  %call3 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %arraydecay2)
  ret void
}

; test5a:  no arrays / no nested arrays
;          no safestack attribute
; Requires no protector.
define void @test5a(i8* %a) nounwind uwtable {
entry:
; LINUX-I386: test5a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test5a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test5a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  store i8* %a, i8** %a.addr, align 8
  %0 = load i8** %a.addr, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %0)
  ret void
}

; test5b:  no arrays / no nested arrays
;          safestack attribute
; Requires no protector.
define void @test5b(i8* %a) nounwind uwtable safestack {
entry:
; LINUX-I386: test5b:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test5b:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test5b:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a.addr = alloca i8*, align 8
  store i8* %a, i8** %a.addr, align 8
  %0 = load i8** %a.addr, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i8* %0)
  ret void
}

; test6a:  Address-of local taken (j = &a)
;          no safestack attribute
; Requires no protector.
define void @test6a() nounwind uwtable {
entry:
; LINUX-I386: test6a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test6a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test6a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %retval = alloca i32, align 4
  %a = alloca i32, align 4
  %j = alloca i32*, align 8
  store i32 0, i32* %retval
  %0 = load i32* %a, align 4
  %add = add nsw i32 %0, 1
  store i32 %add, i32* %a, align 4
  store i32* %a, i32** %j, align 8
  ret void
}

; test6b:  Address-of local taken (j = &a)
;          safestack attribute
; Requires protector.
define void @test6b() nounwind uwtable safestack {
entry:
; LINUX-I386: test6b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test6b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test6b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %retval = alloca i32, align 4
  %a = alloca i32, align 4
  %j = alloca i32*, align 8
  store i32 0, i32* %retval
  %0 = load i32* %a, align 4
  %add = add nsw i32 %0, 1
  store i32 %add, i32* %a, align 4
  store i32* %a, i32** %j, align 8
  ret void
}

; test7a:  PtrToInt Cast
;          no safestack attribute
; Requires no protector.
define void @test7a() nounwind uwtable readnone {
entry:
; LINUX-I386: test7a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test7a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test7a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %0 = ptrtoint i32* %a to i64
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i64 %0)
  ret void
}

; test7b:  PtrToInt Cast
;          safestack attribute
; Requires no protector.
define void @test7b() nounwind uwtable readnone safestack {
entry:
; LINUX-I386: test7b:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test7b:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test7b:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %0 = ptrtoint i32* %a to i64
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i64 %0)
  ret void
}

; test8a:  Passing addr-of to function call
;          no safestack attribute
; Requires no protector.
define void @test8a() nounwind uwtable {
entry:
; LINUX-I386: test8a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test8a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test8a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %b = alloca i32, align 4
  call void @funcall(i32* %b) nounwind
  ret void
}

; test8b:  Passing addr-of to function call
;          safestack attribute
; Requires protector.
define void @test8b() nounwind uwtable safestack {
entry:
; LINUX-I386: test8b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test8b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test8b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %b = alloca i32, align 4
  call void @funcall(i32* %b) nounwind
  ret void
}

; test9a:  Addr-of in select instruction
;          no safestack attribute
; Requires no protector.
define void @test9a() nounwind uwtable {
entry:
; LINUX-I386: test9a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test9a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test9a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %x = alloca double, align 8
  %call = call double @testi_aux() nounwind
  store double %call, double* %x, align 8
  %cmp2 = fcmp ogt double %call, 0.000000e+00
  %y.1 = select i1 %cmp2, double* %x, double* null
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), double* %y.1)
  ret void
}

; test9b:  Addr-of in select instruction
;          safestack attribute
; Requires protector.
define void @test9b() nounwind uwtable safestack {
entry:
; LINUX-I386: test9b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test9b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test9b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %x = alloca double, align 8
  %call = call double @testi_aux() nounwind
  store double %call, double* %x, align 8
  %cmp2 = fcmp ogt double %call, 0.000000e+00
  %y.1 = select i1 %cmp2, double* %x, double* null
  %call2 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), double* %y.1)
  ret void
}

; test10a: Addr-of in phi instruction
;          no safestack attribute
; Requires no protector.
define void @test10a() nounwind uwtable {
entry:
; LINUX-I386: test10a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test10a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test10a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
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
  %call5 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), double* %y.0) nounwind
  ret void
}

; test10b: Addr-of in phi instruction
;          safestack attribute
; Requires protector.
define void @test10b() nounwind uwtable safestack {
entry:
; LINUX-I386: test10b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test10b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test10b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
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
  %call5 = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), double* %y.0) nounwind
  ret void
}

; test11a: Addr-of struct element. (GEP followed by store).
;          no safestack attribute
; Requires no protector.
define void @test11a() nounwind uwtable {
entry:
; LINUX-I386: test11a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test11a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test11a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair* %c, i32 0, i32 1
  store i32* %y, i32** %b, align 8
  %0 = load i32** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i32* %0)
  ret void
}

; test11b: Addr-of struct element. (GEP followed by store).
;          safestack attribute
; Requires protector.
define void @test11b() nounwind uwtable safestack {
entry:
; LINUX-I386: test11b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test11b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test11b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair* %c, i32 0, i32 1
  store i32* %y, i32** %b, align 8
  %0 = load i32** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i32* %0)
  ret void
}

; test12a: Addr-of struct element, GEP followed by ptrtoint.
;          no safestack attribute
; Requires no protector.
define void @test12a() nounwind uwtable {
entry:
; LINUX-I386: test12a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test12a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test12a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair* %c, i32 0, i32 1
  %0 = ptrtoint i32* %y to i64
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i64 %0)
  ret void
}

; test12b: Addr-of struct element, GEP followed by ptrtoint.
;          safestack attribute
; Requires protector.
define void @test12b() nounwind uwtable safestack {
entry:
; LINUX-I386: test12b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test12b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test12b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %b = alloca i32*, align 8
  %y = getelementptr inbounds %struct.pair* %c, i32 0, i32 1
  %0 = ptrtoint i32* %y to i64
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i64 %0)
  ret void
}

; test13a: Addr-of struct element, GEP followed by callinst.
;          no safestack attribute
; Requires no protector.
define void @test13a() nounwind uwtable {
entry:
; LINUX-I386: test13a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test13a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test13a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %y = getelementptr inbounds %struct.pair* %c, i64 0, i32 1
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), i32* %y) nounwind
  ret void
}

; test13b: Addr-of struct element, GEP followed by callinst.
;          safestack attribute
; Requires protector.
define void @test13b() nounwind uwtable safestack {
entry:
; LINUX-I386: test13b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test13b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test13b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %y = getelementptr inbounds %struct.pair* %c, i64 0, i32 1
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), i32* %y) nounwind
  ret void
}

; test14a: Addr-of a local, optimized into a GEP (e.g., &a - 12)
;          no safestack attribute
; Requires no protector.
define void @test14a() nounwind uwtable {
entry:
; LINUX-I386: test14a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test14a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test14a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %add.ptr5 = getelementptr inbounds i32* %a, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), i32* %add.ptr5) nounwind
  ret void
}

; test14b: Addr-of a local, optimized into a GEP (e.g., &a - 12)
;          safestack attribute
; Requires protector.
define void @test14b() nounwind uwtable safestack {
entry:
; LINUX-I386: test14b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test14b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test14b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %add.ptr5 = getelementptr inbounds i32* %a, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), i32* %add.ptr5) nounwind
  ret void
}

; test15a: Addr-of a local cast to a ptr of a different type
;           (e.g., int a; ... ; float *b = &a;)
;          no safestack attribute
; Requires no protector.
define void @test15a() nounwind uwtable {
entry:
; LINUX-I386: test15a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test15a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test15a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %b = alloca float*, align 8
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  store float* %0, float** %b, align 8
  %1 = load float** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), float* %1)
  ret void
}

; test15b: Addr-of a local cast to a ptr of a different type
;           (e.g., int a; ... ; float *b = &a;)
;          safestack attribute
; Requires protector.
define void @test15b() nounwind uwtable safestack {
entry:
; LINUX-I386: test15b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test15b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test15b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  %b = alloca float*, align 8
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  store float* %0, float** %b, align 8
  %1 = load float** %b, align 8
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), float* %1)
  ret void
}

; test16a: Addr-of a local cast to a ptr of a different type (optimized)
;           (e.g., int a; ... ; float *b = &a;)
;          no safestack attribute
; Requires no protector.
define void @test16a() nounwind uwtable {
entry:
; LINUX-I386: test16a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test16a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test16a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  call void @funfloat(float* %0) nounwind
  ret void
}

; test16b: Addr-of a local cast to a ptr of a different type (optimized)
;           (e.g., int a; ... ; float *b = &a;)
;          safestack attribute
; Requires protector.
define void @test16b() nounwind uwtable safestack {
entry:
; LINUX-I386: test16b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test16b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test16b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32, align 4
  store i32 0, i32* %a, align 4
  %0 = bitcast i32* %a to float*
  call void @funfloat(float* %0) nounwind
  ret void
}

; test17a: Addr-of a vector nested in a struct
;          no safestack attribute
; Requires no protector.
define void @test17a() nounwind uwtable {
entry:
; LINUX-I386: test17a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test17a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test17a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.vec, align 16
  %y = getelementptr inbounds %struct.vec* %c, i64 0, i32 0
  %add.ptr = getelementptr inbounds <4 x i32>* %y, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), <4 x i32>* %add.ptr) nounwind
  ret void
}

; test17b: Addr-of a vector nested in a struct
;          safestack attribute
; Requires protector.
define void @test17b() nounwind uwtable safestack {
entry:
; LINUX-I386: test17b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test17b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test17b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.vec, align 16
  %y = getelementptr inbounds %struct.vec* %c, i64 0, i32 0
  %add.ptr = getelementptr inbounds <4 x i32>* %y, i64 -12
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i64 0, i64 0), <4 x i32>* %add.ptr) nounwind
  ret void
}

; test18a: Addr-of a variable passed into an invoke instruction.
;          no safestack attribute
; Requires no protector.
define i32 @test18a() uwtable {
entry:
; LINUX-I386: test18a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test18a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test18a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
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

; test18b: Addr-of a variable passed into an invoke instruction.
;          safestack attribute
; Requires protector.
define i32 @test18b() uwtable safestack {
entry:
; LINUX-I386: test18b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test18b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test18b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
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

; test19a: Addr-of a struct element passed into an invoke instruction.
;           (GEP followed by an invoke)
;          no safestack attribute
; Requires no protector.
define i32 @test19a() uwtable {
entry:
; LINUX-I386: test19a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test19a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test19a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %exn.slot = alloca i8*
  %ehselector.slot = alloca i32
  %a = getelementptr inbounds %struct.pair* %c, i32 0, i32 0
  store i32 0, i32* %a, align 4
  %a1 = getelementptr inbounds %struct.pair* %c, i32 0, i32 0
  invoke void @_Z3exceptPi(i32* %a1)
          to label %invoke.cont unwind label %lpad

invoke.cont:
  ret i32 0

lpad:
  %0 = landingpad { i8*, i32 } personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*)
          catch i8* null
  ret i32 0
}

; test19b: Addr-of a struct element passed into an invoke instruction.
;           (GEP followed by an invoke)
;          safestack attribute
; Requires protector.
define i32 @test19b() uwtable safestack {
entry:
; LINUX-I386: test19b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test19b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test19b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.pair, align 4
  %exn.slot = alloca i8*
  %ehselector.slot = alloca i32
  %a = getelementptr inbounds %struct.pair* %c, i32 0, i32 0
  store i32 0, i32* %a, align 4
  %a1 = getelementptr inbounds %struct.pair* %c, i32 0, i32 0
  invoke void @_Z3exceptPi(i32* %a1)
          to label %invoke.cont unwind label %lpad

invoke.cont:
  ret i32 0

lpad:
  %0 = landingpad { i8*, i32 } personality i8* bitcast (i32 (...)* @__gxx_personality_v0 to i8*)
          catch i8* null
  ret i32 0
}

; test20a: Addr-of a pointer
;          no safestack attribute
; Requires no protector.
define void @test20a() nounwind uwtable {
entry:
; LINUX-I386: test20a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test20a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test20a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32*, align 8
  %b = alloca i32**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  store i32** %a, i32*** %b, align 8
  %0 = load i32*** %b, align 8
  call void @funcall2(i32** %0)
  ret void
}

; test20b: Addr-of a pointer
;          safestack attribute
; Requires protector.
define void @test20b() nounwind uwtable safestack {
entry:
; LINUX-I386: test20b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test20b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test20b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32*, align 8
  %b = alloca i32**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  store i32** %a, i32*** %b, align 8
  %0 = load i32*** %b, align 8
  call void @funcall2(i32** %0)
  ret void
}

; test21a: Addr-of a casted pointer
;          no safestack attribute
; Requires no protector.
define void @test21a() nounwind uwtable {
entry:
; LINUX-I386: test21a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test21a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test21a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32*, align 8
  %b = alloca float**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  %0 = bitcast i32** %a to float**
  store float** %0, float*** %b, align 8
  %1 = load float*** %b, align 8
  call void @funfloat2(float** %1)
  ret void
}

; test21b: Addr-of a casted pointer
;          safestack attribute
; Requires protector.
define void @test21b() nounwind uwtable safestack {
entry:
; LINUX-I386: test21b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test21b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test21b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca i32*, align 8
  %b = alloca float**, align 8
  %call = call i32* @getp()
  store i32* %call, i32** %a, align 8
  %0 = bitcast i32** %a to float**
  store float** %0, float*** %b, align 8
  %1 = load float*** %b, align 8
  call void @funfloat2(float** %1)
  ret void
}

; test22a: [2 x i8] in a class
;          no safestack attribute
; Requires no protector.
define signext i8 @test22a() nounwind uwtable {
entry:
; LINUX-I386: test22a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test22a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test22a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca %class.A, align 1
  %array = getelementptr inbounds %class.A* %a, i32 0, i32 0
  %arrayidx = getelementptr inbounds [2 x i8]* %array, i32 0, i64 0
  %0 = load i8* %arrayidx, align 1
  ret i8 %0
}

; test22b: [2 x i8] in a class
;          safestack attribute
; Requires no protector.
define signext i8 @test22b() nounwind uwtable safestack {
entry:
; LINUX-I386: test22b:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test22b:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test22b:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca %class.A, align 1
  %array = getelementptr inbounds %class.A* %a, i32 0, i32 0
  %arrayidx = getelementptr inbounds [2 x i8]* %array, i32 0, i64 0
  %0 = load i8* %arrayidx, align 1
  ret i8 %0
}

; test23a: [2 x i8] nested in several layers of structs and unions
;          no safestack attribute
; Requires no protector.
define signext i8 @test23a() nounwind uwtable {
entry:
; LINUX-I386: test23a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test23a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test23a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %x = alloca %struct.deep, align 1
  %b = getelementptr inbounds %struct.deep* %x, i32 0, i32 0
  %c = bitcast %union.anon* %b to %struct.anon*
  %d = getelementptr inbounds %struct.anon* %c, i32 0, i32 0
  %e = getelementptr inbounds %struct.anon.0* %d, i32 0, i32 0
  %array = bitcast %union.anon.1* %e to [2 x i8]*
  %arrayidx = getelementptr inbounds [2 x i8]* %array, i32 0, i64 0
  %0 = load i8* %arrayidx, align 1
  ret i8 %0
}

; test23b: [2 x i8] nested in several layers of structs and unions
;          safestack attribute
; Requires no protector.
define signext i8 @test23b() nounwind uwtable safestack {
entry:
; LINUX-I386: test23b:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test23b:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test23b:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %x = alloca %struct.deep, align 1
  %b = getelementptr inbounds %struct.deep* %x, i32 0, i32 0
  %c = bitcast %union.anon* %b to %struct.anon*
  %d = getelementptr inbounds %struct.anon* %c, i32 0, i32 0
  %e = getelementptr inbounds %struct.anon.0* %d, i32 0, i32 0
  %array = bitcast %union.anon.1* %e to [2 x i8]*
  %arrayidx = getelementptr inbounds [2 x i8]* %array, i32 0, i64 0
  %0 = load i8* %arrayidx, align 1
  ret i8 %0
}

; test24a: Variable sized alloca
;          no safestack attribute
; Requires no protector.
define void @test24a(i32 %n) nounwind uwtable {
entry:
; LINUX-I386: test24a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test24a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test24a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %n.addr = alloca i32, align 4
  %a = alloca i32*, align 8
  store i32 %n, i32* %n.addr, align 4
  %0 = load i32* %n.addr, align 4
  %conv = sext i32 %0 to i64
  %1 = alloca i8, i64 %conv
  %2 = bitcast i8* %1 to i32*
  store i32* %2, i32** %a, align 8
  ret void
}

; test24b: Variable sized alloca
;          safestack attribute
; Requires protector.
define void @test24b(i32 %n) nounwind uwtable safestack {
entry:
; LINUX-I386: test24b:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test24b:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test24b:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %n.addr = alloca i32, align 4
  %a = alloca i32*, align 8
  store i32 %n, i32* %n.addr, align 4
  %0 = load i32* %n.addr, align 4
  %conv = sext i32 %0 to i64
  %1 = alloca i8, i64 %conv
  %2 = bitcast i8* %1 to i32*
  store i32* %2, i32** %a, align 8
  ret void
}

; test25a: array of [4 x i32]
;          no safestack attribute
; Requires no protector.
define i32 @test25a() nounwind uwtable {
entry:
; LINUX-I386: test25a:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test25a:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test25a:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca [4 x i32], align 16
  %arrayidx = getelementptr inbounds [4 x i32]* %a, i32 0, i64 0
  %0 = load i32* %arrayidx, align 4
  ret i32 %0
}

; test25b: array of [4 x i32]
;          safestack attribute
; Requires no protector, constant index.
define i32 @test25b() nounwind uwtable safestack {
entry:
; LINUX-I386: test25b:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test25b:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test25b:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %a = alloca [4 x i32], align 16
  %arrayidx = getelementptr inbounds [4 x i32]* %a, i32 0, i64 0
  %0 = load i32* %arrayidx, align 4
  ret i32 %0
}

; test26: Nested structure, no arrays, no address-of expressions.
;         Verify that the resulting gep-of-gep does not incorrectly trigger
;         a safe stack protector.
;         safestack attribute
; Requires no protector.
define void @test26() nounwind uwtable safestack {
entry:
; LINUX-I386: test26:
; LINUX-I386-NOT: movl	__llvm__unsafe_stack_ptr
; LINUX-I386: .cfi_endproc

; LINUX-X64: test26:
; LINUX-X64-NOT: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test26:
; DARWIN-X64-NOT: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %c = alloca %struct.nest, align 4
  %b = getelementptr inbounds %struct.nest* %c, i32 0, i32 1
  %_a = getelementptr inbounds %struct.pair* %b, i32 0, i32 0
  %0 = load i32* %_a, align 4
  %call = call i32 (i8*, ...)* @printf(i8* getelementptr inbounds ([4 x i8]* @.str, i32 0, i32 0), i32 %0)
  ret void
}

; test27: Address-of a structure taken in a function with a loop where
;         the alloca is an incoming value to a PHI node and a use of that PHI 
;         node is also an incoming value.
;         Verify that the address-of analysis does not get stuck in infinite
;         recursion when chasing the alloca through the PHI nodes.
; Requires protector.
define i32 @test27(i32 %arg) nounwind uwtable safestack {
bb:
; LINUX-I386: test27:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:

; LINUX-I386: .cfi_endproc

; LINUX-X64: test27:
; LINUX-X64: movq	%fs:640
; LINUX-X64: .cfi_endproc

; DARWIN-X64: test27:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %tmp = alloca %struct.small*, align 8
  %tmp1 = call i32 (...)* @dummy(%struct.small** %tmp) nounwind
  %tmp2 = load %struct.small** %tmp, align 8
  %tmp3 = ptrtoint %struct.small* %tmp2 to i64
  %tmp4 = trunc i64 %tmp3 to i32
  %tmp5 = icmp sgt i32 %tmp4, 0
  br i1 %tmp5, label %bb6, label %bb21

bb6:                                              ; preds = %bb17, %bb
  %tmp7 = phi %struct.small* [ %tmp19, %bb17 ], [ %tmp2, %bb ]
  %tmp8 = phi i64 [ %tmp20, %bb17 ], [ 1, %bb ]
  %tmp9 = phi i32 [ %tmp14, %bb17 ], [ %tmp1, %bb ]
  %tmp10 = getelementptr inbounds %struct.small* %tmp7, i64 0, i32 0
  %tmp11 = load i8* %tmp10, align 1
  %tmp12 = icmp eq i8 %tmp11, 1
  %tmp13 = add nsw i32 %tmp9, 8
  %tmp14 = select i1 %tmp12, i32 %tmp13, i32 %tmp9
  %tmp15 = trunc i64 %tmp8 to i32
  %tmp16 = icmp eq i32 %tmp15, %tmp4
  br i1 %tmp16, label %bb21, label %bb17

bb17:                                             ; preds = %bb6
  %tmp18 = getelementptr inbounds %struct.small** %tmp, i64 %tmp8
  %tmp19 = load %struct.small** %tmp18, align 8
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
define i32 @test28() nounwind uwtable safestack {
entry:
; LINUX-I386: test28:
; LINUX-I386: movl	__llvm__unsafe_stack_ptr
; LINUX-I386-NEXT: movl	%gs:
; LINUX-I386: .cfi_endproc

; LINUX-X64: test28:
; LINUX-X64: movq	%fs:640
; LINUX-X64: movq	{{.*}}, %fs:640
; LINUX-X64: movq	{{.*}}, %fs:640

; LINUX-X64: .cfi_endproc

; DARWIN-X64: test28:
; DARWIN-X64: movq	___llvm__unsafe_stack_ptr
; DARWIN-X64: .cfi_endproc
  %retval = alloca i32, align 4
  %x = alloca i32, align 4
  store i32 0, i32* %retval
  store i32 42, i32* %x, align 4
  %call = call i32 @_setjmp(%struct.__jmp_buf_tag* getelementptr inbounds ([1 x %struct.__jmp_buf_tag]* @buf, i32 0, i32 0)) #3
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
