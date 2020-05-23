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
#import "XVimMotionEvaluator.h"
#import "XVimMotionOption.h"
#import "XVimWindow.h"
#import "XVimSearch.h"
#import "XVim2-Swift.h"

#ifdef TODO
#import "XVimCommandLineEvaluator.h"
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
    self.motion = [XVimMotion style:MOTION_END_OF_WORD_BACKWARD type:CHARWISE_INCLUSIVE count:self.numericArg];
    return nil;
}

- (XVimEvaluator*)E
{
    // Select previous WORD end
    self.motion = [XVimMotion style:MOTION_END_OF_WORD_BACKWARD type:CHARWISE_INCLUSIVE option:MOPT_BIGWORD count:self.numericArg];
    return nil;
}

- (XVimEvaluator*)g
{
    self.motion = [XVimMotion style:MOTION_LINENUMBER type:LINEWISE count:1];
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)j
{
    self.motion = [XVimMotion style:MOTION_LINE_FORWARD type:CHARWISE_EXCLUSIVE option:MOPT_DISPLAY_LINE count: self.numericArg];
    return nil;
}

- (XVimEvaluator*)k
{
    self.motion = [XVimMotion style:MOTION_LINE_BACKWARD type:CHARWISE_EXCLUSIVE option:MOPT_DISPLAY_LINE count: self.numericArg];
    return nil;
}

- (XVimEvaluator*)n{
    self.motion = XVim.instance.searcher.motionForRepeatSearch;
    self.motion.style = MOTION_SEARCH_MATCHED_FORWARD;

    return nil;
}

- (XVimEvaluator*)N{
    self.motion = XVim.instance.searcher.motionForRepeatSearch;
    self.motion.style = MOTION_SEARCH_MATCHED_BACKWARD;

    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward
{
    let eval = [self searchEvaluatorForward:forward];
    let r = [self.sourceView xvim_currentWord:MOPT_NONE];
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
