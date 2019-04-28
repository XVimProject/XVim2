//
//  XVimLowercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimLowercaseEvaluator.h"
#import "XVim.h"
#import "XVimWindow.h"

@implementation XVimLowercaseEvaluator

- (XVimEvaluator*)u
{
    if ([self numericArg] < 1)
        return nil;

    let m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOPT_NONE, [self numericArg] - 1);
    return [self _motionFixed:m];
}

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [[self sourceView] xvim_makeLowerCase:motion];
    return nil;
}


@end
