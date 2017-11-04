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
    leaq    -208(%rsp), %rsp
    andq    $0FFFFFFFFFFFFFFF0H, %rsp
    movq    %rbx, (%rsp)
    movq    %r12, 8(%rsp)
    movq    %r13, 16(%rsp)
    movq    %r14, 24(%rsp)
    movq    %r15, 32(%rsp)


    movdqa  %xmm0, 64(%rsp)
    movdqa  %xmm1, 80(%rsp)
    movdqa  %xmm2, 96(%rsp)
    movdqa  %xmm3, 112(%rsp)
    movdqa  %xmm4, 128(%rsp)
    movdqa  %xmm5, 144(%rsp)
    movdqa  %xmm6, 160(%rsp)
    movdqa  %xmm7, 176(%rsp)

# Body
    pushq %rdi
    pushq 24(%rdi)      # Push function pointer onto stack

    movq  16(%rdi), %r13 # Load the target 'self'

# Shuffle up arguments
    movq  %rsi, %rdi
    movq  %rdx, %rsi
    movq  %rcx, %rdx
    movq  %r8, %rcx
    movq  %r9, %r8

# CALL
    callq *(%rsp)

    addq $8, %rsp
    popq %rdi

    movq %rax, 32(%rdi) # Save rax to calling object
    movq %rdx, 40(%rdi) # Save rdx to calling object

# Restore registers from stack
    movq    (%rsp), %rbx
    movq    8(%rsp), %r12
    movq    16(%rsp), %r13
    movq    24(%rsp), %r14
    movq    32(%rsp), %r15

    movdqa  64(%rsp), %xmm0
    movdqa  80(%rsp), %xmm1
    movdqa  96(%rsp), %xmm2
    movdqa  112(%rsp), %xmm3
    movdqa  128(%rsp), %xmm4
    movdqa  144(%rsp), %xmm5
    movdqa  160(%rsp), %xmm6
    movdqa  176(%rsp), %xmm7

    leaq    208(%rsp), %rsp

# Cleanup
    movq %rbp, %rsp
    popq %rbp
    ret




