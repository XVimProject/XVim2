//
//  SourceCodeEditorViewProxy+Scrolling.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "NSTextStorage+VimOperation.h"
#import "SourceViewProtocol.h"
#import "SourceCodeEditorViewProxy+Scrolling.h"
#import "SourceCodeEditorViewProxy+XVim.h"
#import "SourceCodeEditorViewProxy+Yank.h"

@interface SourceCodeEditorViewProxy ()
@property (readwrite) NSUInteger selectionBegin;
@property (readwrite) NSUInteger insertionPoint;
@property (readwrite) NSUInteger preservedColumn;
@property (readwrite) BOOL selectionToEOL;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
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
        [self xvim_syncStateWithScroll:YES];
    }
    if (fnb) {
        NSUInteger pos = [self.textStorage xvim_firstNonblankInLineAtIndex:self.insertionPoint allowEOL:YES];
        [self xvim_moveCursor:pos preserveColumn:NO];
        [self xvim_syncStateWithScroll:YES];
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

    LineRange visibleLineRange = [self xvim_visibleLineRange];

    NSInteger scrollToLine = (numScrollLines < 0) ? (visibleLineRange.topLine + numScrollLines) : (visibleLineRange.bottomLine + numScrollLines);
    clamp(scrollToLine, 0, self.lineCount - 1);

    _auto scrollToCharRange = [self characterRangeForLineRange:NSMakeRange(scrollToLine, 1)];
    clamp(scrollToCharRange.location, 0, self.string.length);
    [self scrollRangeToVisible:scrollToCharRange];

    // Update cursor
    switch (type) {
      case XVIM_SCROLL_TYPE_LINE: {
        NSInteger numLinesActuallyScrolled;
        if (numScrollLines < 0) {
          numLinesActuallyScrolled = -MIN(visibleLineRange.topLine+1, -numScrollLines);
        } else {
          numLinesActuallyScrolled = MIN(self.lineCount - visibleLineRange.bottomLine, numScrollLines);
        }
        clamp(cursorLine,
              visibleLineRange.topLine + numLinesActuallyScrolled,
              visibleLineRange.bottomLine + numLinesActuallyScrolled);
        break;
      }
      default:
        cursorLine += numScrollLines;
        break;
    }
    clamp(cursorLine, 0, self.lineCount - 1);

    _auto newCharRange = [self characterRangeForLineRange:NSMakeRange(cursorLine, 1)];
    clamp(newCharRange.location, 0, self.string.length);
    _auto cursorIndexAfterScroll =
                [self.textStorage xvim_firstNonblankInLineAtIndex:newCharRange.location allowEOL:YES];

    [self xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
    [self xvim_syncStateWithScroll:YES];
}

typedef struct {
    NSInteger topLine;
    NSInteger bottomLine;
} LineRange;

// zero index
- (LineRange)xvim_visibleLineRange
{
    NSPoint bottomPoint = NSMakePoint(0.0, self.contentSize.height);
    
    NSInteger topLine =
    [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:NSZeroPoint], 0)]
    .location;
    clamp(topLine, 0, self.lineCount - 1);
    
    NSInteger bottomLine =
    [self lineRangeForCharacterRange:NSMakeRange([self characterIndexForInsertionAtPoint:bottomPoint], 0)]
    .location;
    clamp(bottomLine, 0, self.lineCount - 1);
    
    LineRange r;
    r.topLine = topLine;
    r.bottomLine = bottomLine;
    return r;
}

- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb
{ // zb / z-
    
    [self xvim_scrollCenter:lineNumber firstNonblank:fnb];
    
    NSInteger linesPerPage = [self linesPerPage];
    for (int i = 0; i < linesPerPage/2; ++i){
        [self scrollLineUp:self];
    }
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
    
    // first, scroll for cursor visible
    [self xvim_scrollCenter:lineNumber firstNonblank:fnb];

    NSInteger linesPerPage = [self linesPerPage];
    for (int i = 0; i < linesPerPage/2; ++i){
        [self scrollLineDown:self];
    }
}

- (void)xvim_scrollTo:(NSUInteger)insertionPoint
{
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
