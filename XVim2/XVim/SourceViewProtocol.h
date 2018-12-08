//
//  SourceViewProtocol.h
//  XVim2
//
//  Created by Ant on 30/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef SourceViewProtocol_h
#define SourceViewProtocol_h
#import "XVimMotionOption.h"
#import "XVimTextStoring.h"
#import <AppKit/AppKit.h>
#import "_TtC12SourceEditor23SourceEditorUndoManager.h"

typedef NS_ENUM(char, CursorStyle) { CursorStyleVerticalBar, CursorStyleBlock, CursorStyleUnderline };

@class XVimMotion;
@class XVimCommandLine;

@protocol XVimTextViewDelegateProtocol
- (void)textView:(id)view didYank:(NSString*)yankedText withType:(TEXT_TYPE)type;
- (void)textView:(id)view didDelete:(NSString*)deletedText withType:(TEXT_TYPE)type;
@end

@protocol SourceViewProtocol <NSObject>
- (void)showCommandLine;
- (void)hideCommandLine;
- (BOOL)isShowingCommandLine;
- (void)keyDown:(NSEvent*)event;
- (void)interpretKeyEvents:(NSArray<NSEvent*>*)eventArray;
- (void)insertText:(id)insertString;
- (id)performSelector:(SEL)aSelector withObject:(id)object;
- (void)scrollPageForward:(NSUInteger)numPages;
- (void)scrollPageBackward:(NSUInteger)numPages;
- (void)showFindIndicatorForRange:(NSRange)arg1;
- (void)selectionChanged:(NSNotification*)changeNotification;
- (void)insertText:(id)string replacementRange:(NSRange)replacementRange;

// Properties
@property (nonatomic, getter=isEnabled) BOOL enabled;
@property NSRange selectedRange;
@property (readonly) NSString* string;
@property (readonly) XVIM_VISUAL_MODE selectionMode;
@property (readonly) _TtC12SourceEditor23SourceEditorUndoManager* undoManager;
@property (strong) id<XVimTextViewDelegateProtocol> xvimDelegate;
@property CURSOR_MODE cursorMode;
@property (readonly) NSUInteger insertionPoint;
@property (readonly) NSInteger currentLineNumber;
@property (readonly) NSArray<NSValue*>* selectedRanges;
@property (readonly) NSTextStorage* textStorage;
@property (readonly) XVimPosition insertionPosition;
@property (readonly) NSUInteger selectionBegin;
@property (readonly) XVimPosition selectionBeginPosition;
@property (nonatomic) BOOL needsUpdateFoundRanges;
@property (readonly) BOOL selectionToEOL;
@property (readonly) NSUInteger insertionColumn;
@property (readonly) NSUInteger insertionLine;
@property (readonly) NSURL* documentURL;
@property (readonly) XVimCommandLine* commandLine;
@property (readonly) NSWindow* window;
@property (readonly) NSView* view;
@property CursorStyle originalCursorStyle;
@property CursorStyle cursorStyle;
@end


// XVim extensions
@protocol SourceViewXVimProtocol <NSObject, XVimTextStoring>
- (void)xvim_beginUndoGrouping;
- (void)xvim_endUndoGrouping;

// WARNING! xvim_endEditTransaction MUST be called on the main thread, after
// xvim_beginEditTransaction, and during a single pass of the run-loop. So,
// always use the macro EDIT_TRANSACTION_SCOPE instead of these calls
- (void)xvim_beginEditTransaction;
- (void)xvim_endEditTransaction;

- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (void)xvim_syncStateFromView;
- (void)xvim_insert:(XVimInsertionPoint)mode blockColumn:(NSUInteger*)column blockLines:(XVimRange*)lines;
- (void)xvim_blockInsertFixupWithText:(NSString*)text
                                     mode:(XVimInsertionPoint)mode
                                    count:(NSUInteger)count
                                   column:(NSUInteger)column
                                    lines:(XVimRange)lines;
- (void)xvim_adjustCursorPosition;
- (void)xvim_escapeFromInsert;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (void)xvim_move:(XVimMotion*)motion;
- (void)xvim_moveToPosition:(XVimPosition)pos;
- (NSUInteger)numberOfSelectedLines;
- (NSArray*)xvim_selectedRanges;
- (void)xvim_setSelectedRange:(NSRange)range;
- (NSRange)xvim_currentWord:(MOTION_OPTION)opt;
- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
- (unichar)xvim_characterAtIndex:(NSInteger)idx;
- (NSUInteger)xvim_lineNumberFromBottom:(NSUInteger)count;
- (NSUInteger)xvim_lineNumberAtMiddle;
- (NSUInteger)xvim_lineNumberFromTop:(NSUInteger)count;
- (void)xvim_highlightNextSearchCandidate:(NSString*)regex
                                        count:(NSUInteger)count
                                       option:(MOTION_OPTION)opt
                                      forward:(BOOL)forward;
- (void)xvim_highlightNextSearchCandidateForward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)xvim_highlightNextSearchCandidateBackward:(NSString*)regex count:(NSUInteger)count option:(MOTION_OPTION)opt;
- (void)xvim_hideCompletions;
@end


// Scrolling
@protocol SourceViewScrollingProtocol <NSObject>
- (void)xvim_scroll:(XVIM_SCROLL_TYPE)type direction:(XVIM_SCROLL_DIRECTION)direction count:(NSUInteger)count;
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
- (void)xvim_scrollBottom:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)xvim_scrollCenter:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
- (void)xvim_scrollTop:(NSUInteger)lineNumber firstNonblank:(BOOL)fnb;
@end

// Mutate Operations
@protocol SourceViewOperationsProtocol <NSObject>
- (void)xvim_copymove:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint withInsertionPoint:(NSUInteger)insertionPoint after:(BOOL)after onlyCopy:(BOOL)onlyCopy;
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
- (void)xvim_swapCase:(XVimMotion*)motion;
- (void)xvim_swapCaseForRange:(NSRange)range;
- (void)xvim_makeLowerCase:(XVimMotion*)motion;
- (void)xvim_makeUpperCase:(XVimMotion*)motion;
- (BOOL)xvim_change:(XVimMotion*)motion;
- (void)xvim_joinAtLineNumber:(NSUInteger)line;
- (void)xvim_join:(NSUInteger)count addSpace:(BOOL)addSpace;
- (void)_xvim_shift:(XVimMotion*)motion right:(BOOL)right;
- (void)xvim_shiftRight:(XVimMotion*)motion;
- (void)xvim_shiftRight:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count;
- (void)xvim_shiftLeft:(XVimMotion*)motion;
- (void)xvim_shiftLeft:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint count:(NSUInteger)count;
- (void)xvim_filter:(XVimMotion*)motion;
- (void)xvim_indentCharacterRange:(NSRange)range;
- (BOOL)xvim_incrementNumber:(int64_t)offset;
- (void)xvim_sortLinesFrom:(NSUInteger)line1 to:(NSUInteger)line2 withOptions:(XVimSortOptions)options;
@end

// Yank + Put
@protocol SourceViewYankProtocol <NSObject>
- (void)xvim_yank:(XVimMotion*)motion;
- (void)xvim_yank:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint;
- (void)xvim_put:(NSString*)text withType:(TEXT_TYPE)type afterCursor:(bool)after count:(NSUInteger)count;
@end


#endif /* SourceViewProtocol_h */
