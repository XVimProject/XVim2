//
//  SourceViewProtocol.h
//  XVim2
//
//  Created by Ant on 30/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef SourceViewProtocol_h
#define SourceViewProtocol_h
#import <AppKit/AppKit.h>

@class XVimMotion;

@protocol XVimTextViewDelegateProtocol
- (void)textView:(id)view didYank:(NSString*)yankedText withType:(TEXT_TYPE)type;
- (void)textView:(id)view didDelete:(NSString*)deletedText withType:(TEXT_TYPE)type;
@end

@protocol SourceViewProtocol <NSObject, NSTextInputClient>
- (void) keyDown:(NSEvent*)event;
- (void)interpretKeyEvents:(NSArray<NSEvent *> *)eventArray;
- (void) insertText:(id)insertString;
- (id) performSelector:(SEL)aSelector withObject:(id)object;
- (void) scrollPageForward:(NSUInteger)numPages;
- (void) scrollPageBackward:(NSUInteger)numPages;

// Properties
@property (readonly) NSRange selectedRange;
@property (readonly) NSString *string;
@property (readonly) XVIM_VISUAL_MODE selectionMode;
@property (readonly) NSUndoManager *undoManager;
@property (strong) id<XVimTextViewDelegateProtocol> xvimDelegate;
@property CURSOR_MODE cursorMode;
@property (readonly) NSUInteger insertionPoint;

@end

@protocol SourceViewXVimProtocol <NSObject>
- (void)xvim_syncState;
- (void)xvim_syncStateFromView;
- (void)xvim_insert:(XVimInsertionPoint)mode blockColumn:(NSUInteger*)column blockLines:(XVimRange*)lines;
- (void)xvim_blockInsertFixupWithText:(NSString*)text mode:(XVimInsertionPoint)mode
                                count:(NSUInteger)count
                               column:(NSUInteger)column
                                lines:(XVimRange)lines;
- (void)xvim_escapeFromInsert;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_move:(XVimMotion*)motion;
-(NSUInteger) numberOfSelectedLines;
@end


@protocol SourceViewScrollingProtocol <NSObject>
// Scrolling
- (void)xvim_scroll:(CGFloat)ratio count:(NSUInteger)count;
- (void)xvim_pageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_pageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_halfPageForward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_halfPageBackward:(NSUInteger)index count:(NSUInteger)count;
- (void)xvim_scrollPageForward:(NSUInteger)count;
- (void)xvim_scrollPageBackward:(NSUInteger)count;
- (void)xvim_scrollHalfPageForward:(NSUInteger)count;
- (void)xvim_scrollHalfPageBackward:(NSUInteger)count;
- (void)xvim_scrollLineForward:(NSUInteger)count;
- (void)xvim_scrollLineBackward:(NSUInteger)count;
- (void)xvim_scrollTo:(NSUInteger)insertionPoint;
@end

@protocol SourceViewOperationsProtocol <NSObject>
- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank;
- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank;
- (void)xvim_insertText:(NSString*)str line:(NSUInteger)line column:(NSUInteger)column;
- (void)xvim_insertNewlineBelowLine:(NSUInteger)line;
- (void)xvim_insertNewlineBelowCurrentLine;
- (void)xvim_insertNewlineBelowCurrentLineWithIndent;
- (void)xvim_insertNewlineAboveLine:(NSUInteger)line;
- (void)xvim_insertNewlineAboveCurrentLine;
- (void)xvim_insertNewlineAboveCurrentLineWithIndent;
- (void)xvim_insertNewlineAboveAndInsertWithIndent;
- (void)xvim_insertNewlineBelowAndInsertWithIndent;
- (BOOL)xvim_replaceCharacters:(unichar)c count:(NSUInteger)count;
@end

@protocol SourceViewYankProtocol <NSObject>
- (void)xvim_yank:(XVimMotion*)motion;
- (void)xvim_yank:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint;
- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count;
@end

#endif /* SourceViewProtocol_h */
