//
//  SourceCodeEditorViewWrapper.s
//  XVim2
//
//  Created by Ant on 23/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

.text
    .global _scev_wrapper_call
    .global _scev_wrapper_call2
    .global _scev_wrapper_call3
    .global _scev_wrapper_call4
    .global _scev_wrapper_call5
    .global _scev_wrapper_call6
    .global _scev_wrapper_call7
    .global _scev_wrapper_call8
    .global _scev_wrapper_call9

    .global _seds_wrapper_call
    .global _seds_wrapper_call2
    .global _seds_wrapper_call3
    .global _seds_wrapper_call4
    .global _seds_wrapper_call5
    .global _seds_wrapper_call6
    .global _seds_wrapper_call7
    .global _seds_wrapper_call8
    .global _seds_wrapper_call9

_scev_wrapper_call:
_scev_wrapper_call2:
_scev_wrapper_call3:
_scev_wrapper_call4:
_scev_wrapper_call5:
_scev_wrapper_call6:
_scev_wrapper_call7:
_scev_wrapper_call8:
_scev_wrapper_call9:

_seds_wrapper_call:
_seds_wrapper_call2:
_seds_wrapper_call3:
_seds_wrapper_call4:
_seds_wrapper_call5:
_seds_wrapper_call6:
_seds_wrapper_call7:
_seds_wrapper_call8:
_seds_wrapper_call9:

# Prolog
    pushq %rbp
    movq  %rsp, %rbp

# Allocate memory on stack

    leaq    -8(%rsp), %rsp # allocate 8 byte on stack

# Body

    # We passed UnsafeMutablePointer that allocate 8 byte * 8 memory as 1st argument from Invoker.
    # %rdi = contextPtr[0] = self (view)
    # %rdi + 8 = contextPtr[1] = target function pointer
    # %rdi + 16~56 is reserved for future use case. It can be passed as contextPtr[2~7]

    # Load the target 'self', this is Swift function calling convensions
    # https://github.com/apple/swift/blob/main/docs/ABI/RegisterUsage.md
    movq  (%rdi), %r13

    # 8 + 8 = 16 bytes is ok to keeping 16-byte SP alignment, no need allocate more.
    pushq  8(%rdi)  # Push the target function pointer to stack

# Shuffle up arguments

    # rest of integer arguments (2nd~6th) from Invoker = %rsi, %rdx, %rcx, %r8, %r9
    # that must be shuffle up to call target function.
    # Currently we support up to 4 (r9 register is not shuffled up) arguments
    # for integer that passed as register.
    movq  %rsi, %rdi
    movq  %rdx, %rsi
    movq  %rcx, %rdx
    movq  %r8, %rcx
    movq  %r9, %r8

# CALL
    callq *(%rsp)

    addq $8, %rsp

# Restore stack pointer position

    // RAX, RDX Used for return values
    // RCX Used for return values
    // R8 Used for return values

    // XMM0-3 Used for return values

    leaq    8(%rsp), %rsp

# Cleanup
    movq %rbp, %rsp
    popq %rbp
    ret
