//
//  XVimEqualEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/5/2012
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEqualEvaluator.h"

@implementation XVimEqualEvaluator

- (XVimEvaluator*)EQUAL
{
    if (self.numericArg < 1)
        return nil;
    let m = [XVimMotion motion:MOTION_LINE_FORWARD type:LINEWISE count:self.numericArg - 1];
    return [self _motionFixed:m];
}

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [self.sourceView xvim_filter:motion];
    return nil;
}

@end
