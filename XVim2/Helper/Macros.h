//
//  Macros.h
//  XVim2
//
//  Created by Ant on 17/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

//#define let __auto_type
#define let __auto_type const
#define var __auto_type


#define clamp(_in, _min, _max) do { (_in) = ((_in) < (_min) ? (_min) : ((_in) > (_max) ? (_max) : (_in))); } while(false)
#define xvim_swap(v1, v2) do { let tmp = (v2); (v2) = (v1); (v1) = tmp; } while(false)

typedef void (^xvim_cleanup_block_t)(void);
static inline void xvim_execute_cleanup_block(__strong xvim_cleanup_block_t* block) { (*block)(); }
#define xvim_concat_(A, B) A##B
#define xvim_concat(A, B) xvim_concat_(A, B)

#define xvim_on_exit                                                                                                   \
    __strong xvim_cleanup_block_t xvim_concat(xvim_exitBlock_, __LINE__)                                               \
                __attribute__((cleanup(xvim_execute_cleanup_block), unused, objc_precise_lifetime))                    \
                = ^

#define CONST_STR(_name) NSString* _name = @ #_name;

#define _run_before_main(_id, _disambiguator, _priority)                                                               \
    void xvim_concat(runBeforeMain_, xvim_concat(_id, _disambiguator))(void) __attribute__((constructor(_priority)));  \
    void xvim_concat(runBeforeMain_, xvim_concat(_id, _disambiguator))()

#define run_before_main(_id) _run_before_main(_id, xvim_concat(__LINE__, __COUNTER__), 110)


#define xvim_ignore_warning_undeclared_selector_push _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Wundeclared-selector\"")
#define xvim_ignore_warning_pop _Pragma("clang diagnostic pop")

#endif /* Macros_h */
