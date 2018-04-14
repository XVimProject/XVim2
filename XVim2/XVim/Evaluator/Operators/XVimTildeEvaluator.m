//
//  XVimTildeEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTildeEvaluator.h"
#import "SourceViewProtocol.h"
#import "XVim.h"
#import "XVimWindow.h"

@implementation XVimTildeEvaluator

- (XVimEvaluator*)fixWithNoMotion:(NSUInteger)count
{
    return [self _motionFixed:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, count)];
}

- (XVimEvaluator*)TILDE
{
    if ([self numericArg] < 1)
        return nil;

    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOPT_NONE, [self numericArg] - 1);
    return [self _motionFixed:m];
}

- (XVimEvaluator*)motionFixed:(XVimMotion*)motion
{
    [[self sourceView] xvim_swapCase:motion];
    return nil;
}

@end
