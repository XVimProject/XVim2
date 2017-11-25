//
//  SourceCodeEditorViewProxy+Scrolling.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "NSTextStorage+VimOperation.h"
#import "SourceCodeEditorViewProxy+Scrolling.h"

@interface SourceCodeEditorViewProxy ()
@property (readwrite) NSUInteger selectionBegin;
@property (readwrite) NSUInteger insertionPoint;
@property (readwrite) NSUInteger preservedColumn;
@property (readwrite) BOOL selectionToEOL;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
@end

@implementation SourceCodeEditorViewProxy (Scrolling)

// This is used by scrollBottom,Top,Center as a common method
- (void)xvim_scrollCommon_moveCursorPos:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb
{
    if (lineNumber != 0) {
        NSUInteger pos = [self xvim_indexOfLineNumber:lineNumber];
        if (NSNotFound == pos) {
            pos = self.textStorage.length;
        }
        [self xvim_moveCursor:pos preserveColumn:NO];
        [self xvim_syncState];
    }
    if (fnb) {
        NSUInteger pos = [self.textStorage xvim_firstNonblankInLineAtIndex:self.insertionPoint allowEOL:YES];
        [self xvim_moveCursor:pos preserveColumn:NO];
        [self xvim_syncState];
    }
}

- (void)xvim_scroll:(XVIM_SCROLL_TYPE)type direction:(XVIM_SCROLL_DIRECTION)direction count:(NSUInteger)count
{
    NSInteger cursorLine = self.insertionLine - 1;

    // Scroll to the new location
    NSInteger numScrollLines;
    switch (type) {
        case XVIM_SCROLL_TYPE_PAGE:
            numScrollLines = (NSInteger)(self.linesPerPage) * direction * count;
            break;
        case XVIM_SCROLL_TYPE_HALF_PAGE:
            numScrollLines = (NSInteger)(self.linesPerPage * 0.5) * direction * count;
            break;
        case XVIM_SCROLL_TYPE_LINE:
            numScrollLines = direction * count;
            break;
    }

    NSPoint bottomPoint = NSMakePoint(0.0, self.contentSize.height);

    NSInteger topLine =
                [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:NSZeroPoint], 0)]
                            .location;
    clamp(topLine, 0, self.lineCount - 1);

    NSInteger bottomLine =
                [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:bottomPoint], 0)]
                            .location;
    clamp(bottomLine, 0, self.lineCount - 1);

    NSInteger scrollToLine = (numScrollLines < 0) ? (topLine + numScrollLines) : (bottomLine + numScrollLines);
    clamp(scrollToLine, 0, self.lineCount - 1);

    _auto scrollToCharRange = [self characterRangeForLineRange:NSMakeRange(scrollToLine, 1)];
    clamp(scrollToCharRange.location, 0, self.string.length);
    [self scrollRangeToVisible:scrollToCharRange];

    // Update cursor
    cursorLine += numScrollLines;
    clamp(cursorLine, 0, self.lineCount - 1);

    _auto newCharRange = [self characterRangeForLineRange:NSMakeRange(cursorLine, 1)];
    clamp(newCharRange.location, 0, self.string.length);
    _auto cursorIndexAfterScroll =
                [self.textStorage xvim_firstNonblankInLineAtIndex:newCharRange.location allowEOL:YES];

    [self xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [self xvim_syncState];
}

- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb
{ // zb / z-
#ifdef TODO
    [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
    NSScrollView* scrollView = [self enclosingScrollView];
    NSTextContainer* container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint, 0)
                                                       inTextContainer:container];
    NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
    bottom.y -= NSHeight([[scrollView contentView] bounds]);
    if (bottom.y < 0.0) {
        bottom.y = 0.0;
    }
    [[scrollView contentView] scrollToPoint:bottom];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
#endif
}

- (void)xvim_scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb
{ // zz / z.
    if (fnb) {
        _auto cursorIndexAfterScroll =
                    [self.textStorage xvim_firstNonblankInLineAtIndex:self.selectedRange.location allowEOL:YES];
        if (cursorIndexAfterScroll != self.selectedRange.location) {
            self.selectedRange = NSMakeRange(cursorIndexAfterScroll, 0);
            [self xvim_syncStateWithScroll:NO];
        }
    }
    [self centerSelectionInVisibleArea:self];
}

- (void)xvim_scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb
{ // zt / z<CR>
#ifdef TODO
    [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
    NSScrollView* scrollView = [self enclosingScrollView];
    NSTextContainer* container = [self textContainer];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint, 0)
                                                       inTextContainer:container];
    NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
    [[scrollView contentView] scrollToPoint:top];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
#endif
}

- (void)xvim_scrollTo:(NSUInteger)insertionPoint
{
    //_auto rng = [self.sourceCodeEditorView lineRangeForCharacterRange:NSMakeRange(insertionPoint, 0)];
    [self scrollRangeToVisible:NSMakeRange(insertionPoint, 0)];
}

- (void)xvim_pageForward:(NSUInteger)index count:(NSUInteger)count
{ // C-f
    [self xvim_scroll:XVIM_SCROLL_TYPE_PAGE direction:XVIM_SCROLL_DIRECTION_DOWN count:count];
}

- (void)xvim_pageBackward:(NSUInteger)index count:(NSUInteger)count
{ // C-b
    [self xvim_scroll:XVIM_SCROLL_TYPE_PAGE direction:XVIM_SCROLL_DIRECTION_UP count:count];
}

- (void)xvim_halfPageForward:(NSUInteger)index count:(NSUInteger)count
{ // C-d
    [self xvim_scroll:XVIM_SCROLL_TYPE_HALF_PAGE direction:XVIM_SCROLL_DIRECTION_DOWN count:count];
}

- (void)xvim_halfPageBackward:(NSUInteger)index count:(NSUInteger)count
{ // C-u
    [self xvim_scroll:XVIM_SCROLL_TYPE_HALF_PAGE direction:XVIM_SCROLL_DIRECTION_UP count:count];
}

- (void)xvim_lineDown:(NSUInteger)index count:(NSUInteger)count
{ // C-e
    [self xvim_scroll:XVIM_SCROLL_TYPE_LINE direction:XVIM_SCROLL_DIRECTION_DOWN count:count];
}

- (void)xvim_lineUp:(NSUInteger)index count:(NSUInteger)count
{ // C-y
    [self xvim_scroll:XVIM_SCROLL_TYPE_LINE direction:XVIM_SCROLL_DIRECTION_UP count:count];
}

- (void)xvim_scrollPageForward:(NSUInteger)count { [self xvim_pageForward:self.insertionPoint count:count]; }

- (void)xvim_scrollPageBackward:(NSUInteger)count { [self xvim_pageBackward:self.insertionPoint count:count]; }

- (void)xvim_scrollHalfPageForward:(NSUInteger)count { [self xvim_halfPageForward:self.insertionPoint count:count]; }

- (void)xvim_scrollHalfPageBackward:(NSUInteger)count { [self xvim_halfPageBackward:self.insertionPoint count:count]; }

- (void)xvim_scrollLineForward:(NSUInteger)count { [self xvim_lineDown:self.insertionPoint count:count]; }

- (void)xvim_scrollLineBackward:(NSUInteger)count { [self xvim_lineUp:self.insertionPoint count:count]; }
@end
