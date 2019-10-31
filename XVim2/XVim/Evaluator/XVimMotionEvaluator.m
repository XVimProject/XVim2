
//
//  XVimMotionEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceViewProtocol.h"
#import "XVim.h"
#import "XVimArgumentEvaluator.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimSearch.h"
#import "XVimWindow.h"
#import "XVimZEvaluator.h"
#import "XcodeUtils.h"
#import "XVimGMotionEvaluator.h"

@interface XVimMotionEvaluator () {
    MOTION_TYPE _forcedMotionType;
    BOOL _toggleInclusiveExclusive;
}
@end

@implementation XVimMotionEvaluator
@synthesize motion = _motion;

- (id)initWithWindow:(XVimWindow*)window
{
    self = [super initWithWindow:window];
    if (self) {
        _forcedMotionType = DEFAULT_MOTION_TYPE;
        _motion = [XVimMotion style:MOTION_NONE type:CHARWISE_INCLUSIVE count:1];
    }
    return self;
}

- (XVimEvaluator*)_motionFixed:(XVimMotion*)motion
{
    if (_forcedMotionType == CHARWISE_EXCLUSIVE) { // CHARWISE_EXCLUSIVE means 'v' is pressed and it means
                                                        // toggle inclusive/exclusive. So its not always "exclusive"
        if (motion.type == LINEWISE) {
            motion.type = CHARWISE_EXCLUSIVE;
        }
        else {
            if (motion.type == CHARWISE_EXCLUSIVE) {
                motion.type = CHARWISE_INCLUSIVE;
            }
            else if (motion.type == CHARWISE_INCLUSIVE) {
                motion.type = CHARWISE_EXCLUSIVE;
            }
        }
    }
    else if (_forcedMotionType == LINEWISE) {
        motion.type = LINEWISE;
    }
    else if (_forcedMotionType == BLOCKWISE) {
        // TODO: Implement BLOCKWISE operation
        // Currently BLOCKWISE is not supporeted by operations implemented in NSTextView.m
        motion.type = LINEWISE;
    }
    else {
        // _forceMotionType == DEFAULT_MOTION_TYPE
    }
    return [self motionFixedCore:motion];
}

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion { return nil; }

////////////KeyDown Handlers///////////////
// Please keep it in alphabetical order ///
///////////////////////////////////////////

- (XVimEvaluator*)b
{
    return [self _motionFixed:[XVimMotion style:MOTION_WORD_BACKWARD type:CHARWISE_EXCLUSIVE count:[self numericArg]]];
}

- (XVimEvaluator*)B
{
    return [self _motionFixed:[XVimMotion style:MOTION_WORD_BACKWARD type:CHARWISE_EXCLUSIVE option:MOPT_BIGWORD
                                           count:self.numericArg]];
}

/*
 // Since Ctrl-b, Ctrl-d is not "motion" but "scroll"
 // Do not implement it here. they are implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.
 */

- (XVimEvaluator*)e
{
    let motion = [XVimMotion style:MOTION_END_OF_WORD_FORWARD type:CHARWISE_INCLUSIVE count:
                                          self.numericArg];
    return [self _motionFixed:motion];
}

- (XVimEvaluator*)E
{
    let motion
    = [XVimMotion style:MOTION_END_OF_WORD_FORWARD type:CHARWISE_INCLUSIVE option:MOPT_BIGWORD count:self .numericArg];
    return [self _motionFixed:motion];
}

- (XVimEvaluator*)onComplete_fFtT:(XVimArgumentEvaluator*)childEvaluator
{
    // FIXME:
    // Do not use toString here.
    // keyStroke must generate a internal code
    /*
if( childEvaluator.keyStroke.toString.length != 1 ){
    return [XVimEvaluator invalidEvaluator];
}
 */

    self.motion.count = self.numericArg;
    self.motion.character = childEvaluator.keyStroke.character;
    XVim.instance.lastCharacterSearchMotion = self.motion;
    return [self _motionFixed:self.motion];
}

- (XVimEvaluator*)f
{
    [self.argumentString appendString:@"f"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.style = MOTION_NEXT_CHARACTER;
    self.motion.type = CHARWISE_INCLUSIVE;
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)F
{
    [self.argumentString appendString:@"F"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.style = MOTION_PREV_CHARACTER;
    self.motion.type = CHARWISE_EXCLUSIVE;
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)g
{
    [self.argumentString appendString:@"g"];
     self.onChildCompleteHandler = @selector(onComplete_g:);
     return [[XVimGMotionEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)onComplete_g:(XVimGMotionEvaluator*)childEvaluator{
    if( childEvaluator.key.selector == @selector(SEMICOLON) ){
        let mark = [XVim.instance.marks markForName:@"." forDocument:self.sourceView.documentURL.path];
        return [self jumpToMark:mark firstOfLine:NO KeepJumpMarkIndex:NO NeedUpdateMark:YES];
    }else{
        return [self _motionFixed:childEvaluator.motion];
    }
}

- (XVimEvaluator*)G
{
    var m = [XVimMotion style:MOTION_LINENUMBER type:LINEWISE option:MOPT_LEFT_RIGHT_NOWRAP count:self.numericArg];
    if (self.numericMode) {
        m.line = self.numericArg;
    }
    else {
        m.style = MOTION_LASTLINE;
    }
    return [self _motionFixed:m];
}

- (XVimEvaluator*)h
{
    return [self _motionFixed:[XVimMotion style:MOTION_BACKWARD type:CHARWISE_EXCLUSIVE option:MOPT_LEFT_RIGHT_NOWRAP count:self.numericArg]];
}

- (XVimEvaluator*)H
{
    return [self _motionFixed:[XVimMotion style:MOTION_HOME type:LINEWISE count:self.numericArg]];
}

- (XVimEvaluator*)j
{
    return [self _motionFixed:[XVimMotion style:MOTION_LINE_FORWARD type:LINEWISE count:self.numericArg]];
}
- (XVimEvaluator*)J
{
    return [self _motionFixed:[XVimMotion style:MOTION_LINE_FORWARD type:LINEWISE option:MOPT_EXTEND_SELECTION count:self.numericArg]];
}

- (XVimEvaluator*)k
{
    return [self _motionFixed:[XVimMotion style:MOTION_LINE_BACKWARD type:LINEWISE count:self.numericArg]];
}
- (XVimEvaluator*)K
{
    return [self _motionFixed:[XVimMotion style:MOTION_LINE_BACKWARD type:LINEWISE option:MOPT_EXTEND_SELECTION count:self.numericArg]];
}

- (XVimEvaluator*)l
{
    return [self _motionFixed:[XVimMotion style:MOTION_FORWARD type:CHARWISE_EXCLUSIVE option:MOPT_LEFT_RIGHT_NOWRAP
                                           count:self.numericArg]];
}

- (XVimEvaluator*)L
{
    return [self _motionFixed:[XVimMotion style:MOTION_BOTTOM type:LINEWISE count:self.numericArg]];
}

- (XVimEvaluator*)M
{
    return [self _motionFixed:[XVimMotion style:MOTION_MIDDLE type:LINEWISE count:self.numericArg]];
}

- (XVimEvaluator*)nN_impl:(BOOL)opposite
{
    XVim.instance.foundRangesHidden = NO;
    let view = self.window.sourceView;
    view.needsUpdateFoundRanges = YES;

    XVimMotion* m = [XVim.instance.searcher motionForRepeatSearch];
    if (opposite) {
        m.style = (m.style == MOTION_SEARCH_FORWARD) ? MOTION_SEARCH_BACKWARD : MOTION_SEARCH_FORWARD;
    }
    self.motion = m;
    return [self _motionFixed:m];
}

- (XVimEvaluator*)n { return [self nN_impl:NO]; }

- (XVimEvaluator*)N { return [self nN_impl:YES]; }

/*
 // Since Ctrl-u is not "motion" but "scroll"
 // it is implemented in XVimNormalEvaluator and XVimVisualEvaluator respectively.

 - (XVimEvaluator*)C_u{
 // This should not be implemneted here
 }
 */

- (XVimEvaluator*)t
{
    [self.argumentString appendString:@"t"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.style = MOTION_TILL_NEXT_CHARACTER;
    self.motion.type = CHARWISE_INCLUSIVE;
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)T
{
    [self.argumentString appendString:@"T"];
    self.onChildCompleteHandler = @selector(onComplete_fFtT:);
    self.motion.style = MOTION_TILL_PREV_CHARACTER;
    self.motion.type = CHARWISE_EXCLUSIVE;
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)v
{
    _forcedMotionType = CHARWISE_EXCLUSIVE; // This does not mean the motion will always be "exclusive". This is
                                                 // just for remembering that its type is "characterwise" forced.
    // Actual motion is decided by motions' default inclusive/exclusive attribute and _toggleInclusiveExclusive flag.
    _toggleInclusiveExclusive = !_toggleInclusiveExclusive;
    return self;
}

- (XVimEvaluator*)V
{
    _toggleInclusiveExclusive = NO;
    _forcedMotionType = LINEWISE;
    return self;
}

- (XVimEvaluator*)C_v
{
    _toggleInclusiveExclusive = NO;
    _forcedMotionType = BLOCKWISE;
    return self;
}

- (XVimEvaluator*)w
{
    return [self _motionFixed:[XVimMotion style:MOTION_WORD_FORWARD type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

- (XVimEvaluator*)W
{
    return [self _motionFixed:[XVimMotion style:MOTION_WORD_FORWARD type:CHARWISE_EXCLUSIVE option:MOPT_BIGWORD
                                           count:self.numericArg]];
}

- (XVimEvaluator*)NUM0
{
    return [self _motionFixed:[XVimMotion style:MOTION_BEGINNING_OF_LINE type:CHARWISE_INCLUSIVE count:
                                               self.numericArg]];
}

// SEARCH
#pragma mark - SEARCH

- (XVimEvaluator*)ASTERISK { return [self searchCurrentWordForward:YES]; }

- (XVimEvaluator*)NUMBER { return [self searchCurrentWordForward:NO]; }

// MARKS
#pragma mark - MARKS

// This is internal method used by SQUOTE, BACKQUOTE
// TODO: rename firstOfLine -> firstNonblankOfLine
- (XVimEvaluator*)jumpToMark:(XVimMark*)mark
                  firstOfLine:(BOOL)fol
            KeepJumpMarkIndex:(BOOL)keepJumpMarkIndex
               NeedUpdateMark:(BOOL)needUpdateMark
{
    if (mark == nil)
        return XVimEvaluator.invalidEvaluator;

    let motionType = fol ? LINEWISE : CHARWISE_EXCLUSIVE;

    if (mark.line == NSNotFound) {
        return XVimEvaluator.invalidEvaluator;
    }

    var jumpToAnotherFile = NO;
    if (mark.document && ![mark.document isEqualToString:self.sourceView.documentURL.path]) {
        jumpToAnotherFile = YES;
        XVimOpenDocumentAtPath(mark.document);
    }

    var to = [self.sourceView xvim_indexOfLineNumber:mark.line column:mark.column];
    if (NSNotFound == to) {
        return XVimEvaluator.invalidEvaluator;
    }

    if (fol) {
        to = [self.sourceView.textStorage xvim_firstNonblankInLineAtIndex:to
                                                                 allowEOL:YES]; // This never returns NSNotFound
    }

    let m = [XVimMotion style:needUpdateMark ? MOTION_POSITION_JUMP : MOTION_POSITION type:motionType
                         count:self.numericArg];
    m.position = to;
    if (needUpdateMark) {
        m.jumpToAnotherFile = jumpToAnotherFile;
    }
    m.keepJumpMarkIndex = keepJumpMarkIndex;

    return [self _motionFixed:m];
}

// SQUOTE ( "'{mark-name-letter}" ) moves the cursor to the mark named {mark-name-letter}
// e.g. 'a moves the cursor to the mark names "a"
// It does nothing if the mark is not defined or if the mark is no longer within
//  the range of the document

- (XVimEvaluator*)SQUOTE
{
    [self.argumentString appendString:@"'"];
    self.onChildCompleteHandler = @selector(onComplete_SQUOTE:);
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)onComplete_SQUOTE:(XVimArgumentEvaluator*)childEvaluator
{
    // FIXME:
    // This will work for Ctrl-c as register c but it should not
    // NSString* key = [childEvaluator.keyStroke toString];
    let key = [NSString stringWithFormat:@"%c", childEvaluator.keyStroke.character];
    let mark = [XVim.instance.marks markForName:key forDocument:self.sourceView.documentURL.path];
    return [self jumpToMark:mark firstOfLine:YES KeepJumpMarkIndex:NO NeedUpdateMark:YES];
}

- (XVimEvaluator*)z
{
    [self.argumentString appendString:@"z"];
    return [[XVimZEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)BACKQUOTE
{
    [self.argumentString appendString:@"`"];
    self.onChildCompleteHandler = @selector(onComplete_BACKQUOTE:);
    return [[XVimArgumentEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)onComplete_BACKQUOTE:(XVimArgumentEvaluator*)childEvaluator
{
    // FIXME:
    // This will work for Ctrl-c as register c but it should not
    // NSString* key = [childEvaluator.keyStroke toString];
    let key = [NSString stringWithFormat:@"%c", childEvaluator.keyStroke.character];
    let mark = [XVim.instance.marks markForName:key forDocument:self.sourceView.documentURL.path];
    return [self jumpToMark:mark firstOfLine:NO KeepJumpMarkIndex:NO NeedUpdateMark:YES];
}

// CARET ( "^") moves the cursor to the start of the currentline (past leading whitespace)
// Note: CARET always moves to start of the current line ignoring any numericArg.
- (XVimEvaluator*)CARET
{
    return [self _motionFixed:[XVimMotion style:MOTION_FIRST_NONBLANK type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

- (XVimEvaluator*)DOLLAR
{
    return [self _motionFixed:[XVimMotion style:MOTION_END_OF_LINE type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

// Underscore ( "_") moves the cursor to the start of the line (past leading whitespace)
// Note: underscore without any numeric arguments behaves like caret but with a numeric argument greater than 1
// it will moves to start of the numeric argument - 1 lines down.
- (XVimEvaluator*)UNDERSCORE
{
    // TODO add this motion interface to NSTextView
    let view = self.window.sourceView;
    let r = [view selectedRange];
    let repeat = self.numericArg;
    let linesUpCursorloc =
                [view.textStorage nextLine:r.location column:0 count:(repeat - 1) option:MOPT_NONE];
    var head = [view.textStorage xvim_firstNonblankInLineAtIndex:linesUpCursorloc allowEOL:NO];
    if (NSNotFound == head && linesUpCursorloc != NSNotFound) {
        head = linesUpCursorloc;
    }
    else if (NSNotFound == head) {
        head = r.location;
    }
    let m = [XVimMotion style:MOTION_POSITION type:CHARWISE_EXCLUSIVE count:0];
    m.position = head;
    return [self _motionFixed:m];
}

- (XVimEvaluator*)PERCENT
{
    if (self.numericMode) {
        return [self _motionFixed:[XVimMotion style:MOTION_PERCENT type:LINEWISE count:self.numericArg]];
    }
    else {
        return [self _motionFixed:[XVimMotion style:MOTION_NEXT_MATCHED_ITEM type:CHARWISE_INCLUSIVE
                                                count:self.numericArg]];
    }
}
/*
 * Space acts like 'l' in vi. moves  cursor forward
 */
- (XVimEvaluator*)SPACE { return [self l]; }

/*
 * BackSpace (BS) acts like 'h' in vi. moves cursor backward
 */
- (XVimEvaluator*)BS { return [self h]; }

- (XVimEvaluator*)PLUS
{
    return [self _motionFixed:[XVimMotion style:MOTION_NEXT_FIRST_NONBLANK type:LINEWISE count:
                                               self.numericArg]];
}
/*
 * CR (return) acts like PLUS in vi
 */
- (XVimEvaluator*)CR { return [self PLUS]; }

- (XVimEvaluator*)MINUS
{
    return [self _motionFixed:[XVimMotion style:MOTION_PREV_FIRST_NONBLANK type:LINEWISE count:
                                               self.numericArg]];
}


- (XVimEvaluator*)LSQUAREBRACKET
{
    // TODO: implement XVimLSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET
{
    // TODO: implement XVimRSquareBracketEvaluator
    return nil;
}

- (XVimEvaluator*)LBRACE
{ // {
    return [self _motionFixed:[XVimMotion style:MOTION_PARAGRAPH_BACKWARD type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

- (XVimEvaluator*)RBRACE
{ // }
    return [self _motionFixed:[XVimMotion style:MOTION_PARAGRAPH_FORWARD type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}


- (XVimEvaluator*)LPARENTHESIS
{ // (
    return [self _motionFixed:[XVimMotion style:MOTION_SENTENCE_BACKWARD type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

- (XVimEvaluator*)RPARENTHESIS
{ // )
    return [self _motionFixed:[XVimMotion style:MOTION_SENTENCE_FORWARD type:CHARWISE_EXCLUSIVE count:
                                               self.numericArg]];
}

- (XVimEvaluator*)COMMA
{
    let m = XVim.instance.lastCharacterSearchMotion;
    if (m == nil) {
        return XVimEvaluator.invalidEvaluator;
    }
    MOTION_STYLE new_motion = MOTION_PREV_CHARACTER;
    var new_option = m.option;
    switch (m.style) {
    case MOTION_NEXT_CHARACTER:
        new_motion = MOTION_PREV_CHARACTER;
        break;
    case MOTION_PREV_CHARACTER:
        new_motion = MOTION_NEXT_CHARACTER;
        break;
    case MOTION_TILL_NEXT_CHARACTER:
        new_motion = MOTION_TILL_PREV_CHARACTER;
        new_option |= MOPT_SKIP_ADJACENT_CHAR;
        break;
    case MOTION_TILL_PREV_CHARACTER:
        new_motion = MOTION_TILL_NEXT_CHARACTER;
        new_option |= MOPT_SKIP_ADJACENT_CHAR;
        break;
    default:
        NSAssert(NO, @"Should not reach here");
        break;
    }
    let n = [XVimMotion style:new_motion type:m.type option:new_option count:self.numericArg];
    n.character = m.character;
    return [self _motionFixed:n];
}

- (XVimEvaluator*)SEMICOLON
{
    let m = XVim.instance.lastCharacterSearchMotion;
    if (nil == m) {
        return XVimEvaluator.invalidEvaluator;
    }

    let n = [XVimMotion style:m.style type:m.type option:m.option | MOPT_SKIP_ADJACENT_CHAR count:self.numericArg];
    n.character = m.character;
    return [self _motionFixed:n];
}

// TODO: Temporary replacement for slash and asterisk

#ifdef TODO
- (XVimEvaluator*)QUESTION
{
    [NSApp sendAction:NSSelectorFromString(@"find:") to:nil from:self];
    return nil;
}

- (XVimEvaluator*)SLASH
{
    [NSApp sendAction:NSSelectorFromString(@"find:") to:nil from:self];
    return nil;
}
#endif


// QESTION and SLASH are "motion" since it can be used as an arugment for operators.
// "d/abc<CR>" will delete until "abc" characters.
- (XVimEvaluator*)QUESTION
{
    self.onChildCompleteHandler = @selector(onCompleteSearch:);
    return [self searchEvaluatorForward:NO];
}

- (XVimEvaluator*)SLASH
{
    self.onChildCompleteHandler = @selector(onCompleteSearch:);
    return [self searchEvaluatorForward:YES];
}

- (XVimEvaluator*)onCompleteSearch:(XVimCommandLineEvaluator*)childEvaluator
{
    self.onChildCompleteHandler = nil;
    if (childEvaluator.evalutionResult != nil) {
        return [self _motionFixed:childEvaluator.evalutionResult];
    }
    return [XVimEvaluator invalidEvaluator];
}


- (XVimEvaluator*)Up { return [self k]; }

- (XVimEvaluator*)Down { return [self j]; }

- (XVimEvaluator*)Left { return [self h]; }

- (XVimEvaluator*)Right { return [self l]; }
- (XVimEvaluator*)Home { return [self NUM0]; }

- (XVimEvaluator*)End { return [self DOLLAR]; }

- (XVimEvaluator*)searchCurrentWordForward:(BOOL)forward
{
    let eval = [self searchEvaluatorForward:forward];
    let r = [self.sourceView xvim_currentWord:MOPT_NONE];
    if (r.location == NSNotFound) {
        return nil;
    }

    let word = [self.sourceView.string substringWithRange:r];
    var searchWord = [NSRegularExpression escapedPatternForString:word];
    searchWord = [NSString stringWithFormat:@"%@%@%@", @"\\b", searchWord, @"\\b"];
    [eval appendString:searchWord];
    [eval execute];
    let motion = eval.evalutionResult;
    if (!forward) {
        // NB when searching backward (`QUESTION`) while in the middle of the
        // searched word, the first match is the word at the cursor. Therefore,
        // search backwards an extra time if not at the beginning of a word.
        NSUInteger index = self.sourceView.insertionPoint;
        if (isKeyword([self.sourceView xvim_characterAtIndex:(index - 1)])) {
            ++motion.count;
        }
    }
    [self _motionFixed:motion];
    return nil;
}

@end
