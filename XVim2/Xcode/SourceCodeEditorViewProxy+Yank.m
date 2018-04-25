//
//  SourceCodeEditorViewProxy+Yank.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceCodeEditorViewProxy+Yank.h"
#import "SourceCodeEditorViewProxy+XVim.h"
#import "SourceCodeEditorViewProxy+Operations.h"
#import "XVimMotion.h"

@interface SourceCodeEditorViewProxy ()
@property (readwrite) NSUInteger selectionBegin;
@property (readwrite) NSUInteger insertionPoint;
@property (readwrite) NSUInteger preservedColumn;
@property (readwrite) BOOL selectionToEOL;
@property (strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (XVimSelection)_xvim_selectedBlock;
- (NSRange)_xvim_selectedRange;
- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
- (void)xvim_registerInsertionPointForUndo;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
- (void)_xvim_insertSpaces:(NSUInteger)count replacementRange:(NSRange)replacementRange;
@end

@implementation SourceCodeEditorViewProxy (Yank)

- (NSRange)_xvim_getYankRange:(XVimMotion*)motion withRange:(XVimRange)to
{
    NSRange r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
    BOOL eof = [self.textStorage isEOF:to.end];
    BOOL blank = [self.textStorage isBlankline:to.end];
    if (motion.type == LINEWISE && blank && eof) {
        if (r.location != 0) {
            r.location--;
            r.length++;
        }
    }
    return r;
}

- (void)xvim_yank:(XVimMotion*)motion { [self xvim_yank:motion withMotionPoint:self.insertionPoint]; }

- (void)xvim_yank:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint
{
    NSAssert(!(self.selectionMode == XVIM_VISUAL_NONE && motion == nil),
             @"motion must be specified if current selection mode is not visual");
    NSUInteger newPos = NSNotFound;

    if (self.selectionMode == XVIM_VISUAL_NONE) {
        XVimRange to = [self xvim_getMotionRange:motionPoint Motion:motion];
        if (NSNotFound == to.end) {
            return;
        }
        // We have to treat some special cases (same as delete)
        if (motion.motion == MOTION_FORWARD && motion.info.reachedEndOfLine) {
            motion.type = CHARACTERWISE_INCLUSIVE;
        }
        if (motion.motion == MOTION_WORD_FORWARD) {
            if ((motion.info.isFirstWordInLine && motion.info.lastEndOfLine != NSNotFound)) {
                // Special cases for word move over a line break.
                to.end = motion.info.lastEndOfLine;
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
        NSRange r = [self _xvim_getYankRange:motion withRange:to];
        [self _xvim_yankRange:r withType:motion.type];
    }
    else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        NSRange range = [self _xvim_selectedRange];

        newPos = range.location;
        [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
    }
    else {
        XVimSelection sel = [self _xvim_selectedBlock];

        newPos = [self xvim_indexOfLineNumber:sel.top column:sel.left];
        [self _xvim_yankSelection:sel];
    }

    [self.xvimDelegate textView:self didYank:self.lastYankedText withType:self.lastYankedType];
    if (newPos != NSNotFound) {
        [self xvim_moveCursor:newPos preserveColumn:NO];
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count
{
    [self xvim_beginEditTransaction];
    xvim_on_exit { [self xvim_endEditTransaction]; };

    TRACE_LOG(@"text:%@  type:%d   afterCursor:%d   count:%d", text, type, after, count);
    if (self.selectionMode != XVIM_VISUAL_NONE) {
        // FIXME: Make them not to change text from register...
        text = [NSString stringWithString:text]; // copy string because the text may be changed with folloing delete if
                                                 // it is from the same register...
        [self xvim_delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_INCLUSIVE, MOPT_NONE, 1) andYank:YES];
        after = NO;
    }

    NSUInteger insertionPointAfterPut = self.insertionPoint;
    NSUInteger targetPos = self.insertionPoint;
    if (type == TEXT_TYPE_CHARACTERS) {
        // Forward insertion point +1 if after flag if on
        if (0 != text.length) {
            if (![self.textStorage isNewline:self.insertionPoint] && after) {
                targetPos++;
            }
            insertionPointAfterPut = targetPos;
            for (NSUInteger i = 0; i < count; i++) {
                [self insertText:text replacementRange:NSMakeRange(targetPos, 0)];
            }
            insertionPointAfterPut += text.length * count - 1;
        }
    }
    else if (type == TEXT_TYPE_LINES) {
        if (after) {
            [self xvim_insertNewlineBelowCurrentLine];
            targetPos = self.insertionPoint;
        }
        else {
            targetPos = [self.textStorage xvim_startOfLine:self.insertionPoint];
        }
        insertionPointAfterPut = targetPos;
        for (NSUInteger i = 0; i < count; i++) {
            if (after && i == 0) {
                // delete newline at the end. (TEXT_TYPE_LINES always have newline at the end of the text)
                NSString* t = [text substringToIndex:text.length - 1];
                [self insertText:t replacementRange:NSMakeRange(targetPos, 0)];
            }
            else {
                [self insertText:text replacementRange:NSMakeRange(targetPos, 0)];
            }
        }
    }
    else if (type == TEXT_TYPE_BLOCK) {
        // Forward insertion point +1 if after flag if on
        if (![self.textStorage isNewline:self.insertionPoint] && ![self.textStorage isEOF:self.insertionPoint]
            && after) {
            self.insertionPoint++;
        }
        insertionPointAfterPut = self.insertionPoint;
        NSUInteger insertPos = self.insertionPoint;
        NSUInteger column = [self.textStorage xvim_columnOfIndex:insertPos];
        NSUInteger startLine = [self.textStorage xvim_lineNumberAtIndex:insertPos];
        NSArray* lines = [text componentsSeparatedByString:@"\n"];
        for (NSUInteger i = 0; i < lines.count; i++) {
            NSString* line = [lines objectAtIndex:i];
            NSUInteger targetLine = startLine + i;
            NSUInteger head = [self xvim_indexOfLineNumber:targetLine];
            if (NSNotFound == head) {
                NSAssert(targetLine != 0, @"This should not be happen");
                [self xvim_insertNewlineBelowLine:targetLine - 1];
                head = [self xvim_indexOfLineNumber:targetLine];
            }
            NSAssert(NSNotFound != head, @"Head of the target line must be found at this point");

            // Find next insertion point
            NSUInteger max = [self.textStorage xvim_numberOfColumnsInLineAtIndex:head];
            NSAssert(max != NSNotFound, @"Should not be NSNotFound");
            if (column > max) {
                // If the line does not have enough column pad it with spaces
                NSUInteger end = [self xvim_endOfLine:head];

                [self _xvim_insertSpaces:column - max replacementRange:NSMakeRange(end, 0)];
            }
            for (NSUInteger j = 0; j < count; j++) {
                [self xvim_insertText:line line:targetLine column:column];
            }
        }
    }


    [self xvim_moveCursor:insertionPointAfterPut preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)__xvim_startYankWithType:(MOTION_TYPE)type
{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        if (type == CHARACTERWISE_EXCLUSIVE || type == CHARACTERWISE_INCLUSIVE) {
            self.lastYankedType = TEXT_TYPE_CHARACTERS;
        }
        else if (type == LINEWISE) {
            self.lastYankedType = TEXT_TYPE_LINES;
        }
    }
    else if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        self.lastYankedType = TEXT_TYPE_CHARACTERS;
    }
    else if (self.selectionMode == XVIM_VISUAL_LINE) {
        self.lastYankedType = TEXT_TYPE_LINES;
    }
    else if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        self.lastYankedType = TEXT_TYPE_BLOCK;
    }
    TRACE_LOG(@"YANKED START WITH TYPE:%d", self.lastYankedType);
}

- (void)_xvim_yankRange:(NSRange)range withType:(MOTION_TYPE)type
{
    NSString* s;
    BOOL needsNL;

    [self __xvim_startYankWithType:type];

    needsNL = self.lastYankedType == TEXT_TYPE_LINES;
    if (range.length) {
        s = [self.string substringWithRange:range];
        if (needsNL && !isNewline([s characterAtIndex:s.length - 1])) {
            s = [s stringByAppendingString:@"\n"];
        }
    }
    else if (needsNL) {
        s = @"\n";
    }
    else {
        s = @"";
    }

    self.lastYankedText = s;
    TRACE_LOG(@"YANKED STRING : %@", s);
}

- (void)_xvim_yankSelection:(XVimSelection)sel
{
    NSTextStorage* ts = self.textStorage;
    NSString* s = self.string;
    NSUInteger tabWidth = ts.xvim_tabWidth;

    NSMutableString* ybuf = [[NSMutableString alloc] init];
    self.lastYankedType = TEXT_TYPE_BLOCK;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        NSUInteger lpos = [self xvim_indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [self xvim_indexOfLineNumber:line column:sel.right];

        /* if lpos points in the middle of a tab, split it and advance lpos */
        if (![ts isEOF:lpos] && [s characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = sel.left - (sel.left % tabWidth);

            if (lcol < sel.left) {
                TRACE_LOG("lcol %ld  left %ld tab %ld", (long)lcol, (long)sel.left, (long)tabWidth);
                NSUInteger count = tabWidth - (sel.left - lcol);

                if (lpos == rpos) {
                    /* if rpos points to the same tab, truncate it to the right also */
                    count = sel.right - sel.left + 1;
                }
                [ybuf appendString:[NSString stringMadeOfSpaces:count]];
                lpos++;
            }
        }

        if (lpos <= rpos) {
            if (sel.right == XVimSelectionEOL) {
                [ybuf appendString:[s substringWithRange:NSMakeRange(lpos, rpos - lpos)]];
            }
            else {
                NSRange r = NSMakeRange(lpos, rpos - lpos + 1);
                NSUInteger rcol = 0;
                BOOL mustPad = NO;

                if ([ts isEOF:rpos]) {
                    rcol = [ts xvim_columnOfIndex:rpos];
                    mustPad = YES;
                    r.length--;
                }
                else {
                    unichar c = [s characterAtIndex:rpos];
                    if (isNewline(c)) {
                        rcol = [ts xvim_columnOfIndex:rpos];
                        mustPad = YES;
                        r.length--;
                    }
                    else if (c == '\t') {
                        rcol = [ts xvim_columnOfIndex:rpos];
                        if (sel.right - rcol + 1 < tabWidth) {
                            mustPad = YES;
                            r.length--;
                        }
                    }
                }

                if (r.length) {
                    [ybuf appendString:[s substringWithRange:r]];
                }

                if (mustPad) {
                    [ybuf appendString:[NSString stringMadeOfSpaces:sel.right - rcol + 1]];
                }
            }
        }
        [ybuf appendString:@"\n"];
    }

    self.lastYankedText = ybuf;
    TRACE_LOG(@"YANKED STRING : %@", ybuf);
}

- (void)_xvim_killSelection:(XVimSelection)sel
{
    NSString* s = self.string;
    NSUInteger tabWidth = self.textStorage.xvim_tabWidth;

    for (NSUInteger line = sel.bottom; line >= sel.top; line--) {
        NSTextStorage* ts = self.textStorage;
        NSUInteger lpos = [self xvim_indexOfLineNumber:line column:sel.left];
        NSUInteger rpos = [self xvim_indexOfLineNumber:line column:sel.right];
        NSUInteger nspaces = 0;

        if ([ts isEOF:lpos]) {
            continue;
        }

        if ([s characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = [ts xvim_columnOfIndex:lpos];

            if (lcol < sel.left) {
                nspaces = sel.left - lcol;
                if (lpos == rpos) {
                    nspaces = tabWidth - (sel.right - sel.left + 1);
                }
            }
        }

        if ([ts isEOL:rpos]) {
            rpos--;
        }
        else if (lpos < rpos) {
            if ([s characterAtIndex:rpos] == '\t') {
                nspaces += tabWidth - (sel.right - [ts xvim_columnOfIndex:rpos] + 1);
            }
        }

        NSRange range = NSMakeRange(lpos, rpos - lpos + 1);
        NSString* repl = @"";

        if (nspaces) {
            repl = [NSString stringWithFormat:@"%*s", (int)nspaces, ""];
        }
        [self insertText:repl replacementRange:range];
    }
}


@end
