//
//  SourceCodeEditorViewWrapper.s
//  XVim2
//
//  Created by Ant on 23/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

.text
    .global _wrapper_call
    .global _wrapper_call2
    .global _wrapper_call3
    .global _wrapper_call4
    .global _wrapper_call5
    .global _wrapper_call6
    .global _wrapper_call7
    .global _wrapper_call8
    .global _wrapper_call9

_wrapper_call:
_wrapper_call2:
_wrapper_call3:
_wrapper_call4:
_wrapper_call5:
_wrapper_call6:
_wrapper_call7:
_wrapper_call8:
_wrapper_call9:

# Prolog
    pushq %rbp
    movq  %rsp, %rbp

# Save registers on stack
    leaq    -208(%rsp), %rsp
    andq    $0FFFFFFFFFFFFFFF0H, %rsp
    movq    %rdi, (%rsp)
    movq    %rsi, 8(%rsp)
    movq    %rdx, 16(%rsp)
    movq    %rcx, 24(%rsp)
    movq    %r8, 32(%rsp)
    movq    %r9, 40(%rsp)
    movq    %r12, 48(%rsp)
    movq    %r14, 56(%rsp)

    movdqa  %xmm0, 64(%rsp)
    movdqa  %xmm1, 80(%rsp)
    movdqa  %xmm2, 96(%rsp)
    movdqa  %xmm3, 112(%rsp)
    movdqa  %xmm4, 128(%rsp)
    movdqa  %xmm5, 144(%rsp)
    movdqa  %xmm6, 160(%rsp)
    movdqa  %xmm7, 176(%rsp)

# Body
    pushq %r13
    pushq 16(%r13)      # Push function pointer onto stack
    movq  8(%r13), %r13 # Load the target 'self'
    callq *(%rsp)
    addq $8, %rsp
    popq %r13           # Restore original 'self'

    movq %rax, 32(%r13) # Save rax to calling object

# Restore registers from stack
    movq    (%rsp), %rdi
    movq    8(%rsp), %rsi
    movq    16(%rsp), %rdx
    movq    24(%rsp), %rcx
    movq    32(%rsp), %r8
    movq    40(%rsp), %r9
    movq    48(%rsp), %r12
    movq    56(%rsp), %r14

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




