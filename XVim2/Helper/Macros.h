//
//  Macros.h
//  XVim2
//
//  Created by Ant on 17/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

#define _auto __auto_type

#define clamp(_in, _min, _max) _in = ((_in) < (_min) ? (_min) : ((_in) > (_max) ? (_max) : (_in) ))

typedef void (^xvim_cleanup_block_t)(void);
static inline void xvim_execute_cleanup_block (__strong xvim_cleanup_block_t *block) {
        (*block)();
}
#define xvim_concat_(A, B) A ## B
#define xvim_concat(A, B) xvim_concat_(A, B)

#define xvim_on_exit \
__strong xvim_cleanup_block_t xvim_concat(xvim_exitBlock_, __LINE__) __attribute__((cleanup(xvim_execute_cleanup_block), unused, objc_precise_lifetime)) = ^


#endif /* Macros_h */
