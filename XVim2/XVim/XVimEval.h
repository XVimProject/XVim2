//
//  XVimEval.h
//  XVim
//
//  Created by pebble on 2013/01/28.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class XVimWindow;

// @ref eval.c in original vim
@interface XVimEvalArg : NSObject
@property (nonnull) NSString* invar; // [in] in variable
@property (nullable) NSString* rvar; // [out] return variable
@end

//
@interface XVimEvalFunc : NSObject
@property (nonnull) NSString* funcName;
@property (nonnull) NSString* methodName;
@end

//
@interface XVimEval : NSObject {
    NSArray<XVimEvalFunc *>* _evalFuncs;
}
- (void)evaluateWhole:(nonnull XVimEvalArg*)args inWindow:(nonnull XVimWindow*)window;
@end

NS_ASSUME_NONNULL_END
