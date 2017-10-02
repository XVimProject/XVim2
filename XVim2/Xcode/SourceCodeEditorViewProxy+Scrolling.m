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
@property(readonly) NSTextStorage *textStorage;
@property NSRange selectedRange;
@property BOOL xvim_lockSyncStateFromView;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_syncState;
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
        _auto origLineRange = [self.sourceCodeEditorView lineRangeForCharacterRange: self.sourceCodeEditorView.selectedRange];
        _auto linesPerPage = self.sourceCodeEditorView.linesPerPage;
        _auto numScrollLines = (NSInteger)( linesPerPage * ratio);
        
        if (numScrollLines < 0) {
                clamp(numScrollLines, -(int)origLineRange.location, numScrollLines);
                for (NSInteger i = numScrollLines; i !=0; ++i) {
                        [self.sourceCodeEditorView scrollLineUp:self];
                }
        }
        else {
                clamp(numScrollLines, 0, self.sourceCodeEditorView.lineCount - (NSInteger)origLineRange.location);
                for (NSInteger i = 0; i != numScrollLines; ++i) {
                        [self.sourceCodeEditorView scrollLineDown:self];
                }
        }
        origLineRange.location += numScrollLines;
        clamp(origLineRange.location, 0, self.sourceCodeEditorView.lineCount-1);
        _auto newCharRange = [self.sourceCodeEditorView characterRangeForLineRange:origLineRange];
        clamp(newCharRange.location, 0, self.string.length);
        
        _auto cursorIndexAfterScroll = [self.textStorage xvim_firstNonblankInLineAtIndex:newCharRange.location allowEOL:YES];
        _auto maxIdx = self.string.length;
        clamp(cursorIndexAfterScroll, 0, maxIdx);
        [self xvim_moveCursor:cursorIndexAfterScroll preserveColumn:NO];
        [self xvim_syncState];
        
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
        [self.sourceCodeEditorView scrollRangeToVisible:NSMakeRange(insertionPoint, 0)];
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
