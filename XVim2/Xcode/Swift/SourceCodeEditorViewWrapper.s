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

# Save registers on stack

    leaq    -240(%rsp), %rsp
    andq    $0FFFFFFFFFFFFFFF0H, %rsp

    // Callee-saved
    movq    %rbx, (%rsp)
    movq    %r12, 8(%rsp)
    movq    %r13, 16(%rsp)
    movq    %r14, 24(%rsp)
    movq    %r15, 32(%rsp)

    // Shuffled args
    movq    %rdi, 40(%rsp)
    movq    %rsi, 48(%rsp)
    movq    %rdx, 56(%rsp)
    movq    %rcx, 64(%rsp)
    movq    %r8, 80(%rsp)
    movq    %r9, 96(%rsp)

    movdqa  %xmm0, 112(%rsp)
    movdqa  %xmm1, 128(%rsp)
    movdqa  %xmm2, 144(%rsp)
    movdqa  %xmm3, 160(%rsp)
    movdqa  %xmm4, 176(%rsp)
    movdqa  %xmm5, 192(%rsp)
    movdqa  %xmm6, 208(%rsp)
    movdqa  %xmm7, 224(%rsp)

# Body
    movq  (%rdi), %r13 # Load the target 'self'

    pushq  $0 # Keep 16-byte SP alignment
    pushq  8(%rdi)  # Push the target function

# Shuffle up arguments
    movq  %rsi, %rdi
    movq  %rdx, %rsi
    movq  %rcx, %rdx
    movq  %r8, %rcx
    movq  %r9, %r8

# CALL
    callq *(%rsp)

    addq $16, %rsp

# Restore registers from stack
    movq    (%rsp), %rbx
    movq    8(%rsp), %r12
    movq    16(%rsp), %r13
    movq    24(%rsp), %r14
    movq    32(%rsp), %r15

    // Shuffled args
    movq    40(%rsp), %rdi
    movq    48(%rsp), %rsi

    // RAX, RDX Used for return values
    // RCX Used for return values
    // R8 Used for return values

    movq    96(%rsp), %r9

    // XMM0-3 Used for return values
    movdqa  176(%rsp), %xmm4
    movdqa  192(%rsp), %xmm5
    movdqa  208(%rsp), %xmm6
    movdqa  224(%rsp), %xmm7

    leaq    240(%rsp), %rsp

# Cleanup
    movq %rbp, %rsp
    popq %rbp
    ret




