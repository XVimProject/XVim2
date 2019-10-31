//
//  XVimUppercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimUppercaseEvaluator.h"
#import "SourceViewProtocol.h"
#import "XVim.h"
#import "XVimWindow.h"

@implementation XVimUppercaseEvaluator

- (XVimEvaluator*)U
{
    if (self.numericArg < 1)
        return nil;

    let m = [XVimMotion style:MOTION_LINE_FORWARD type:LINEWISE count:self.numericArg - 1];
    return [self _motionFixed:m];
}

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [self.sourceView xvim_makeUpperCase:motion];
    return nil;
}

@end
