//
//  XVimGActionEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

//#import "XVimJoinEvaluator.h"
#import "XVimGActionEvaluator.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceViewProtocol.h"
#import "XVim.h"
#import "XVimInsertEvaluator.h"
#import "XVimJoinEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimLowercaseEvaluator.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimTildeEvaluator.h"
#import "XVimUppercaseEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimWindow.h"

@implementation XVimGActionEvaluator

// CASE CHANGING

- (XVimEvaluator*)u
{
    [self.argumentString appendString:@"u"];
    return [[XVimLowercaseEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)U
{
    [self.argumentString appendString:@"U"];
    return [[XVimUppercaseEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)d
{
    xvim_ignore_warning_undeclared_selector_push [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    xvim_ignore_warning_pop return nil;
}

- (XVimEvaluator*)f
{
    // Does not work correctly.
    // This seems because the when Xcode change the content of DVTSourceTextView
    // ( for example when the file shown in the view is changed )
    // it makes the content empty first but does not set selectedRange.
    // This cause assertion is NSTextView+VimMotion's ASSERT_VALID_RANGE_WITH_EOF.
    // One option is change the assertion condition, but I still need to
    // know more about this to implement robust one.
    //[NSApp sendAction:@selector(openQuickly:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)i
{
    XVimMark* mark = [[XVim instance].marks markForName:@"^" forDocument:self.sourceView.documentURL.path];
    XVimInsertionPoint mode = XVIM_INSERT_DEFAULT;

    if (mark.line != NSNotFound) {
        NSUInteger newPos = [self.sourceView xvim_indexOfLineNumber:mark.line column:mark.column];
        if (NSNotFound != newPos) {
            XVimMotion* m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 0);
            m.position = newPos;

            [self.window preMotion:m];
            [self.sourceView xvim_move:m];
            mode = XVIM_INSERT_APPEND;
        }
    }
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window mode:mode];
}

- (XVimEvaluator*)J
{
    XVimJoinEvaluator* eval = [[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:NO];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE,
                                                             self.numericArg)];
}


- (XVimEvaluator*)v
{
    // Select previous visual selection
    return [[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window];
}

- (XVimEvaluator*)TILDE
{
    [self.argumentString appendString:@"~"];
    return [[XVimTildeEvaluator alloc] initWithWindow:self.window];
}
@end
