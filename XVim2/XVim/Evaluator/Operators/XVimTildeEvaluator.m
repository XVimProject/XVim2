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
    return [self _motionFixed:[XVimMotion motion:MOTION_NONE type:CHARWISE_EXCLUSIVE count:count]];
}

- (XVimEvaluator*)TILDE
{
    if (self.numericArg < 1)
        return nil;

    let m = [XVimMotion motion:MOTION_LINE_FORWARD type:LINEWISE count:self.numericArg - 1];
    return [self _motionFixed:m];
}

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [self.sourceView xvim_swapCase:motion];
    return nil;
}

@end
