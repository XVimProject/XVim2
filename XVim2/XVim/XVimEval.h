//
//  XVimEval.h
//  XVim
//
//  Created by pebble on 2013/01/28.
//
//

#import <Foundation/Foundation.h>
#import "XVim2-Swift.h"

NS_ASSUME_NONNULL_BEGIN

@class XVimWindow;
@class XVimEvalArg;

//
@interface XVimEval : NSObject {
    NSArray<XVimEvalFunc *>* _evalFuncs;
}
- (void)evaluateWhole:(nonnull XVimEvalArg*)args inWindow:(nonnull XVimWindow*)window;
@end

NS_ASSUME_NONNULL_END
