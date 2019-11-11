//
//  SourceCodeEditorViewProxy+XVim.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <IDEKit/IDEEditor.h>
#import <IDEKit/IDEEditorDocument.h>
#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceEditorViewProxy.h"
#import "SourceEditorViewProxy+Scrolling.h"
#import "SourceEditorViewProxy+XVim.h"
#import "SourceEditorViewProxy+Yank.h"
#import "XVim.h"
#import "XVim2-Swift.h"
#import "XVimMotion.h"
#import "XVimOptions.h"
#import "XVimXcode.h"
#import <IDESourceEditor/_TtC15IDESourceEditor19IDESourceEditorView.h>

@interface SourceEditorViewProxy ()
@property (weak) _TtC15IDESourceEditor19IDESourceEditorView* sourceEditorView;
@end


@implementation SourceEditorViewProxy (XVim)

- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line column:(NSUInteger)col
{
    if (line > self.lineCount) return NSNotFound;
    
    if (line == self.lineCount) {
        return self.string.length - 1;
    }
    let row = line - 1;
    let cols = [self characterRangeForLineRange:NSMakeRange(row, 1)];
    
    // If col is beyond end of content, return position of end of line
    if (col > cols.length) {
        col = cols.length;
    }
    
    let idx = [self indexFromPosition:XvimMakeSourceEditorPosition(row, col)];
    return idx;
}
- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line
{
    return [self xvim_indexOfLineNumber:line column:0];
}

-(NSRange)xvim_indexRangeForLines:(NSRange)lineRange includeEOL:(BOOL)includeEOL
{
    NSUInteger firstRow = lineRange.location - 1;
    NSUInteger numRows = lineRange.length;
    
    var charRange = [self.sourceEditorView characterRangeForLineRange:NSMakeRange(firstRow, numRows)];
    if (includeEOL) {
        charRange.length += [self.sourceEditorDataSourceWrapper lineTerminatorLengthForLine:(firstRow + numRows - 1)];
    }
    return charRange;
}

- (NSRange)xvim_indexRangeForLines:(NSRange)lineRange
{
    return [self xvim_indexRangeForLines:lineRange includeEOL:YES];
}

- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)idx
{
    let l = [self lineRangeForCharacterRange:NSMakeRange(idx, 0)].location;
    return l != NSNotFound ? l + 1 : 1;
}

- (NSUInteger)xvim_endOfLine:(NSUInteger)startIdx
{
    if (startIdx == self.string.length)
        return startIdx;
    
    let firstLine = [self xvim_lineNumberAtIndex:startIdx];
    NSUInteger row = firstLine - 1;
    let charRange = [self characterRangeForLineRange:NSMakeRange(row, 1)];
    var idx = charRange.location + charRange.length - 1;
    idx += [self.sourceEditorDataSourceWrapper lineTerminatorLengthForLine:row];
    return idx;
}

- (void)xvim_beginUndoGrouping
{
    if (self.undoGroupingDepth == 0) {
        [self.undoManager beginUndoGrouping];
        [self xvim_registerInsertionPointForUndo];
    }
    self.undoGroupingDepth++;
}

- (void)xvim_endUndoGrouping
{
    if (self.undoGroupingDepth == 0) {
        ERROR_LOG(@"Attempt to end a non-existent edit transaction");
        return;
    }

    --self.undoGroupingDepth;
    if (self.undoGroupingDepth == 0) {
        [self.undoManager endUndoGrouping];
    }
}

- (void)xvim_beginEditTransaction
{
    if (self.editTransactionDepth == 0) {
        [self beginEditTransaction];
        [self xvim_registerInsertionPointForUndo];
    }
    self.editTransactionDepth++;
}

- (void)xvim_endEditTransaction
{
    if (self.editTransactionDepth == 0) {
        ERROR_LOG(@"Attempt to end a non-existent edit transaction");
        return;
    }

    --self.editTransactionDepth;
    if (self.editTransactionDepth == 0) {
        [self endEditTransaction];
    }
}

- (void)xvim_move:(XVimMotion*)motion
{
    var r = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
    if (r.end == NSNotFound) {
        return;
    }

    if (self.selectionMode != XVIM_VISUAL_NONE && [motion isTextObject]) {
        if (self.selectionMode == XVIM_VISUAL_LINE) {
            // Motion with text object in VISUAL LINE changes visual mode to VISUAL CHARACTER
            [self setSelectionMode:XVIM_VISUAL_CHARACTER];
        }

        if (self.insertionPoint < self.selectionBegin) {
            // When insertionPoint < selectionBegin it only changes insertion point to beginning of the text object
            [self xvim_moveCursor:r.begin preserveColumn:NO];
        }
        else {
            // Text object expands one text object ( the text object under insertion point + 1 )
            if (![self.textStorage isEOF:self.insertionPoint + 1]) {
                if (motion.style != TEXTOBJECT_UNDERSCORE) {
                    r = [self xvim_getMotionRange:self.insertionPoint + 1 Motion:motion];
                }
            }
            if (self.selectionBegin > r.begin) {
                self.selectionBegin = r.begin;
            }
            [self xvim_moveCursor:r.end preserveColumn:NO];
        }
    }
    else { // VISUAL MODE
        switch (motion.style) {
        case MOTION_LINE_BACKWARD:
        case MOTION_LINE_FORWARD:
        case MOTION_LASTLINE:
        case MOTION_LINENUMBER:
            // TODO: Preserve column option can be included in motion object
            if (self.selectionMode == XVIM_VISUAL_BLOCK && self.selectionToEOL) {
                r.end = [self xvim_endOfLine:r.end];
            }
            else if (XVim.instance.options.startofline) {
                // only jump to nonblank line for last line or line number
                if (motion.style == MOTION_LASTLINE || motion.style == MOTION_LINENUMBER) {
                    r.end = [self.textStorage xvim_firstNonblankInLineAtIndex:r.end allowEOL:YES];
                }
            }
            [self xvim_moveCursor:r.end preserveColumn:YES];
            break;
        case MOTION_END_OF_LINE:
            self.selectionToEOL = NO;
            [self xvim_moveCursor:r.end preserveColumn:NO];
            break;
        case MOTION_END_OF_WORD_BACKWARD:
            self.selectionToEOL = NO;
            [self xvim_moveCursor:r.begin preserveColumn:NO];
            break;

        default:
            self.selectionToEOL = NO;
            [self xvim_moveCursor:r.end preserveColumn:NO];
            break;
        }
    }
    //[self setNeedsDisplay:YES];
    [self xvim_syncStateWithScroll:YES];
}

- (void)xvim_moveToLocation:(XVimLocation)location
{
    [self xvim_moveCursor:[self xvim_indexOfLineNumber:location.line column:location.column] preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
}

- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve
{
    // This method only update the internal state(like self.insertionPoint)

    if (pos > self.string.length) {
        ERROR_LOG(@"[%p]Position specified exceeds the length of the text", self);
        pos = self.string.length;
    }

    if (self.cursorMode == XVIM_CURSOR_MODE_COMMAND && !(self.selectionMode == XVIM_VISUAL_BLOCK)) {
        let adjustedPos = [self.textStorage convertToValidCursorPositionForNormalMode:pos];
        self.insertionPoint = adjustedPos;
        if (pos != adjustedPos && self.selectedRange.length == 0) {
            self.xvim_lockSyncStateFromView = YES;
            self.selectedRange = NSMakeRange(adjustedPos, 0);
            self.xvim_lockSyncStateFromView = NO;
        }
    }
    else {
        self.insertionPoint = pos;
    }

    if (!preserve) {
        self.preservedColumn = [self.textStorage xvim_columnOfIndex:self.insertionPoint];
    }

    //DEBUG_LOG(@"[%p]New Insertion Point:%d   Preserved Column:%d", self, self.insertionPoint, self.preservedColumn);
}

/**
 * Adjust cursor position if the position is not valid as normal mode cursor position
 * This method may changes selected range of the view.
 **/
- (void)xvim_adjustCursorPosition
{
    // If the current cursor position is not valid for normal mode move it.
    if (nil == self.textStorage) {
        return;
    }
    if (![self.textStorage isValidCursorPosition:self.selectedRange.location]) {
        NSRange currentRange = self.selectedRange;
        // TODO: [self selectPreviousPlaceholder];
        NSRange prevPlaceHolder = self.selectedRange;
        if (currentRange.location != prevPlaceHolder.location
            && currentRange.location == (prevPlaceHolder.location + prevPlaceHolder.length)) {
            // The condition here means that just before current insertion point is a placeholder.
            // So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
        }
        else {
            if (self.string.length > currentRange.location) {
                [self setSelectedRange:NSMakeRange(UNSIGNED_DECREMENT(currentRange.location, 1), 0)];
            }
        }
    }
}


- (void)_adjustCursorPosition
{
    if (![self.textStorage isValidCursorPosition:self.insertionPoint]) {
#ifdef TODO
        NSRange placeholder = [(DVTSourceTextView*)self rangeOfPlaceholderFromCharacterIndex:self.insertionPoint
                                                                                     forward:NO
                                                                                        wrap:NO
                                                                                       limit:0];
        if (placeholder.location != NSNotFound && self.insertionPoint == (placeholder.location + placeholder.length)) {
            // The condition here means that just before current insertion point is a placeholder.
            // So we select the the place holder and its already selected by "selectedPreviousPlaceholder" above
            [self xvim_moveCursor:placeholder.location preserveColumn:YES];
        }
        else {
#endif
        [self xvim_moveCursor:self.insertionPoint - 1 preserveColumn:YES];
    }
}

/**
 * Applies internal state to underlying view (self).
 * This update self's property and applies the visual effect on it.
 * All the state need to express Vim is held by this class and
 * we use self to express it visually.
 **/
- (void)xvim_syncStateWithScroll:(BOOL)scroll
{
    self.xvim_lockSyncStateFromView = YES;
    // Reset current selection
    if (self.cursorMode == XVIM_CURSOR_MODE_COMMAND) {
        [self _adjustCursorPosition];
    }

    [self setSelectedRanges:self.xvim_selectedRanges affinity:NSSelectionAffinityDownstream stillSelecting:NO];

    if (scroll) {
        [self xvim_scrollTo:self.insertionPoint];
    }
    self.xvim_lockSyncStateFromView = NO;
}

- (void)xvim_syncStateFromView
{
    // TODO: handle block selection (if selectedRanges have multiple ranges )
    if (self.xvim_lockSyncStateFromView) {
        return;
    }
    let range = self.selectedRange;
    //DEBUG_LOG(@"Selected Range(TotalLen:%d): Loc:%d Len:%d", self.string.length, range.location, range.length);
    self.selectionMode = XVIM_VISUAL_NONE;
    [self xvim_moveCursor:range.location preserveColumn:NO];
    self.selectionBegin = self.insertionPoint;
}

// SELECTION
#pragma mark - SELECTION

// xvim_setSelectedRange is an internal method
// This is used when you want to call [self setSelectedRrange];
// The difference is that this checks the bounds(range can not be include EOF) and protect from Assersion
// Cursor can be on EOF but EOF can not be selected.
// It means that
//   - setSelectedRange:NSMakeRange( indexOfEOF, 0 )   is allowed
//   - setSelectedRange:NSMakeRange( indexOfEOF, 1 )   is not allowed
- (void)xvim_setSelectedRange:(NSRange)range
{
    if ([self.textStorage isEOF:range.location]) {
        [self setSelectedRange:NSMakeRange(range.location, 0)];
        return;
    }
    if (0 == range.length) {
        // No need to check bounds
    }
    else {
        NSUInteger lastIndex = range.location + range.length - 1;
        if ([self.textStorage isEOF:lastIndex]) {
            range.length--;
        }
        else {
            // No need to change the selection area
        }
    }
    [self setSelectedRange:range];
}

- (NSArray<NSValue *>*)xvim_selectedRanges
{
    if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        return [NSArray arrayWithObject:[NSValue valueWithRange:[self xvim_selectedRange]]];
    }

    NSMutableArray* rangeArray = [[NSMutableArray alloc] init];
    NSTextStorage* ts = self.textStorage;
    XVimSelection sel = self.xvim_selectedBlock;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        let begin = [self xvim_indexOfLineNumber:line column:sel.left];
        var end = [self xvim_indexOfLineNumber:line column:sel.right];

        if ([ts isEOF:begin]) {
            continue;
        }
        if ([ts isEOF:end]) {
            end--;
        }
        else if (sel.right != XVimSelectionEOL && [ts isEOL:end]) {
            end--;
        }
        [rangeArray addObject:[NSValue valueWithRange:NSMakeRange(begin, end - begin + 1)]];
    }
    return rangeArray;
}

- (XVimRange)xvim_selectedLines
{
    if (self.selectionMode == XVIM_VISUAL_NONE) { // its not in selecting mode
        return (XVimRange){ NSNotFound, NSNotFound };
    }
    else {
        NSUInteger l1 = [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint];
        NSUInteger l2 = [self.textStorage xvim_lineNumberAtIndex:self.selectionBegin];

        return (XVimRange){ MIN(l1, l2), MAX(l1, l2) };
    }
}

- (NSRange)xvim_selectedRange
{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        return NSMakeRange(self.insertionPoint, 0);
    }

    if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        var xvr = XVimMakeRange(self.selectionBegin, self.insertionPoint);

        if (xvr.begin > xvr.end) {
            xvr = XVimRangeSwap(xvr);
        }
        if ([self.textStorage isEOF:xvr.end]) {
            xvr.end--;
        }
        return XVimMakeNSRange(xvr);
    }

    if (self.selectionMode == XVIM_VISUAL_LINE) {
        let lines = self.xvim_selectedLines;
        let begin = [self xvim_indexOfLineNumber:lines.begin];
        var end = [self xvim_indexOfLineNumber:lines.end];

        end = [self xvim_endOfLine:end];
        if ([self.textStorage isEOF:end]) {
            end--;
        }
        return NSMakeRange(begin, end - begin + 1);
    }

    return NSMakeRange(NSNotFound, 0);
}

- (XVimSelection)xvim_selectedBlock
{
    XVimSelection result = {};

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        result.top = result.bottom = result.left = result.right = NSNotFound;
        return result;
    }

    NSTextStorage* ts = self.textStorage;
    NSUInteger l1, c11, c12;
    NSUInteger l2, c21, c22;
    NSUInteger tabWidth = ts.xvim_tabWidth;
    NSUInteger pos = self.selectionBegin;
    l1 = [ts xvim_lineNumberAtIndex:pos];
    c11 = [ts xvim_columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.string characterAtIndex:pos] != '\t') {
        c12 = c11;
    }
    else {
        c12 = c11 + tabWidth - (c11 % tabWidth) - 1;
    }

    pos = self.insertionPoint;
    l2 = [ts xvim_lineNumberAtIndex:pos];
    c21 = [ts xvim_columnOfIndex:pos];
    if (!tabWidth || [ts isEOF:pos] || [self.string characterAtIndex:pos] != '\t') {
        c22 = c21;
    }
    else {
        c22 = c21 + tabWidth - (c21 % tabWidth) - 1;
    }

    if (l1 <= l2) {
        result.corner |= XVIM_VISUAL_BOTTOM;
    }
    if (c11 <= c22) {
        result.corner |= XVIM_VISUAL_RIGHT;
    }
    result.top = MIN(l1, l2);
    result.bottom = MAX(l1, l2);
    result.left = MIN(c11, c21);
    result.right = MAX(c12, c22);
    if (self.selectionToEOL) {
        result.right = XVimSelectionEOL;
    }
    return result;
}

// Text Range Queries
#pragma mark - TEXT RANGE QUERIES

- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion
{
    NSRange range = NSMakeRange(NSNotFound, 0);
    NSUInteger begin = current;
    NSUInteger end = NSNotFound;
    NSUInteger tmpPos = NSNotFound;
    NSUInteger start = NSNotFound;
    NSUInteger starts_end = NSNotFound;

    switch (motion.style) {
    case MOTION_NONE:
        // Do nothing
        break;
    case MOTION_FORWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = [self.textStorage next:begin count:motion.count option:motion.option info:motion.motionInfo];
        break;
    case MOTION_BACKWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = [self.textStorage prev:begin count:motion.count option:motion.option];
        break;
    case MOTION_WORD_FORWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = [self.textStorage wordsForward:begin count:motion.count option:motion.option info:motion.motionInfo];
        break;
    case MOTION_WORD_BACKWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = [self.textStorage wordsBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_END_OF_WORD_FORWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = [self.textStorage endOfWordsForward:begin count:motion.count option:motion.option];
        break;
    case MOTION_END_OF_WORD_BACKWARD:
        motion.option |= MOPT_PLACEHOLDER;
        end = begin;
        begin = [self.textStorage endOfWordsBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_LINE_FORWARD:
        if (motion.option & MOPT_DISPLAY_LINE) {
            end = [self xvim_displayNextLine:begin
                                      column:self.preservedColumn
                                       count:motion.count
                                      option:motion.option];
        }
        else {
            end = [self.textStorage nextLine:begin
                                      column:self.preservedColumn
                                       count:motion.count
                                      option:motion.option];
        }
        break;
    case MOTION_LINE_BACKWARD:
        if (motion.option & MOPT_DISPLAY_LINE) {
            end = [self xvim_displayPrevLine:begin
                                      column:self.preservedColumn
                                       count:motion.count
                                      option:motion.option];
        }
        else {
            end = [self.textStorage prevLine:begin
                                      column:self.preservedColumn
                                       count:motion.count
                                      option:motion.option];
        }
        break;
    case MOTION_BEGINNING_OF_LINE:
        end = [self.textStorage xvim_startOfLine:begin];
        if (end == NSNotFound) {
            end = current;
        }
        break;
    case MOTION_END_OF_LINE:
        tmpPos = [self.textStorage nextLine:begin column:0 count:motion.count - 1 option:MOPT_NONE];
        end = [self xvim_endOfLine:tmpPos];
        if (end == NSNotFound) {
            end = tmpPos;
        }
        break;
    case MOTION_SENTENCE_FORWARD:
        end = [self.textStorage sentencesForward:begin count:motion.count option:motion.option];
        break;
    case MOTION_SENTENCE_BACKWARD:
        end = [self.textStorage sentencesBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_PARAGRAPH_FORWARD:
        end = [self.textStorage paragraphsForward:begin count:motion.count option:motion.option];
        break;
    case MOTION_PARAGRAPH_BACKWARD:
        end = [self.textStorage paragraphsBackward:begin count:motion.count option:motion.option];
        break;
    case MOTION_NEXT_CHARACTER:
        end = [self.textStorage nextCharacterInLine:begin
                                              count:motion.count
                                          character:motion.character
                                             option:MOPT_NONE];
        break;
    case MOTION_PREV_CHARACTER:
        end = [self.textStorage prevCharacterInLine:begin
                                              count:motion.count
                                          character:motion.character
                                             option:MOPT_NONE];
        break;
    case MOTION_TILL_NEXT_CHARACTER:
        end = [self.textStorage nextCharacterInLine:begin
                                              count:motion.count
                                          character:motion.character
                                             option:motion.option];
        if (end != NSNotFound) {
            end--;
        }
        break;
    case MOTION_TILL_PREV_CHARACTER:
        end = [self.textStorage prevCharacterInLine:begin
                                              count:motion.count
                                          character:motion.character
                                             option:motion.option];
        if (end != NSNotFound) {
            end++;
        }
        break;
    case MOTION_NEXT_FIRST_NONBLANK:
        end = [self.textStorage nextLine:begin column:0 count:motion.count option:motion.option];
        tmpPos = [self.textStorage xvim_nextNonblankInLineAtIndex:end allowEOL:NO];
        if (NSNotFound != tmpPos) {
            end = tmpPos;
        }
        break;
    case MOTION_PREV_FIRST_NONBLANK:
        end = [self.textStorage prevLine:begin column:0 count:motion.count option:motion.option];
        tmpPos = [self.textStorage xvim_nextNonblankInLineAtIndex:end allowEOL:NO];
        if (NSNotFound != tmpPos) {
            end = tmpPos;
        }
        break;
    case MOTION_FIRST_NONBLANK:
        end = [self.textStorage xvim_firstNonblankInLineAtIndex:begin allowEOL:NO];
        break;
    case MOTION_LINENUMBER:
        end = [self xvim_indexOfLineNumber:motion.line column:self.preservedColumn];
        if (NSNotFound == end) {
            end = [self xvim_indexOfLineNumber:[self.textStorage xvim_numberOfLines]
                                                    column:self.preservedColumn];
        }
        break;
    case MOTION_PERCENT:
        end = [self xvim_indexOfLineNumber:1 + ([self.textStorage xvim_numberOfLines] - 1) * motion.count / 100];
        break;
    case MOTION_NEXT_MATCHED_ITEM:
        end = [self.textStorage positionOfMatchedPair:begin];
        break;
    case MOTION_LASTLINE:
        end = [self xvim_indexOfLineNumber:[self.textStorage xvim_numberOfLines]
                                                column:self.preservedColumn];
        break;
    case MOTION_HOME:
        end = [self.textStorage
                    xvim_firstNonblankInLineAtIndex:
                                [self xvim_indexOfLineNumber:[self xvim_lineNumberFromTop:motion.count]]
                                           allowEOL:YES];
        break;
    case MOTION_MIDDLE:
        end = [self.textStorage xvim_firstNonblankInLineAtIndex:
                                            [self xvim_indexOfLineNumber:[self xvim_lineNumberAtMiddle]]
                                                       allowEOL:YES];
        break;
    case MOTION_BOTTOM:
        end = [self.textStorage
                    xvim_firstNonblankInLineAtIndex:
                                [self
                                            xvim_indexOfLineNumber:[self xvim_lineNumberFromBottom:motion.count]]
                                           allowEOL:YES];
        break;
    case MOTION_SEARCH_FORWARD:
        end = [self.textStorage searchRegexForward:motion.regex
                                              from:self.insertionPoint
                                             count:motion.count
                                            option:motion.option]
                          .location;
        if (end == NSNotFound && !(motion.option & MOPT_SEARCH_WRAP)) {
            NSRange r = [self xvim_currentWord:MOPT_NONE];
            end = r.location;
        }
        break;
    case MOTION_SEARCH_BACKWARD:
        end = [self.textStorage searchRegexBackward:motion.regex
                                               from:self.insertionPoint
                                              count:motion.count
                                             option:motion.option]
                          .location;
        if (end == NSNotFound && !(motion.option & MOPT_SEARCH_WRAP)) {
            NSRange r = [self xvim_currentWord:MOPT_NONE];
            end = r.location;
        }
        break;
    case MOTION_SEARCH_MATCHED_FORWARD:
    case MOTION_SEARCH_MATCHED_BACKWARD:
        if (motion.style == MOTION_SEARCH_MATCHED_FORWARD) {
            range = [self.textStorage searchRegexForward:motion.regex from:self.insertionPoint count:motion.count option:motion.option];
        } else {
            range = [self.textStorage searchRegexBackward:motion.regex from:self.insertionPoint count:motion.count option:motion.option];
        }

        // SEARCH_MATCHED uses TEXTOBJECT family code, it's more convenient but require this workaround
        range.length += 1;
        if (range.location != NSNotFound) {
            [self xvim_setSelectedRange:NSMakeRange(range.location, 0)];
        }
        break;
    case TEXTOBJECT_WORD:
        range = [self.textStorage currentWord:begin count:motion.count option:motion.option];
        break;
    case TEXTOBJECT_UNDERSCORE:
        range = [self.textStorage currentCamelCaseWord:begin count:motion.count option:motion.option];
        break;
    case TEXTOBJECT_BRACES:
        range = xv_current_block(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '{', '}');
        break;
    case TEXTOBJECT_PARAGRAPH:
        // Not supported
        start = self.insertionPoint;
        if (start != 0) {
            start = [self.textStorage paragraphsBackward:self.insertionPoint
                                                   count:1
                                                  option:MOPT_PARA_BOUND_BLANKLINE];
        }
        starts_end = [self.textStorage paragraphsForward:start count:1 option:MOPT_PARA_BOUND_BLANKLINE];
        end = [self.textStorage paragraphsForward:self.insertionPoint
                                            count:motion.count
                                           option:MOPT_PARA_BOUND_BLANKLINE];

        if (starts_end != end) {
            start = starts_end;
        }
        range = NSMakeRange(start, end - start);
        break;
    case TEXTOBJECT_PARENTHESES:
        range = xv_current_block(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '(', ')');
        break;
    case TEXTOBJECT_SENTENCE:
        // Not supported
        break;
    case TEXTOBJECT_ANGLEBRACKETS:
        range = xv_current_block(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '<', '>');
        break;
    case TEXTOBJECT_SQUOTE:
        range = xv_current_quote(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '\'');
        break;
    case TEXTOBJECT_DQUOTE:
        range = xv_current_quote(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '\"');
        break;
    case TEXTOBJECT_TAG:
        // Not supported
        break;
    case TEXTOBJECT_BACKQUOTE:
        range = xv_current_quote(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '`');
        break;
    case TEXTOBJECT_SQUAREBRACKETS:
        range = xv_current_block(self.string, current, motion.count, !(motion.option & MOPT_TEXTOBJECT_INNER), '[', ']');
        break;
    case MOTION_LINE_COLUMN:
        end = [self xvim_indexOfLineNumber:motion.line column:motion.column];
        if (NSNotFound == end) {
            end = current;
        }
        break;
    case MOTION_POSITION:
    case MOTION_POSITION_JUMP:
        end = motion.position;
        break;
    }

    if (range.location != NSNotFound) { // This block is for TEXTOBJECT
        begin = range.location;
        if (range.length == 0) {
            end = NSNotFound;
        }
        else {
            end = range.location + range.length - 1;
        }
    }
    let r = XVimMakeRange(begin, end);
    //DEBUG_LOG(@"range location:%u  length:%u", r.begin, r.end - r.begin + 1);
    return r;
}

// Perform actions before entering insertion mode. For example, for visual block mode:
// kill the current selection, and yank it.
- (void)xvim_insert:(XVimInsertMode)insertMode blockColumn:(NSUInteger*)column blockLines:(XVimRange*)lines
{
    if (column)
        *column = NSNotFound;
    if (lines)
        *lines = XVimMakeRange(NSNotFound, NSNotFound);

    if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        XVimSelection sel = [self xvim_selectedBlock];

        if (lines)
            *lines = XVimMakeRange(sel.top, sel.bottom);
        switch (insertMode) {
        case XVIM_INSERT_BLOCK_KILL:
            [self xvim_yankSelection:sel];
            [self xvim_killSelection:sel];
        /* falltrhough */
        case XVIM_INSERT_DEFAULT:
            self.insertionPoint = [self xvim_indexOfLineNumber:sel.top column:sel.left];
            if (column)
                *column = sel.left;
            break;
        case XVIM_INSERT_APPEND:
            if (sel.right != XVimSelectionEOL) {
                sel.right++;
            }
            self.insertionPoint = [self xvim_indexOfLineNumber:sel.top column:sel.right];
            if (column)
                *column = sel.right;
            break;
        default:
            NSAssert(false, @"unreachable");
            break;
        }
    }
    else if (insertMode != XVIM_INSERT_DEFAULT) {
        NSTextStorage* ts = self.textStorage;
        NSUInteger pos = self.insertionPoint;
        switch (insertMode) {
        case XVIM_INSERT_APPEND_EOL:
            self.insertionPoint = [self xvim_endOfLine:pos];
            break;
        case XVIM_INSERT_APPEND:
            NSAssert(self.cursorMode == XVIM_CURSOR_MODE_COMMAND, @"self.cursorMode shoud be CURSOR_MODE_COMMAND");
            if (![ts isEOF:pos] && ![ts isNewline:pos]) {
                self.insertionPoint = pos + 1;
            }
            break;
        case XVIM_INSERT_BEFORE_FIRST_NONBLANK:
            self.insertionPoint = [ts xvim_firstNonblankInLineAtIndex:pos allowEOL:YES];
            break;
        default:
            NSAssert(false, @"unreachable");
        }
    }
    self.cursorMode = XVIM_CURSOR_MODE_INSERT;
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (NSRange)xvim_currentWord:(MOTION_OPTION)opt
{
    return [self.textStorage currentWord:self.insertionPoint count:1 option:opt | MOPT_TEXTOBJECT_INNER];
}

// UTILITY
#pragma MARK - UTILITY

- (void)xvim_insertSpaces:(NSUInteger)count replacementRange:(NSRange)replacementRange
{
    if (count || replacementRange.length) {
        [self insertText:[NSString stringMadeOfSpaces:count] replacementRange:replacementRange];
    }
}

- (unichar)xvim_characterAtIndex:(NSInteger)idx
{
    if (self.string.length == 0)
        return 0;
    clamp(idx, 0, self.string.length - 1);
    return [self.string characterAtIndex:idx];
}

- (NSUInteger)xvim_lineNumberFromBottom:(NSUInteger)count
{
    NSAssert(0 != count, @"count starts from 1");
    let bottomPoint = NSMakePoint(0.0, self.contentSize.height);
    NSInteger bottomLine = [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:bottomPoint], 0)].location;
    clamp(bottomLine, 0, self.lineCount - 1);
    if (count > 1) {
        bottomLine -= (count - 1);
        clamp(bottomLine, 0, self.lineCount - 1);
    }
    return bottomLine + 1;
}

- (NSUInteger)xvim_lineNumberAtMiddle
{
    let topLine = [self xvim_lineNumberFromTop:1];
    let bottomLine = [self xvim_lineNumberFromBottom:1];
    return (topLine + bottomLine) / 2;
}

- (NSUInteger)xvim_lineNumberFromTop:(NSUInteger)count
{
    NSAssert(0 != count, @"count starts from 1");
    NSInteger topLine = [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:NSZeroPoint], 0)].location;
    clamp(topLine, 0, self.lineCount - 1);
    if (count > 1) {
        topLine += (count - 1);
        clamp(topLine, 0, self.lineCount - 1);
    }
    return topLine + 1;
}

// Insert some text at the same column position, for a range of lines
// Used by the XVim visual block mode, and shift functions
- (void)xvim_blockInsertFixupWithText:(NSString*)text insertMode:(XVimInsertMode)insertMode
    count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines
{
    NSMutableString* buf = nil;
    NSTextStorage* ts;
    NSUInteger tabWidth;

    self.xvim_lockSyncStateFromView = YES;
    xvim_on_exit {
        self.xvim_lockSyncStateFromView = NO;
    };

    if (count == 0 || lines.begin > lines.end || text.length == 0) {
        return;
    }
    if ([text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location != NSNotFound) {
        return;
    }
    if (count > 1) {
        buf = [[NSMutableString alloc] initWithCapacity:text.length * count];
        for (NSUInteger i = 0; i < count; i++) {
            [buf appendString:text];
        }
        text = buf;
    }

    tabWidth = self.textStorage.xvim_tabWidth;

    for (NSUInteger line = lines.begin; line <= lines.end; line++) {
        ts = self.textStorage;
        var pos = [self xvim_indexOfLineNumber:line column:column];
        if (pos == NSNotFound) {
            continue;
        }

        if (column != XVimSelectionEOL && [ts isEOL:pos]) {
            if (insertMode == XVIM_INSERT_SPACES && column == 0) {
                continue;
            }
            if ([ts xvim_columnOfIndex:pos] < column) {
                if (insertMode != XVIM_INSERT_APPEND) {
                    continue;
                }
                [self xvim_insertSpaces:column - [ts xvim_columnOfIndex:pos] replacementRange:NSMakeRange(pos, 0)];
            }
        }
        if (tabWidth && [self.string characterAtIndex:pos] == '\t') {
            NSUInteger col = [ts xvim_columnOfIndex:pos];

            if (col < column) {
                [self xvim_insertSpaces:tabWidth - (col % tabWidth) replacementRange:NSMakeRange(pos, 1)];
                pos += column - col;
            }
        }
        [self insertText:text replacementRange:NSMakeRange(pos, 0)];
    }
}

- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode
{
    if (self.selectionMode == XVIM_VISUAL_NONE && mode != XVIM_VISUAL_NONE) {
        self.selectionBegin = self.insertionPoint;
    }
    else if (self.selectionMode != XVIM_VISUAL_NONE && mode == XVIM_VISUAL_NONE) {
        self.selectionBegin = NSNotFound;
    }
    self.selectionMode = mode;
    [self xvim_syncStateWithScroll:NO];
}

- (void)xvim_escapeFromInsert
{
    if (self.cursorMode == XVIM_CURSOR_MODE_INSERT) {
        self.cursorMode = XVIM_CURSOR_MODE_COMMAND;
        if (![self.textStorage isBOL:self.insertionPoint]) {
            [self xvim_moveCursor:self.insertionPoint - 1 preserveColumn:NO];
        }
        [self xvim_syncStateWithScroll:YES];
    }
}

#pragma mark Status

- (NSUInteger)xvim_displayNextLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt
{
    for (NSUInteger i = 0; i < count; i++) {
        [self.sourceEditorView moveDown:self];
    }
    // TODO
    return [self.sourceEditorView
                       characterRangeForLineRange:NSMakeRange(self.sourceEditorView
                                                                          .accessibilityInsertionPointLineNumber,
                                                              1)]
                       .location
           + self.sourceEditorView.accessibilityColumnIndexRange.location;
}

- (NSUInteger)xvim_displayPrevLine:(NSUInteger)index column:(NSUInteger)column count:(NSUInteger)count option:(MOTION_OPTION)opt
{
    for (NSUInteger i = 0; i < count; i++) {
        [self.sourceEditorView moveUp:self];
    }
    NSRange range = self.sourceEditorView.accessibilityColumnIndexRange;
    return [self.sourceEditorView
                       characterRangeForLineRange:NSMakeRange(self.sourceEditorView
                                                                          .accessibilityInsertionPointLineNumber,
                                                              1)]
                       .location
           + range.location;
}

// UNDO

- (void)xvim_registerPositionForUndo:(NSUInteger)pos
{
    // XCODE93
    /*
    __weak SourceEditorViewProxy* weakSelf = self;
    [self.undoManager registerUndoWithTarget:self handler:^(id _Nonnull target){
        SourceEditorViewProxy* SELF = weakSelf;
        if (!SELF)
            return;
        XVimMotion* m = [XVimMotion style:MOTION_POSITION type:DEFAULT_MOTION_TYPE
                                         count:1];
        m.position = pos;
        [SELF xvim_move:m];
    }];
     */
}

- (void)xvim_registerInsertionPointForUndo
{
	[self xvim_registerPositionForUndo:self.selectedRange.location];
}

- (NSUInteger)numberOfSelectedLines
{
    if (XVIM_VISUAL_NONE == self.selectionMode) {
        return 0;
    }
    let lines = [self xvim_selectedLines];
    return lines.end - lines.begin + 1;
}

- (void)xvim_highlightNextSearchCandidate:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt forward:(BOOL)forward
{
    var range = NSMakeRange(NSNotFound, 0);
    if (forward) {
        range = [self.textStorage searchRegexForward:regex from:self.insertionPoint count:count option:opt];
    }
    else {
        range = [self.textStorage searchRegexBackward:regex from:self.insertionPoint count:count option:opt];
    }
    if (range.location != NSNotFound) {
        clamp(range.location, 0, self.string.length);
        [self scrollRangeToVisible:range];
        [self showFindIndicatorForRange:range];
    }
}

- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt
{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:YES];
}

- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt
{
    [self xvim_highlightNextSearchCandidate:regex count:count option:opt forward:NO];
}

- (void)xvim_updateFoundRanges:(NSString*)pattern withOption:(MOTION_OPTION)opt
{
    NSAssert(nil != pattern, @"pattern munst not be nil");
    if (!self.needsUpdateFoundRanges) {
        return;
    }

    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (opt & MOPT_SEARCH_CASEINSENSITIVE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }

    NSError* error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:pattern options:r_opts error:&error];
    if (nil != error) {
        [self.foundRanges removeAllObjects];
        return;
    }

    // Find all the maches
    NSString* string = self.string;
    if (string == nil) {
        return;
    }
    NSArray* matches = [regex matchesInString:string options:0 range:NSMakeRange(0, string.length)];
    [self.foundRanges setArray:matches];

    // Clear current highlight.
    [self xvim_clearHighlightText];

#ifdef TODO
    XVimOptions* options = [[XVim instance] options];
    NSColor* highlightColor = options.highlight[@"Search"][@"guibg"];
    // Add highlight
    for (NSTextCheckingResult* result in self.foundRanges) {
        [self.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName
                                            value:highlightColor
                                forCharacterRange:result.range];
    }
#endif

    [self setNeedsUpdateFoundRanges:NO];
}

- (void)xvim_clearHighlightText
{
    if (!self.needsUpdateFoundRanges) {
        return;
    }
#ifdef TODO
    NSString* string = self.string;
    [self.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName
                               forCharacterRange:NSMakeRange(0, string.length)];
#endif
    [self setNeedsUpdateFoundRanges:NO];
}

- (NSRange)xvim_currentNumber
{
    NSUInteger insertPoint = self.insertionPoint;
    NSUInteger n_start, n_end;
    NSUInteger x_start, x_end;
    NSString* s = self.string;
    unichar c;
    BOOL isOctal = YES;

    n_start = insertPoint;
    while (n_start > 0 && [s isDigit:n_start - 1]) {
        if (![s isOctDigit:n_start]) {
            isOctal = NO;
        }
        n_start--;
    }
    n_end = insertPoint;
    while (n_end < s.length && [s isDigit:n_end]) {
        if (![s isOctDigit:n_end]) {
            isOctal = NO;
        }
        n_end++;
    }

    x_start = n_start;
    while (x_start > 0 && [s isHexDigit:x_start - 1]) {
        x_start--;
    }
    x_end = n_end;
    while (x_end < s.length && [s isHexDigit:x_end]) {
        x_end++;
    }

    // first deal with Hex: 0xNNNNN
    // case 1: check for insertion point on the '0' or 'x'
    if (x_end - x_start == 1) {
        NSUInteger end = x_end;
        if (end < s.length && [s characterAtIndex:end] == 'x') {
            do {
                end++;
            } while (end < s.length && [s isHexDigit:end]);
            if (insertPoint < end && end - x_start > 2) {
                // YAY it's hex for real!!!
                return NSMakeRange(x_start, end - x_start);
            }
        }
    }

    // case 2: check whether we're after 0x
    if (insertPoint < x_end && x_end - x_start >= 1) {
        if (x_start >= 2 && [s characterAtIndex:x_start - 1] == 'x' && [s characterAtIndex:x_start - 2] == '0') {
            return NSMakeRange(x_start - 2, x_end - x_start + 2);
        }
    }

    if (insertPoint == n_end || n_start - n_end == 0) {
        return NSMakeRange(NSNotFound, 0);
    }

    // okay it's not hex, if it's not octal, check for leading +/-
    if (n_start > 0 && !(isOctal && [s characterAtIndex:n_start] == '0')) {
        c = [s characterAtIndex:n_start - 1];
        if (c == '+' || c == '-') {
            n_start--;
        }
    }
    return NSMakeRange(n_start, n_end - n_start);
}

- (void)xvim_hideCompletions
{
    // TODO
}

@end
