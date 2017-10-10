//
//  SourceCodeEditorViewProxy+Scrolling.m
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceCodeEditorViewProxy+Scrolling.h"
#import "NSTextStorage+VimOperation.h"

@interface SourceCodeEditorViewProxy()
@property(readwrite) NSUInteger selectionBegin;
@property(readwrite) NSUInteger insertionPoint;
@property(readwrite) NSUInteger preservedColumn;
@property(readwrite) BOOL selectionToEOL;
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
@end

@implementation SourceCodeEditorViewProxy(Scrolling)

// This is used by scrollBottom,Top,Center as a common method
- (void)xvim_scrollCommon_moveCursorPos:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{
        if( lineNumber != 0 ){
                NSUInteger pos = [self.textStorage xvim_indexOfLineNumber:lineNumber];
                if( NSNotFound == pos ){
                        pos = self.textStorage.length;
                }
                [self xvim_moveCursor:pos preserveColumn:NO];
                [self xvim_syncState];
        }
        if( fnb ){
                NSUInteger pos = [self.textStorage xvim_firstNonblankInLineAtIndex:self.insertionPoint allowEOL:YES];
                [self xvim_moveCursor:pos preserveColumn:NO];
                [self xvim_syncState];
        }
}


- (void)xvim_scroll:(CGFloat)ratio count:(NSUInteger)count {
        NSInteger cursorLine = self.currentLineNumber - 1;
        
        // Scroll to the new location
        NSInteger numScrollLines = (NSInteger)(self.linesPerPage * ratio);
        
        NSPoint bottomPoint = NSMakePoint(0.0, self.contentSize.height);
        
        NSInteger topLine =
                [self lineRangeForCharacterRange:
                         NSMakeRange([self characterIndexForInsertionAtPoint:NSZeroPoint], 0)].location;
        clamp(topLine, 0, self.lineCount-1);
        
        NSInteger bottomLine =
                [self lineRangeForCharacterRange:
                         NSMakeRange([self characterIndexForInsertionAtPoint:bottomPoint], 0)].location;
        clamp(bottomLine, 0, self.lineCount-1);

        NSInteger scrollToLine = (numScrollLines < 0)
                ? (topLine + numScrollLines)
                : (bottomLine + numScrollLines);
        clamp(scrollToLine, 0, self.lineCount-1);

        _auto scrollToCharRange = [self characterRangeForLineRange:NSMakeRange(scrollToLine, 1)];
        clamp(scrollToCharRange.location, 0, self.string.length);
        [self scrollRangeToVisible:scrollToCharRange];

        // Update cursor
        cursorLine += numScrollLines;
        clamp(cursorLine, 0, self.lineCount-1);
        
        _auto newCharRange = [self characterRangeForLineRange:NSMakeRange(cursorLine, 1)];
        clamp(newCharRange.location, 0, self.string.length);
        _auto cursorIndexAfterScroll = [self.textStorage xvim_firstNonblankInLineAtIndex:newCharRange.location allowEOL:YES];
        
        [self xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
        [self xvim_syncStateWithScroll:NO];

}

- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zb / z-
#ifdef TODO
        [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
        NSScrollView *scrollView = [self enclosingScrollView];
        NSTextContainer *container = [self textContainer];
        NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
        NSPoint bottom = NSMakePoint(0.0f, NSMidY(glyphRect) + NSHeight(glyphRect) / 2.0f);
        bottom.y -= NSHeight([[scrollView contentView] bounds]);
        if( bottom.y < 0.0 ){
                bottom.y = 0.0;
        }
        [[scrollView contentView] scrollToPoint:bottom];
        [scrollView reflectScrolledClipView:[scrollView contentView]];
#endif

}

- (void)xvim_scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zz / z.
#ifdef TODO
        [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
        NSScrollView *scrollView = [self enclosingScrollView];
        NSTextContainer *container = [self textContainer];
        NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
        NSPoint center = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
        center.y -= NSHeight([[scrollView contentView] bounds]) / 2.0f;
        if( center.y < 0.0 ){
                center.y = 0.0;
        }
        [[scrollView contentView] scrollToPoint:center];
        [scrollView reflectScrolledClipView:[scrollView contentView]];
#endif

}

- (void)xvim_scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb{ // zt / z<CR>
#ifdef TODO
        [self xvim_scrollCommon_moveCursorPos:lineNumber firstNonblank:fnb];
        NSScrollView *scrollView = [self enclosingScrollView];
        NSTextContainer *container = [self textContainer];
        NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(self.insertionPoint,0) inTextContainer:container];
        NSPoint top = NSMakePoint(0.0f, NSMidY(glyphRect) - NSHeight(glyphRect) / 2.0f);
        [[scrollView contentView] scrollToPoint:top];
        [scrollView reflectScrolledClipView:[scrollView contentView]];
#endif
}

-(void)xvim_scrollTo:(NSUInteger)insertionPoint
{
        //_auto rng = [self.sourceCodeEditorView lineRangeForCharacterRange:NSMakeRange(insertionPoint, 0)];
        [self scrollRangeToVisible:NSMakeRange(insertionPoint, 0)];
}

- (void)xvim_pageForward:(NSUInteger)index count:(NSUInteger)count { // C-f
        [self xvim_scroll:1.0 count:count];
}

- (void)xvim_pageBackward:(NSUInteger)index count:(NSUInteger)count { // C-b
        [self xvim_scroll:-1.0 count:count];
}

- (void)xvim_halfPageForward:(NSUInteger)index count:(NSUInteger)count { // C-d
        [self xvim_scroll:0.5 count:count];
}

- (void)xvim_halfPageBackward:(NSUInteger)index count:(NSUInteger)count { // C-u
        [self xvim_scroll:-0.5 count:count];
}

- (void)xvim_scrollPageForward:(NSUInteger)count{
        [self xvim_pageForward:self.insertionPoint count:count];
}

- (void)xvim_scrollPageBackward:(NSUInteger)count{
        [self xvim_pageBackward:self.insertionPoint count:count];
}

- (void)xvim_scrollHalfPageForward:(NSUInteger)count{
        [self xvim_halfPageForward:self.insertionPoint count:count];
}

- (void)xvim_scrollHalfPageBackward:(NSUInteger)count{
        [self xvim_halfPageBackward:self.insertionPoint count:count];
}

- (void)xvim_scrollLineForward:(NSUInteger)count{
#ifdef TODO
        [self xvim_lineDown:self.insertionPoint count:count];
#endif
}

- (void)xvim_scrollLineBackward:(NSUInteger)count{
#ifdef TODO
        [self xvim_lineUp:self.insertionPoint count:count];
#endif
}
@end
