//
//  SourceEditorProxy.h
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceViewProtocol.h"
#import "IDEPegasusSourceEditor/_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"

typedef NS_ENUM(NSInteger, CursorStyle) {
        CursorStyleVerticalBar
        , CursorStyleBlock
        , CursorStyleUnderline
};

// Raw values for SourceEditor.SourceEditorSelectionModifiers
typedef NS_OPTIONS(unsigned, SelectionModifiers) {
       SelectionModifierExtension = 1
        , SelectionModifierColumnar = 1 << 1
        , SelectionModifierDiscontiguous = 1 << 2
};

@class XVimCommandLine;

// SourceEditorView.selection returns a SourceEditor.SourceEditorSelection?
// SourceEditorSelection is an internal class

@protocol XVimTextViewDelegateProtocol;

@interface SourceCodeEditorViewProxy : NSObject <SourceViewProtocol>
@property CursorStyle cursorStyle;
@property(readonly) XVIM_VISUAL_MODE selectionMode;
@property(readonly) NSUInteger insertionPoint;
@property(readonly) XVimPosition insertionPosition;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger preservedColumn;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) XVimPosition selectionBeginPosition;
@property(readonly) BOOL selectionToEOL;
@property CURSOR_MODE cursorMode;
@property(readonly) NSURL* documentURL;
@property (nonatomic) BOOL needsUpdateFoundRanges;
@property(readonly) NSMutableArray* foundRanges;
@property(readonly) NSInteger currentLineNumber;
@property(strong) id<XVimTextViewDelegateProtocol> xvimDelegate;
@property(readonly) XVimCommandLine *commandLine;
@property(readonly) NSWindow *window;
-(instancetype)initWithSourceCodeEditorView:(SourceCodeEditorView*)sourceEditorView;

// Proxy methods
- (NSRange)lineRangeForCharacterRange:(NSRange)arg1;
- (NSRange)characterRangeForLineRange:(NSRange)arg1;
- (NSUInteger)characterIndexForInsertionAtPoint:(CGPoint)arg1;
- (void)mouseExited:(id)sender;
- (void)mouseEntered:(id)sender;
- (void)mouseMoved:(id)sender;
- (void)rightMouseUp:(id)sender;
- (void)mouseUp:(id)sender;
- (void)mouseDragged:(id)sender;
- (void)rightMouseDown:(id)sender;
- (void)mouseDown:(id)sender;
- (void)insertText:(id)sender;
- (void)selectWord:(id)sender;
- (void)selectLine:(id)sender;
- (void)selectParagraph:(id)sender;
- (void)selectAll:(id)sender;
- (void)scrollToEndOfDocument:(id)sender;
- (void)scrollToBeginningOfDocument:(id)sender;
- (void)scrollLineDown:(id)sender;
- (void)scrollLineUp:(id)sender;
- (void)scrollPageDown:(id)sender;
- (void)scrollPageUp:(id)sender;
- (void)centerSelectionInVisibleArea:(id)sender;
- (void)pageUpAndModifySelection:(id)sender;
- (void)pageDownAndModifySelection:(id)sender;
- (void)pageUp:(id)sender;
- (void)pageDown:(id)sender;
- (void)moveToEndOfDocumentAndModifySelection:(id)sender;
- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender;
- (void)moveToEndOfDocument:(id)sender;
- (void)moveToBeginningOfDocument:(id)sender;
- (void)moveParagraphBackwardAndModifySelection:(id)sender;
- (void)moveParagraphForwardAndModifySelection:(id)sender;
- (void)moveToEndOfParagraphAndModifySelection:(id)sender;
- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender;
- (void)moveToEndOfParagraph:(id)sender;
- (void)moveToBeginningOfParagraph:(id)sender;
- (void)moveToEndOfTextAndModifySelection:(id)sender;
- (void)moveToEndOfText:(id)sender;
- (void)moveToBeginningOfTextAndModifySelection:(id)sender;
- (void)moveToBeginningOfText:(id)sender;
- (void)moveToRightEndOfLineAndModifySelection:(id)sender;
- (void)moveToLeftEndOfLineAndModifySelection:(id)sender;
- (void)moveToRightEndOfLine:(id)sender;
- (void)moveToLeftEndOfLine:(id)sender;
- (void)moveToEndOfLineAndModifySelection:(id)sender;
- (void)moveToBeginningOfLineAndModifySelection:(id)sender;
- (void)moveToEndOfLine:(id)sender;
- (void)moveToBeginningOfLine:(id)sender;
- (void)moveExpressionBackwardAndModifySelection:(id)sender;
- (void)moveExpressionForwardAndModifySelection:(id)sender;
- (void)moveExpressionBackward:(id)sender;
- (void)moveExpressionForward:(id)sender;
- (void)moveSubWordBackwardAndModifySelection:(id)sender;
- (void)moveSubWordForwardAndModifySelection:(id)sender;
- (void)moveSubWordBackward:(id)sender;
- (void)moveSubWordForward:(id)sender;
- (void)moveWordLeftAndModifySelection:(id)sender;
- (void)moveWordRightAndModifySelection:(id)sender;
- (void)moveWordLeft:(id)sender;
- (void)moveWordRight:(id)sender;
- (void)moveWordBackwardAndModifySelection:(id)sender;
- (void)moveWordForwardAndModifySelection:(id)sender;
- (void)moveWordBackward:(id)sender;
- (void)moveWordForward:(id)sender;
- (void)moveDownAndModifySelection:(id)sender;
- (void)moveUpAndModifySelection:(id)sender;
- (void)moveDown:(id)sender;
- (void)moveUp:(id)sender;
- (void)moveLeftAndModifySelection:(id)sender;
- (void)moveRightAndModifySelection:(id)sender;
- (void)moveLeft:(id)sender;
- (void)moveRight:(id)sender;
- (void)moveBackwardAndModifySelection:(id)sender;
- (void)moveForwardAndModifySelection:(id)sender;
- (void)moveBackward:(id)sender;
- (void)moveForward:(id)sender;
- (void)unfoldAllComments:(id)sender;
- (void)foldAllComments:(id)sender;
- (void)unfoldAllMethods:(id)sender;
- (void)foldAllMethods:(id)sender;
- (void)unfoldAll:(id)sender;
- (void)unfold:(id)sender;
- (void)fold:(id)sender;
- (void)balance:(id)sender;
- (void)selectStructure:(id)sender;
- (void)shiftRight:(id)sender;
- (void)shiftLeft:(id)sender;
- (void)indentSelection:(id)sender;
- (void)moveCurrentLineDown:(id)sender;
- (void)moveCurrentLineUp:(id)sender;
- (void)complete:(id)sender;
- (void)swapWithMark:(id)sender;
- (void)selectToMark:(id)sender;
- (void)deleteToMark:(id)sender;
- (void)setMark:(id)sender;
- (void)yankAndSelect:(id)sender;
- (void)yank:(id)sender;
- (void)capitalizeWord:(id)sender;
- (void)lowercaseWord:(id)sender;
- (void)uppercaseWord:(id)sender;
- (void)transpose:(id)sender;
- (void)deleteToEndOfText:(id)sender;
- (void)deleteToBeginningOfText:(id)sender;
- (void)deleteToEndOfParagraph:(id)sender;
- (void)deleteToBeginningOfParagraph:(id)sender;
- (void)deleteToEndOfLine:(id)sender;
- (void)deleteToBeginningOfLine:(id)sender;
- (void)deleteExpressionBackward:(id)sender;
- (void)deleteExpressionForward:(id)sender;
- (void)deleteSubWordBackward:(id)sender;
- (void)deleteSubWordForward:(id)sender;
- (void)deleteWordBackward:(id)sender;
- (void)deleteWordForward:(id)sender;
- (void)deleteBackwardByDecomposingPreviousCharacter:(id)sender;
- (void)deleteBackward:(id)sender;
- (void)deleteForward:(id)sender;
- (void)delete:(id)sender;
- (void)insertDoubleQuoteIgnoringSubstitution:(id)sender;
- (void)insertSingleQuoteIgnoringSubstitution:(id)sender;
- (void)insertContainerBreak:(id)sender;
- (void)insertLineBreak:(id)sender;
- (void)insertTabIgnoringFieldEditor:(id)sender;
- (void)insertNewlineIgnoringFieldEditor:(id)sender;
- (void)insertParagraphSeparator:(id)sender;
- (void)insertNewline:(id)sender;
- (void)insertBacktab:(id)sender;
- (void)insertTab:(id)sender;
- (void)flagsChanged:(id)sender;
- (void)keyDown:(id)sender;
- (void)concludeDragOperation:(id)sender;
- (void)draggingExited:(id)sender;
- (void)pasteAsPlainText:(id)sender;
- (void)pasteAndPreserveFormatting:(id)sender;
- (void)paste:(id)sender;
- (void)cut:(id)sender;
- (void)copy:(id)sender;
- (void)showFindIndicatorForRange:(NSRange)arg1;

-(NSRect)bounds;
-(NSRect)frame;
-(NSSize)contentSize;
// Utilities
- (void)scrollRangeToVisible:(NSRange)arg1;
@property (readonly) NSInteger linesPerPage;
@property (readonly) NSInteger lineCount;
- (void)insertText:(id)string replacementRange:(NSRange)replacementRange;
- (void)scrollPageBackward:(NSUInteger)numPages;
- (void)scrollPageForward:(NSUInteger)numPages;
- (void)setSelectedRanges:(NSArray<NSValue*>*)ranges
                 affinity:(NSSelectionAffinity)affinity
           stillSelecting:(BOOL)stillSelectingFlag;

- (void)beginEditTransaction;
- (void)endEditTransaction;

@end

#import "SourceCodeEditorViewProxy+Scrolling.h"
#import "SourceCodeEditorViewProxy+Operations.h"
#import "SourceCodeEditorViewProxy+Yank.h"
#import "SourceCodeEditorViewProxy+XVim.h"


#define EDIT_TRANSACTION_SCOPE \
[self beginEditTransaction]; \
[self.undoManager beginUndoGrouping]; \
[self xvim_registerInsertionPointForUndo]; \
xvim_on_exit { [self.undoManager endUndoGrouping]; [self endEditTransaction]; };

