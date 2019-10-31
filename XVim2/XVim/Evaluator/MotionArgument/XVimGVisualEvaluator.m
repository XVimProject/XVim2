//
//  XVimGVisualEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGVisualEvaluator.h"
#import "SourceViewProtocol.h"
#import "XVimJoinEvaluator.h"
#import "XVimWindow.h"

@implementation XVimGVisualEvaluator

- (XVimEvaluator*)defaultNextEvaluator { return XVimEvaluator.popEvaluator; }

- (NSString*)modeString { return self.parent.modeString; }

- (void)didEndHandler
{
    [self.parent.argumentString setString:@""];
    [super didEndHandler];
}

- (XVimEvaluator*)e
{
    let motion = [XVimMotion style:MOTION_END_OF_WORD_BACKWARD type:CHARWISE_EXCLUSIVE count:self.numericArg];
    [self.sourceView xvim_move:motion];
    [self.parent resetNumericArg];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)E
{
    let motion = [XVimMotion style:MOTION_END_OF_WORD_BACKWARD type:CHARWISE_EXCLUSIVE option:MOPT_BIGWORD count: self.numericArg];
    [self.sourceView xvim_move:motion];
    [self.parent resetNumericArg];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)f
{
    [self.window errorMessage:@"{visual}gf unimplemented" ringBell:NO];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)F { return [self f]; }

- (XVimEvaluator*)C_g
{
    [self.window errorMessage:@"{Visual}g CTRL-G unimplemented" ringBell:NO];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)g
{
    let motion = [XVimMotion style:MOTION_LINENUMBER type:CHARWISE_EXCLUSIVE count:1];
    motion.line = self.numericArg;
    [self.sourceView xvim_move:motion];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)j
{
    let motion = [XVimMotion style:MOTION_LINE_FORWARD type:CHARWISE_EXCLUSIVE option:MOPT_DISPLAY_LINE count:self.numericArg];
    [self.sourceView xvim_move:motion];
    [self.parent resetNumericArg];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)k
{
    let motion = [XVimMotion style:MOTION_LINE_BACKWARD type:CHARWISE_EXCLUSIVE option:MOPT_DISPLAY_LINE count: self.numericArg];
    [self.sourceView xvim_move:motion];
    [self.parent resetNumericArg];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)J
{
    let eval = [[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:NO];
    return [eval executeOperationWithMotion:[XVimMotion style:MOTION_NONE type:CHARWISE_EXCLUSIVE count:
                                                             self.numericArg]];
}

- (XVimEvaluator*)q
{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return [XVimEvaluator popEvaluator];
}

- (XVimEvaluator*)u
{
    let view = [self sourceView];
    [view xvim_makeLowerCase:[XVimMotion style:MOTION_NONE type:CHARWISE_EXCLUSIVE count:1]];
    return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)U
{
    let view = [self sourceView];
    [view xvim_makeUpperCase:[XVimMotion style:MOTION_NONE type:CHARWISE_EXCLUSIVE count:1]];
    return [XVimEvaluator invalidEvaluator];
}

- (XVimEvaluator*)w
{
    [self.window errorMessage:@"{visual}gq unimplemented" ringBell:NO];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)QUESTION
{
    [self.window errorMessage:@"{visual}g? unimplemented" ringBell:NO];
    return XVimEvaluator.popEvaluator;
}

- (XVimEvaluator*)TILDE
{
    let view = self.sourceView;
    [view xvim_swapCase:[XVimMotion style:MOTION_NONE type:CHARWISE_EXCLUSIVE count:1]];
    return XVimEvaluator.invalidEvaluator;
}

@end
