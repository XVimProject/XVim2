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

    pushq %r13
    movq %r12, 24(%r13) # Save r12
    movq 16(%r13), %r12 # Load the function
    movq  8(%r13), %r13 # Load the target 'self'
    callq *%r12
    popq %r13
    movq 24(%r13), %r12 # Restore r12
    movq %rax, 32(%r13) # Save rax to calling object
    ret



