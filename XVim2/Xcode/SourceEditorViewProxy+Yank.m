//
//  SourceCodeEditorViewProxy+Yank.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceEditorViewProxy+Yank.h"
#import "SourceEditorViewProxy+XVim.h"
#import "SourceEditorViewProxy+Operations.h"
#import "XVimMotion.h"

@interface SourceEditorViewProxy ()
@property NSUInteger selectionBegin;
@property NSUInteger insertionPoint;
@property NSUInteger preservedColumn;
@property BOOL selectionToEOL;
@property NSString* lastYankedText;
@property XVimTextType lastYankedType;
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

@implementation SourceEditorViewProxy (Yank)

- (NSRange)_xvim_getYankRange:(XVimMotion*)motion withRange:(XVimRange)to
{
    var r = [self xvim_getOperationRangeFrom:to.begin To:to.end Type:motion.type];
    let eof = [self.textStorage isEOF:to.end];
    let blank = [self.textStorage isBlankline:to.end];
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
        var to = [self xvim_getMotionRange:motionPoint Motion:motion];
        if (NSNotFound == to.end) {
            return;
        }
        // We have to treat some special cases (same as delete)
        if (motion.motion == MOTION_FORWARD && motion.motionInfo.reachedEndOfLine) {
            motion.type = CHARWISE_INCLUSIVE;
        }
        if (motion.motion == MOTION_WORD_FORWARD) {
            if ((motion.motionInfo.isFirstWordInLine && motion.motionInfo.lastEndOfLine != NSNotFound)) {
                // Special cases for word move over a line break.
                to.end = motion.motionInfo.lastEndOfLine;
                motion.type = CHARWISE_INCLUSIVE;
            }
            else if (motion.motionInfo.reachedEndOfLine) {
                if (motion.type == CHARWISE_EXCLUSIVE) {
                    motion.type = CHARWISE_INCLUSIVE;
                }
                else if (motion.type == CHARWISE_INCLUSIVE) {
                    motion.type = CHARWISE_EXCLUSIVE;
                }
            }
        }
        let r = [self _xvim_getYankRange:motion withRange:to];
        [self _xvim_yankRange:r withType:motion.type];
    }
    else if (self.selectionMode != XVIM_VISUAL_BLOCK) {
        let range = [self _xvim_selectedRange];

        newPos = range.location;
        [self _xvim_yankRange:range withType:DEFAULT_MOTION_TYPE];
    }
    else {
        let sel = [self _xvim_selectedBlock];

        newPos = [self xvim_indexOfLineNumber:sel.top column:sel.left];
        [self _xvim_yankSelection:sel];
    }

    [self.xvimTextViewDelegate textView:self didYank:self.lastYankedText type:self.lastYankedType];
    if (newPos != NSNotFound) {
        [self xvim_moveCursor:newPos preserveColumn:NO];
    }
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)xvim_put:(NSString*)text textType:(XVimTextType)textType afterCursor:(BOOL)after count:(NSUInteger)count
{
    [self xvim_beginEditTransaction];
    xvim_on_exit { [self xvim_endEditTransaction]; };

    if (self.selectionMode != XVIM_VISUAL_NONE) {
        // FIXME: Make them not to change text from register...
        text = [NSString stringWithString:text]; // copy string because the text may be changed with folloing delete if
                                                 // it is from the same register...
        [self xvim_delete:XVIM_MAKE_MOTION(MOTION_NONE, CHARWISE_INCLUSIVE, MOPT_NONE, 1) andYank:YES];
        after = NO;
    }

    var insertionPointAfterPut = self.insertionPoint;
    var targetPos = self.insertionPoint;
	switch (textType){
		case XVimTextTypeCharacters:
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
    		break;
		case XVimTextTypeLines:
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
			break;
		case XVimTextTypeBlock:
            // Forward insertion point +1 if after flag if on
            if (![self.textStorage isNewline:self.insertionPoint] && ![self.textStorage isEOF:self.insertionPoint]
                && after) {
                self.insertionPoint++;
            }
            insertionPointAfterPut = self.insertionPoint;
            let insertPos = self.insertionPoint;
            let column = [self.textStorage xvim_columnOfIndex:insertPos];
            let startLine = [self.textStorage xvim_lineNumberAtIndex:insertPos];
            NSArray<NSString*>* lines = [text componentsSeparatedByString:@"\n"];
            for (NSUInteger i = 0; i < lines.count; i++) {
                NSString* line = [lines objectAtIndex:i];
                NSUInteger targetLine = startLine + i;
                var head = [self xvim_indexOfLineNumber:targetLine];
                if (NSNotFound == head) {
                    NSAssert(targetLine != 0, @"This should not be happen");
                    [self xvim_insertNewlineBelowLine:targetLine - 1];
                    head = [self xvim_indexOfLineNumber:targetLine];
                }
                NSAssert(NSNotFound != head, @"Head of the target line must be found at this point");

                // Find next insertion point
                let max = [self.textStorage xvim_numberOfColumnsInLineAtIndex:head];
                NSAssert(max != NSNotFound, @"Should not be NSNotFound");
                if (column > max) {
                    // If the line does not have enough column pad it with spaces
                    let end = [self xvim_endOfLine:head];

                    [self _xvim_insertSpaces:column - max replacementRange:NSMakeRange(end, 0)];
                }
                for (NSUInteger j = 0; j < count; j++) {
                    [self xvim_insertText:line line:targetLine column:column];
                }
            }
    		break;
    }

    [self xvim_moveCursor:insertionPointAfterPut preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
    [self xvim_changeSelectionMode:XVIM_VISUAL_NONE];
}


- (void)__xvim_startYankWithType:(MOTION_TYPE)type
{
    if (self.selectionMode == XVIM_VISUAL_NONE) {
        if (type == CHARWISE_EXCLUSIVE || type == CHARWISE_INCLUSIVE) {
            self.lastYankedType = XVimTextTypeCharacters;
        }
        else if (type == LINEWISE) {
            self.lastYankedType = XVimTextTypeLines;
        }
    }
    else if (self.selectionMode == XVIM_VISUAL_CHARACTER) {
        self.lastYankedType = XVimTextTypeCharacters;
    }
    else if (self.selectionMode == XVIM_VISUAL_LINE) {
        self.lastYankedType = XVimTextTypeLines;
    }
    else if (self.selectionMode == XVIM_VISUAL_BLOCK) {
        self.lastYankedType = XVimTextTypeBlock;
    }
}

- (void)_xvim_yankRange:(NSRange)range withType:(MOTION_TYPE)type
{
    [self __xvim_startYankWithType:type];

    BOOL needsNL = self.lastYankedType == XVimTextTypeLines;
    NSString* s;
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
}

- (void)_xvim_yankSelection:(XVimSelection)sel
{
    let ts = self.textStorage;
    let s = self.string;
    let tabWidth = ts.xvim_tabWidth;

    var ybuf = [[NSMutableString alloc] init];
    self.lastYankedType = XVimTextTypeBlock;

    for (NSUInteger line = sel.top; line <= sel.bottom; line++) {
        var lpos = [self xvim_indexOfLineNumber:line column:sel.left];
        var rpos = [self xvim_indexOfLineNumber:line column:sel.right];

        /* if lpos points in the middle of a tab, split it and advance lpos */
        if (![ts isEOF:lpos] && [s characterAtIndex:lpos] == '\t') {
            NSUInteger lcol = sel.left - (sel.left % tabWidth);

            if (lcol < sel.left) {
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
                var r = NSMakeRange(lpos, rpos - lpos + 1);
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
}

- (void)_xvim_killSelection:(XVimSelection)sel
{
    NSString* s = self.string;
    NSUInteger tabWidth = self.textStorage.xvim_tabWidth;

    for (NSUInteger line = sel.bottom; line >= sel.top; line--) {
        var ts = self.textStorage;
        var lpos = [self xvim_indexOfLineNumber:line column:sel.left];
        var rpos = [self xvim_indexOfLineNumber:line column:sel.right];
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

        var range = NSMakeRange(lpos, rpos - lpos + 1);
        // Workaround Fix: Visual block mode plus d or x equals extra characters deleted https://github.com/XVimProject/XVim2/issues/216
        // This seem a bug in sourceEditorView -insertText:replacementRange:;
        // After first call (the sel.bottom line) of -insertText:replacementRange:,
        // sourceEditorView always delete range.length*2 characters;
        // Or need to reset some statuses inside sourceEditorView?
        if (line != sel.bottom) {
            range.length = 0;
        }
        NSString* repl = @"";

        if (nspaces) {
            repl = [NSString stringWithFormat:@"%*s", (int)nspaces, ""];
        }
        [self insertText:repl replacementRange:range];
    }
}


@end
