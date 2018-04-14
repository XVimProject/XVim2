//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimGMotionEvaluator.h"
#import "Logger.h"
#import "XVim.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMotion.h"
#import "XVimMotionEvaluator.h"
#import "XVimMotionOption.h"
#import "XVimWindow.h"

#ifdef TODO
#import "XVimCommandLineEvaluator.h"
#import "XVimSearch.h"
#endif

@implementation XVimGMotionEvaluator

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke
{
    self.key = keyStroke;
    return [super eval:keyStroke];
}

- (XVimEvaluator*)e
{
    // Select previous word end
    self.motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_INCLUSIVE, MOPT_NONE,
                                   [self numericArg]);
    return nil;
}

- (XVimEvaluator*)E
{
    // Select previous WORD end
    self.motion = XVIM_MAKE_MOTION(MOTION_END_OF_WORD_BACKWARD, CHARACTERWISE_INCLUSIVE, MOPT_BIGWORD, [self numericArg]);
    return nil;
}

- (XVimEvaluator*)g
{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, MOPT_NONE, 1);
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)j
{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, CHARACTERWISE_EXCLUSIVE, MOPT_DISPLAY_LINE, self.numericArg);
    return nil;
}

- (XVimEvaluator*)k
{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOPT_DISPLAY_LINE, self.numericArg);
    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward
{
    XVimCommandLineEvaluator* eval = [self searchEvaluatorForward:forward];
    NSRange r = [self.sourceView xvim_currentWord:MOPT_NONE];
    if (r.location == NSNotFound) {
        return nil;
    }

    NSString* word = [self.sourceView.string substringWithRange:r];
    NSString* searchWord = [NSRegularExpression escapedPatternForString:word];
    [eval appendString:searchWord];
    [eval execute];
    self.motion = eval.evalutionResult;
    return nil;
}

- (XVimEvaluator*)ASTERISK { return [self searchCurrentWord:YES]; }

- (XVimEvaluator*)NUMBER { return [self searchCurrentWord:NO]; }

- (XVimEvaluator*)SEMICOLON
{
    // SEMICOLON is handled by parent evaluator (not really good design though)
    self.motion = nil;
    return nil;
}

@end
