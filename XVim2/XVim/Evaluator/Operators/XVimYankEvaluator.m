//
//  XVimYankEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimYankEvaluator.h"
#import "Logger.h"
#import "SourceEditorViewProtocol.h"
#import "XVim.h"
#import "XVimWindow.h"
#import "XVim2-Swift.h"

@implementation XVimYankEvaluator

- (XVimEvaluator*)y
{
    // 'yy' should obey the repeat specifier
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    if (self.numericArg < 1)
        return nil;

    let m = [[XVimMotion alloc] initWithStyle:MOTION_LINE_FORWARD type:LINEWISE count:self.numericArg - 1];
    return [self _motionFixed:m];
}

- (XVimEvaluator*)UNDERSCORE { return [self y]; }

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [self.sourceView xvim_yank:motion];
    return nil;
}
@end
