//
//  SourceCodeEditorViewProxy+Operations.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceCodeEditorViewProxy+Operations.h"
#import "SourceCodeEditorViewProxy+Yank.h"
#import "SourceCodeEditorViewProxy+XVim.h"
#import "XVim.h"
#import "XVimMotion.h"
#import "XVimOptions.h"


@interface SourceCodeEditorViewProxy ()
@property (readwrite) NSUInteger selectionBegin;
@property (readwrite) NSUInteger insertionPoint;
@property (readwrite) NSUInteger preservedColumn;
@property (readwrite) BOOL selectionToEOL;
@property (strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
- (XVimRange)_xvim_selectedLines;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (NSRange)_xvim_getYankRange:(XVimMotion*)motion withRange:(XVimRange)to;
- (XVimSelection)_xvim_selectedBlock;
- (NSRange)_xvim_selectedRange;
- (void)xvim_registerInsertionPointForUndo;
- (void)xvim_registerPositionForUndo:(NSUInteger)pos;
- (NSRange)xvim_currentNumber;
@end


@implementation SourceCodeEditorViewProxy (Operations)

#pragma mark - COPYMOVE
- (void)xvim_copymove:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint withInsertionPoint:(NSUInteger)insertionPoint after:(BOOL)after onlyCopy:(BOOL)onlyCopy{
    [self xvim_registerInsertionPointForUndo];
    
    // Handle the copy
    XVimRange to = [self xvim_getMotionRange:motionPoint Motion:motion];
    if( NSNotFound == to.end ){
        return;
    }
    NSUInteger motionPointLine = [self xvim_lineNumberAtIndex:motionPoint];
    NSRange r = [self _xvim_getYankRange:motion withRange:to];
    NSString* s = [self.string substringWithRange:r];
    
    // Handle the paste
    NSUInteger targetPos = insertionPoint;
    NSUInteger targetLine = [self xvim_lineNumberAtIndex:insertionPoint];
    NSUInteger cursorOffset = 1;
    // If we are pasting after any line but a blank last one, add a new line to paste into.
    // then, the cursor will moved to this new line automatically, and we change targetPos to that
    BOOL eof = [self.textStorage isEOF:targetPos];
    BOOL blank = [self.textStorage isBlankline:targetPos];
    if(after && !(eof && blank)){
        [self xvim_insertNewlineBelowLine:targetLine];
        targetPos = self.insertionPoint;
        s = [s substringToIndex:s.length-1]; // Remove the last newline in the copied text, since we just added one above
        cursorOffset = 0;
    }
    [self insertText:s replacementRange:NSMakeRange(targetPos,0)];
    
    // Move the cursor to last line of what we pasted.
    NSUInteger cursorPos = [self.textStorage xvim_firstNonblankInLineAtIndex:(targetPos+s.length-cursorOffset) allowEOL:YES];
    [self xvim_moveCursor: cursorPos preserveColumn:NO];
    
    // Delete the copied text if required
    if(!onlyCopy){
        NSUInteger cursorLine = self.insertionLine;
        NSUInteger lineAdjustment = (cursorLine-targetLine)+(after ? 0 : 1);
        
        // Adjust the starting line of the text to delete, if required
        if(motionPointLine>targetLine){
            motionPointLine += lineAdjustment;
        }
        // Delete the copied text
        XVimRange to2 = [self xvim_getMotionRange:[self.textStorage xvim_indexOfLineNumber:motionPointLine] Motion:motion];
        [self insertText:@"" replacementRange:[self _xvim_getDeleteRange:motion withRange:to2]];
        
        // Adjust the line of the last line of what we pasted, if required
        if(cursorLine>motionPointLine){ // cursorLine needs to be adjusted
            cursorLine -= lineAdjustment+(eof && blank ? 1 : 0); // If we targeted the last blank line, increase the line adjustment to account for it
        }
        // Redo the move of the cursor to last line of what we pasted.
        cursorPos = [self.textStorage xvim_firstNonblankInLineAtIndex:[self.textStorage xvim_indexOfLineNumber:cursorLine] allowEOL:YES];
        [self xvim_moveCursor: cursorPos preserveColumn:NO];
    }
    
    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

#pragma mark - DELETE

- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank
{
    return [self xvim_delete:motion withMotionPoint:self.insertionPoint andYank:yank];
}

- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank
{
    NSAssert(!(self.selectionMode == XVIM_VISUAL_NONE && motion == nil),
             @"motion must be specified if current selection mode is not visual");
    if (motionPoint == NSNotFound || (motionPoint == 0 && self.string.length == 0)) {
        return NO;
    }
    NSUInteger newPos = NSNotFound;

    [self xvim_beginEditTransaction];
    xvim_on_exit { [self xvim_endEditTransaction]; };

    motion.info.deleteLastLine = NO;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange motionRange = [self xvim_getMotionRange:motionPoint Motion:motion];
        if (motionRange.end == NSNotFound) {
            return NO;
        }
        // We have to treat some special cases
        // When a cursor get end of line with "l" motion, make the motion type to inclusive.
        // This make you to delete the last character. (if its exclusive last character never deleted with "dl")
        if (motion.motion == MOTION_FORWARD && motion.info.reachedEndOfLine) {
            if (motion.type == CHARACTERWISE_EXCLUSIVE) {
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if (motion.type == CHARACTERWISE_INCLUSIVE) {
                motion.type = CHARACTERWISE_EXCLUSIVE;
            }
        }
        if (motion.motion == MOTION_WORD_FORWARD) {
            if ((motion.info.isFirstWordInLine && motion.info.lastEndOfLine != NSNotFound)) {
                // Special cases for word move over a line break.
                motionRange.end = motion.info.lastEndOfLine;
                motion.type = CHARACTERWISE_INCLUSIVE;
            }
            else if (motion.info.reachedEndOfLine) {
                if (motion.type == CHARACTERWISE_EXCLUSIVE) {
                    motion.type = CHARACTERWISE_INCLUSIVE;
                }
                else if (motion.type == CHARACTERWISE_INCLUSIVE) {
                    motion.type = CHARACTERWISE_EXCLUSIVE;
                }
            }
        }
        NSRange r = [self _xvim_getDeleteRange:motion withRange:motionRange];
        if (yank) {
            [self _xvim_yankRange:r withType:motion.type];
        }
        [self insertText:@"" replacementRange:r];
        if (motion.motion == TEXTOBJECT_SQUOTE || motion.motion == TEXTOBJECT_DQUOTE
            || motion.motion == TEXTOBJECT_BACKQUOTE || motion.motion == TEXTOBJECT_PARENTHESES
            || motion.motion == TEXTOBJECT_BRACES || motion.motion == TEXTOBJECT_SQUAREBRACKETS
            || motion.motion == TEXTOBJECT_ANGLEBRACKETS) {
            newPos = r.location;
        }
        else if (motion.type == LINEWISE) {
            newPos = [self.textStorage xvim_firstNonblankInLineAtIndex:r.location allowEOL:YES];
        }
    }
    else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        BOOL toFirstNonBlank = (self.selectionMode == XVIM_VISUAL_LINE);
        NSRange range = [self _xvim_selectedRange];

        // Currently not supportin deleting EOF with selection mode.
        // This is because of the fact that NSTextView does not allow select EOF

        if (yank) {
            [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
        }
        [self insertText:@"" replacementRange:range];
        if (toFirstNonBlank) {
            newPos = [self.textStorage xvim_firstNonblankInLineAtIndex:range.location allowEOL:YES];
        }
        else {
            newPos = range.location;
        }
    }
    else {
        XVimSelection sel = [self _xvim_selectedBlock];
        if (yank) {
            [self _xvim_yankSelection:sel];
        }
        [self _xvim_killSelection:sel];

        newPos = [self xvim_indexOfLineNumber:sel.top column:sel.left];
    }

    [self.xvimDelegate textView:self didDelete:self.lastYankedText withType:self.lastYankedType];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    if (newPos != NSNotFound) {
        [self xvim_moveCursor:newPos preserveColumn:NO];
        [self xvim_syncStateWithScroll:NO];
    }
    return YES;
}


#pragma mark - INSERT


- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column
{
    NSUInteger pos = [self xvim_indexOfLineNumber:line column:column];
    if (pos == NSNotFound) {
        return;
    }
    [self insertText:str replacementRange:NSMakeRange(pos, 0)];
}

- (void)xvim_insertNewlineBelowLine:(NSUInteger)line
{
    NSAssert(line != 0, @"line number starts from 1");
    NSUInteger pos = [self xvim_indexOfLineNumber:line];
    if (NSNotFound == pos) {
        return;
    }
    pos = [self xvim_endOfLine:pos];
    [self insertText:@"\n" replacementRange:NSMakeRange(pos, 0)];
    [self xvim_moveCursor:pos + 1 preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
}

- (void)xvim_insertNewlineBelowCurrentLine
{
    [self xvim_insertNewlineBelowLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineBelowCurrentLineWithIndent
{
    NSUInteger tail = [self xvim_endOfLine:self.insertionPoint];
    [self setSelectedRange:NSMakeRange(tail, 0)];
    [self insertNewline:self];
}

- (void)xvim_insertNewlineAboveLine:(NSUInteger)line
{
    NSAssert(line != 0, @"line number starts from 1");
    NSUInteger pos = [self xvim_indexOfLineNumber:line];
    if (NSNotFound == pos) {
        return;
    }
    if (1 != line) {
        [self xvim_insertNewlineBelowLine:line - 1];
    }
    else {
        [self insertText:@"\n" replacementRange:NSMakeRange(0, 0)];
        [self setSelectedRange:NSMakeRange(0, 0)];
    }
}

- (void)xvim_insertNewlineAboveCurrentLine
{
    [self xvim_insertNewlineAboveLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
}

- (void)xvim_insertNewlineAboveCurrentLineWithIndent
{
    NSUInteger head = [self.textStorage xvim_startOfLine:self.insertionPoint];
    if (0 != head) {
        [self setSelectedRange:NSMakeRange(head - 1, 0)];
        [self insertNewline:self];
    }
    else {
        [self setSelectedRange:NSMakeRange(head, 0)];
        [self insertNewline:self];
        [self setSelectedRange:NSMakeRange(0, 0)];
    }
}

- (void)xvim_insertNewlineAboveAndInsertWithIndent
{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineAboveCurrentLineWithIndent];
}

- (void)xvim_insertNewlineBelowAndInsertWithIndent
{
    self.cursorMode = CURSOR_MODE_INSERT;
    [self xvim_insertNewlineBelowCurrentLineWithIndent];
}


#pragma mark - REPLACE

- (BOOL)xvim_replaceCharacters:(unichar)c count:(NSUInteger)count
{
    NSUInteger eol = [self xvim_endOfLine:self.insertionPoint];
    // Note : endOfLine may return one less than self.insertionPoint if self.insertionPoint is on newline
    if (NSNotFound == eol) {
        return NO;
    }
    NSUInteger end = self.insertionPoint + count;
    for (NSUInteger pos = self.insertionPoint; pos < end; ++pos) {
        NSString* text = [NSString stringWithFormat:@"%C", c];
        if (pos < eol) {
            [self insertText:text replacementRange:NSMakeRange(pos, 1)];
        }
        else {
            [self insertText:text];
        }
    }
    return YES;
}

- (BOOL)xvim_change:(XVimMotion*)motion
{
    // We do not need to call this since this method uses xvim_delete to operate on text
    //[self xvim_registerInsertionPointForUndo];

    BOOL insertNewline = NO;
    if (motion.type == LINEWISE || self.selectionMode == XVIM_VISUAL_LINE) {
        // 'cc' deletes the lines but need to keep the last newline.
        // So insertNewline as 'O' does before entering insert mode
        insertNewline = YES;
    }

    // "cw" is like "ce" if the cursor is on a word ( in this case blank line is not treated as a word )
    if (motion.motion == MOTION_WORD_FORWARD && [self.textStorage isNonblank:self.insertionPoint]) {
        motion.motion = MOTION_END_OF_WORD_FORWARD;
        motion.type = CHARACTERWISE_INCLUSIVE;
        motion.option |= MOPT_CHANGE_WORD;
    }
    // We have to set cursor mode insert before calling delete
    // because delete adjust cursor position when the cursor is end of line. (e.g. C command).
    // This behaves that insertion position after delete is one character before the last char of the line.
    self.cursorMode = CURSOR_MODE_INSERT;
    if (![self xvim_delete:motion andYank:YES]) {
        // And if the delele failed we set the cursor mode back to command.
        // The cursor mode should be kept in Evaluators so we should make some delegation to it.
        self.cursorMode = CURSOR_MODE_COMMAND;
        return NO;
    }
    if (motion.info.deleteLastLine) {
        [self xvim_insertNewlineAboveLine:[self.textStorage xvim_lineNumberAtIndex:self.insertionPoint]];
    }
    else if (insertNewline) {
        [self xvim_insertNewlineAboveCurrentLineWithIndent];
    }
    else {
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [self xvim_syncStateWithScroll:NO];
    return YES;
}


#pragma mark - CASE

- (void)xvim_swapCaseForRange:(NSRange)range
{
    [self xvim_beginEditTransaction];
    xvim_on_exit { [self xvim_endEditTransaction]; };

    NSString* text = self.string;


    NSMutableString* substring = [[text substringWithRange:range] mutableCopy];
    for (NSUInteger i = 0; i < range.length; ++i) {
        NSRange currentRange = NSMakeRange(i, 1);
        NSString* currentCase = [substring substringWithRange:currentRange];
        NSString* upperCase = [currentCase uppercaseString];

        NSRange replaceRange = NSMakeRange(i, 1);
        if ([currentCase isEqualToString:upperCase]) {
            [substring replaceCharactersInRange:replaceRange withString:[currentCase lowercaseString]];
        }
        else {
            [substring replaceCharactersInRange:replaceRange withString:upperCase];
        }
    }

    [self insertText:substring replacementRange:range];
}


- (void)xvim_swapCase:(XVimMotion*)motion
{
    if (self.insertionPoint == 0 && self.string.length == 0) {
        return;
    }

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        if (motion.motion == MOTION_NONE) {
            XVimMotion* m = XVIM_MAKE_MOTION(MOTION_FORWARD, CHARACTERWISE_EXCLUSIVE, MOPT_LEFT_RIGHT_NOWRAP, motion.count);
            XVimRange r = [self xvim_getMotionRange:self.insertionPoint Motion:m];
            if (r.end == NSNotFound) {
                return;
            }
            if (m.info.reachedEndOfLine) {
                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin
                                                                                To:r.end
                                                                              Type:CHARACTERWISE_INCLUSIVE]];
            }
            else {
                [self xvim_swapCaseForRange:[self xvim_getOperationRangeFrom:r.begin
                                                                                To:r.end
                                                                              Type:CHARACTERWISE_EXCLUSIVE]];
            }
            [self xvim_moveCursor:r.end preserveColumn:NO];
        }
        else {
            NSRange r;
            XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
            if (to.end == NSNotFound) {
                return;
            }
            r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
            [self xvim_swapCaseForRange:r];
            [self xvim_moveCursor:r.location preserveColumn:NO];
        }
    }
    else {
        NSArray* ranges = [self xvim_selectedRanges];
        for (NSValue* val in ranges) {
            [self xvim_swapCaseForRange:[val rangeValue]];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_makeLowerCase:(XVimMotion*)motion
{
    if (self.insertionPoint == 0 && [self.string length] == 0) {
        return;
    }

    NSString* s = self.string;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        NSRange r;
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
        [self insertText:[[s substringWithRange:r] lowercaseString] replacementRange:r];
        [self xvim_moveCursor:r.location preserveColumn:NO];
    }
    else {
        NSArray* ranges = [self xvim_selectedRanges];
        for (NSValue* val in ranges) {
            [self insertText:[[s substringWithRange:val.rangeValue] lowercaseString] replacementRange:val.rangeValue];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_makeUpperCase:(XVimMotion*)motion
{
    if (self.insertionPoint == 0 && [self.string length] == 0) {
        return;
    }

    NSString* s = self.string;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        NSRange r;
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        r = [self xvim_getOperationRangeFrom:to.begin
                                            To:to.end
                                          Type:motion.type]; // TODO: use to.begin instead of insertionPoint
        [self insertText:[[s substringWithRange:r] uppercaseString] replacementRange:r];
        [self xvim_moveCursor:r.location preserveColumn:NO];
    }
    else {
        NSArray* ranges = [self xvim_selectedRanges];
        for (NSValue* val in ranges) {
            [self insertText:[[s substringWithRange:val.rangeValue] uppercaseString] replacementRange:val.rangeValue];
        }
        [self xvim_moveCursor:[[ranges objectAtIndex:0] rangeValue].location preserveColumn:NO];
    }

    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


#pragma mark - JOIN

- (void)xvim_joinAtLineNumber:(NSUInteger)line
{
    BOOL needSpace = NO;
    NSUInteger headOfLine = [self xvim_indexOfLineNumber:line];
    if (headOfLine == NSNotFound) {
        return;
    }

    NSUInteger tail = [self xvim_endOfLine:headOfLine];
    if ([self.textStorage isEOF:tail]) {
        // This is the last line and nothing to join
        return;
    }

    // Check if we need to insert space between lines.
    NSUInteger lastOfLine = [self.textStorage xvim_lastOfLine:headOfLine];
    if (lastOfLine != NSNotFound) {
        // This is not blank line so we check if the last character is space or not .
        if (![self.textStorage isWhitespace:lastOfLine]) {
            needSpace = YES;
        }
    }

    // Search in next line for the position to join(skip white spaces in next line)
    NSUInteger posToJoin = [self.textStorage nextLine:headOfLine column:0 count:1 option:MOPT_NONE];

    posToJoin = [self.textStorage xvim_nextNonblankInLineAtIndex:posToJoin allowEOL:YES];
    if (![self.textStorage isEOF:posToJoin] && [self.string characterAtIndex:posToJoin] == ')') {
        needSpace = NO;
    }

    // delete "tail" to "posToJoin" excluding the position of "posToJoin" and insert space if need.
    if (needSpace) {
        [self insertText:@" " replacementRange:NSMakeRange(tail, posToJoin - tail)];
    }
    else {
        [self insertText:@"" replacementRange:NSMakeRange(tail, posToJoin - tail)];
    }

    // Move cursor
    [self xvim_moveCursor:tail preserveColumn:NO];
}

- (void)xvim_join:(NSUInteger)count addSpace:(BOOL)addSpace
{
    NSUInteger line;

    [self xvim_registerInsertionPointForUndo];

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        line = self.insertionLine;
    }
    else {
        XVimRange lines = [self _xvim_selectedLines];

        line = lines.begin;
        count = MAX((NSUInteger)1, UNSIGNED_DECREMENT(lines.end, lines.begin));
    }

    if (addSpace) {
        for (NSUInteger i = 0; i < count; i++) {
            [self xvim_joinAtLineNumber:line];
        }
    }
    else {
        NSUInteger pos = [self xvim_indexOfLineNumber:line];

        for (NSUInteger i = 0; i < count; i++) {
            NSUInteger tail = [self xvim_endOfLine:pos];

            if (tail != NSNotFound && ![self.textStorage isEOF:tail]) {
                [self insertText:@"" replacementRange:NSMakeRange(tail, 1)];
                [self xvim_moveCursor:tail preserveColumn:NO];
            }
        }
    }

    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


#pragma mark - SHIFT

- (void)_xvim_shift:(XVimMotion*)motion right:(BOOL)right
{
    [self _xvim_shift:motion right:right withMotionPoint:self.insertionPoint count:1];
}

- (void)_xvim_shift:(XVimMotion*)motion
                      right:(BOOL)right
            withMotionPoint:(NSUInteger)motionPoint
                      count:(NSUInteger)count
{
    if (motionPoint == 0 && self.string.length == 0) {
        return;
    }
    [self xvim_beginEditTransaction];
    xvim_on_exit { [self xvim_endEditTransaction]; };

    NSUInteger shiftWidth = self.textStorage.xvim_indentWidth;
    NSUInteger column = 0;
    XVimRange lines;
    BOOL blockMode = NO;

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self xvim_getMotionRange:motionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        NSTextStorage* ts = self.textStorage;
        lines = XVimMakeRange([ts xvim_lineNumberAtIndex:to.begin], [ts xvim_lineNumberAtIndex:to.end]);
        shiftWidth *= count;
    }
    else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        lines = [self _xvim_selectedLines];
        shiftWidth *= motion.count;
    }
    else {
        XVimSelection sel = [self _xvim_selectedBlock];

        column = sel.left;
        lines = XVimMakeRange(sel.top, sel.bottom);
        blockMode = YES;
        shiftWidth *= motion.count;
    }

    NSUInteger pos = [self xvim_indexOfLineNumber:lines.begin column:0];

    if (!blockMode) {
        [self xvim_registerPositionForUndo:[self.textStorage xvim_firstNonblankInLineAtIndex:pos allowEOL:YES]];
    }

    if (right) {
        NSString* s;
        if (XVIM.options.expandtab) {
            s = [NSString stringMadeOfSpaces:shiftWidth];
        }
        else {
            s = @"\t";
            while ([s length] < (shiftWidth / self.textStorage.xvim_indentWidth)) {
                s = [s stringByAppendingString:@"\t"];
            }
        }
        [self xvim_blockInsertFixupWithText:s mode:XVIM_INSERT_SPACES count:1 column:column lines:lines];
    }
    else {
        for (NSUInteger line = lines.begin; line <= lines.end; line++) {
            [self _xvim_removeSpacesAtLine:line column:column count:shiftWidth];
        }
    }

    if (blockMode) {
        pos = [self xvim_indexOfLineNumber:lines.begin column:column];
    }
    else {
        pos = [self.textStorage xvim_firstNonblankInLineAtIndex:pos allowEOL:YES];
    }

    [self xvim_moveCursor:pos preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}

- (void)xvim_shiftRight:(XVimMotion*)motion { [self _xvim_shift:motion right:YES]; }

- (void)xvim_shiftRight:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count
{
    [self _xvim_shift:motion right:YES withMotionPoint:motionPoint count:count];
}

- (void)xvim_shiftLeft:(XVimMotion*)motion { [self _xvim_shift:motion right:NO]; }

- (void)xvim_shiftLeft:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count
{
    [self _xvim_shift:motion right:NO withMotionPoint:motionPoint count:count];
}


#pragma mark - FILTER

- (void)xvim_filter:(XVimMotion*)motion
{
    if (self.insertionPoint == 0 && self.string.length == 0) {
        return;
    }

    NSUInteger insertionAfterFilter = self.insertionPoint;
    NSRange filterRange;
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self xvim_getMotionRange:self.insertionPoint Motion:motion];
        if (to.end == NSNotFound) {
            return;
        }
        filterRange = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:LINEWISE];
    }
    else {
        XVimRange lines = [self _xvim_selectedLines];
        NSUInteger from = [self xvim_indexOfLineNumber:lines.begin];
        NSUInteger to = [self xvim_indexOfLineNumber:lines.end];
        filterRange = [self xvim_getOperationRangeFrom:from To:to Type:LINEWISE];
    }

    [self xvim_indentCharacterRange:filterRange];
    [self xvim_moveCursor:insertionAfterFilter preserveColumn:NO];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_indentCharacterRange:(NSRange)range
{
    _auto currentSelection = self.selectedRange;
    self.selectedRange = range;
    [self indentSelection:self];
    self.selectedRange = NSIntersectionRange(currentSelection, NSMakeRange(0, self.string.length - 1));
}


#pragma mark - Increment/Decrement

- (BOOL)xvim_incrementNumber:(int64_t)offset
{
    NSUInteger ip = self.insertionPoint;
    NSRange range;

    range = [self xvim_currentNumber];
    if (range.location == NSNotFound) {
        NSUInteger pos = [self.textStorage xvim_nextDigitInLine:ip];
        if (pos == NSNotFound) {
            return NO;
        }
        self.insertionPoint = pos;
        range = [self xvim_currentNumber];
        if (range.location == NSNotFound) {
            // should not happen
            self.insertionPoint = ip;
            return NO;
        }
    }

    [self xvim_registerPositionForUndo:ip];

    const char* s = [[self.string substringWithRange:range] UTF8String];
    NSString* repl;
    uint64_t u = strtoull(s, NULL, 0);
    int64_t i = strtoll(s, NULL, 0);

    if (strncmp(s, "0x", 2) == 0) {
        repl = [NSString stringWithFormat:@"0x%0*llx", (int)strlen(s) - 2, u + (uint64_t)offset];
    }
    else if (u && *s == '0' && s[1] && !strchr(s, '9') && !strchr(s, '8')) {
        repl = [NSString stringWithFormat:@"0%0*llo", (int)strlen(s) - 1, u + (uint64_t)offset];
    }
    else if (u && *s == '+') {
        repl = [NSString stringWithFormat:@"%+lld", i + offset];
    }
    else {
        repl = [NSString stringWithFormat:@"%lld", i + offset];
    }

    [self insertText:repl replacementRange:range];
    [self xvim_moveCursor:range.location + repl.length - 1 preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
    return YES;
}


#pragma mark - SORT

- (void)xvim_sortLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2 withOptions:(XVimSortOptions)options
{
    NSAssert(line1 > 0, @"line1 must be greater than 0.");
    NSAssert(line2 > 0, @"line2 must be greater than 0.");

    if (line2 < line1)
        xvim_swap(line1, line2);

    NSRange characterRange = [self xvim_indexRangeForLines:NSMakeRange(line1, line2 - line1 + 1)];
    NSString* str = [self.string substringWithRange:characterRange];

    NSMutableArray<NSString*>* lines =
                [[str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] mutableCopy];
    if ([[lines lastObject] length] == 0) {
        [lines removeLastObject];
    }
    [lines sortUsingComparator:^NSComparisonResult(NSString* str1, NSString* str2) {
        NSStringCompareOptions compareOptions = 0;
        if (options & XVimSortOptionNumericSort) {
            compareOptions |= NSNumericSearch;
        }
        if (options & XVimSortOptionIgnoreCase) {
            compareOptions |= NSCaseInsensitiveSearch;
        }

        if (options & XVimSortOptionReversed) {
            return [str2 compare:str1 options:compareOptions];
        }
        else {
            return [str1 compare:str2 options:compareOptions];
        }
    }];

    if (options & XVimSortOptionRemoveDuplicateLines) {
        NSMutableIndexSet* removeIndices = [NSMutableIndexSet indexSet];
        // At this point the lines are already sorted
        [lines enumerateObjectsUsingBlock:^(NSString* str2, NSUInteger idx, BOOL* stop) {
            if (idx < [lines count] - 1) {
                NSString* nextStr = [lines objectAtIndex:idx + 1];
                if ([str2 isEqualToString:nextStr]) {
                    [removeIndices addIndex:idx + 1];
                }
            }
        }];
        [lines removeObjectsAtIndexes:removeIndices];
    }

    NSUInteger insertionAfterOperation = characterRange.location;
    NSString* sortedLinesString = [[lines componentsJoinedByString:@"\n"] stringByAppendingString:@"\n"];

    {
        self.xvim_lockSyncStateFromView = YES;
        xvim_on_exit {
            self.xvim_lockSyncStateFromView = NO;
        };
        
        [self insertText:sortedLinesString replacementRange:characterRange];
    }

    self.insertionPoint = insertionAfterOperation;
    [self xvim_syncStateWithScroll:YES];
}


#pragma mark - UTILITY

// @param column   head column of selected area (zero origin)
// @param count    moving count of a space
- (void)_xvim_removeSpacesAtLine:(NSUInteger)line column:(NSUInteger)column count:(NSUInteger)count
{
    NSTextStorage* ts = self.textStorage;
    const NSUInteger tabWidth = ts.xvim_tabWidth;
    NSUInteger head_pos = [self xvim_indexOfLineNumber:line column:column];
    NSString* s = self.string;

    if ([ts isEOL:head_pos]) {
        return;
    }

    NSInteger remain = (NSInteger)count;
    NSUInteger pos = head_pos;
    NSUInteger temp_width = 0;
    for (; remain > 0; ++pos) {
        const unichar c = [s characterAtIndex:pos];
        if (c == '\t') {
            remain -= tabWidth;
            // reset
            temp_width = 0;
        }
        else if (c == ' ') {
            ++temp_width;
            if (temp_width >= tabWidth) {
                remain -= tabWidth;
                // reset
                temp_width = 0;
            }
        }
        else {
            break;
        }
    }
    [self insertText:@"" replacementRange:NSMakeRange(head_pos, pos - head_pos)];
}


- (NSRange)_xvim_getDeleteRange:(XVimMotion*)motion withRange:(XVimRange)to
{
    NSRange r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
    if (motion.type == LINEWISE && [self.textStorage isLastLine:to.end]) {
        if (r.location != 0) {
            motion.info.deleteLastLine = YES;
            r.location--;
            r.length++;
        }
    }
    return r;
}

- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type
{
    if (self.string.length == 0) {
        NSMakeRange(0, 0); // No range
    }

    if (from > to)
        xvim_swap(from, to);

    // EOF can not be included in operation range.
    if ([self.textStorage isEOF:from]) {
        return NSMakeRange(from,
                           0); // from is EOF but the length is 0 means EOF will not be included in the returned range.
    }

    // EOF should not be included.
    // If type is exclusive we do not subtract 1 because we do it later below
    if ([self.textStorage isEOF:to] && type != CHARACTERWISE_EXCLUSIVE) {
        to--; // Note that we already know that "to" is not 0 so not chekcing if its 0.
    }

    // At this point "from" and "to" is not EOF
    if (type == CHARACTERWISE_EXCLUSIVE) {
        // to will not be included.
        to--;
    }
    else if (type == CHARACTERWISE_INCLUSIVE) {
        // Nothing special
    }
    else if (type == LINEWISE) {
        to = [self xvim_endOfLine:to];
        if ([self.textStorage isEOF:to]) {
            to--;
        }
        NSUInteger head = [self.textStorage xvim_firstOfLine:from];
        if (NSNotFound != head) {
            from = head;
        }
    }

    return NSMakeRange(from, to - from + 1); // Inclusive range
}


@end
