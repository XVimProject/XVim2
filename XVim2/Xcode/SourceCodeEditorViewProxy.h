//
//  SourceEditorProxy.h
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceViewProtocol.h"
#import <Foundation/Foundation.h>

@class _TtC15IDESourceEditor19IDESourceEditorView;

// Raw values for SourceEditor.SourceEditorSelectionModifiers
typedef NS_OPTIONS(unsigned, XVimSelectionModifiers) {
    SelectionModifierExtension = 1,
    SelectionModifierColumnar = 1 << 1,
    SelectionModifierDiscontiguous = 1 << 2
};

typedef struct {
    NSUInteger row;
    NSUInteger col;
} XVimSourceEditorPosition;

static inline XVimSourceEditorPosition XvimMakeSourceEditorPosition(NSUInteger row, NSUInteger col)
{
    XVimSourceEditorPosition pos = {.row = row, .col = col };
    return pos;
}
typedef struct {
    XVimSourceEditorPosition pos1;
    XVimSourceEditorPosition pos2;
} XVimSourceEditorRange;


static inline NSString* _Nonnull XVimSourceEditorRangeToString(XVimSourceEditorRange rng)
{
    return [NSString stringWithFormat:@"{ {row: %lu, col: %lu}, {row: %lu, col: %lu} }", rng.pos1.row, rng.pos1.col,
                                      rng.pos2.row, rng.pos2.col];
}

static inline XVimSourceEditorRange XvimMakeSourceEditorRange(XVimSourceEditorPosition pos1,
                                                              XVimSourceEditorPosition pos2)
{
    XVimSourceEditorRange rng = {.pos1 = pos1, .pos2 = pos2 };
    return rng;
}

@class XVimCommandLine;

// SourceEditorView.selection returns a SourceEditor.SourceEditorSelection?
// SourceEditorSelection is an internal class

@protocol XVimTextViewDelegateProtocol;
@class SourceCodeEditorViewWrapper, SourceEditorDataSourceWrapper;

@interface SourceCodeEditorViewProxy : NSObject <SourceViewProtocol>
@property (readonly) XVIM_VISUAL_MODE selectionMode;
@property (readonly) NSUInteger insertionPoint;
@property (readonly) XVimPosition insertionPosition;
@property (readonly) NSUInteger insertionColumn;
@property (readonly) NSUInteger insertionLine;
@property (readonly) NSUInteger preservedColumn;
@property (readonly) NSUInteger selectionBegin;
@property (readonly) XVimPosition selectionBeginPosition;
@property (readonly) BOOL selectionToEOL;
@property CURSOR_MODE cursorMode;
@property (readonly, nullable) NSURL* documentURL;
@property (nonatomic) BOOL needsUpdateFoundRanges;
@property (readonly, nonnull) NSMutableArray* foundRanges;
@property (readonly) NSInteger currentLineNumber;
@property (strong, nullable) id<XVimTextViewDelegateProtocol> xvimDelegate;
@property (readonly, nullable) XVimCommandLine* commandLine;
@property (readonly, nullable) NSWindow* window;
@property (strong, nonnull) NSString* string;
@property BOOL xvim_lockSyncStateFromView;
@property (strong, nullable) SourceCodeEditorViewWrapper* sourceCodeEditorViewWrapper;
@property (readonly, nonatomic, nullable) SourceEditorDataSourceWrapper* sourceEditorDataSourceWrapper;
- (nullable instancetype)initWithSourceCodeEditorView:(nonnull _TtC15IDESourceEditor19IDESourceEditorView *)sourceEditorView;

// Data source
@property (readonly, nonatomic, nullable) id dataSource;
- (NSUInteger)indexFromPosition:(XVimSourceEditorPosition)pos;
- (XVimSourceEditorPosition)positionFromIndex:(NSUInteger)idx lineHint:(NSUInteger)line;

// Proxy methods
- (NSRange)lineRangeForCharacterRange:(NSRange)arg1;
- (NSRange)characterRangeForLineRange:(NSRange)arg1;
- (NSUInteger)characterIndexForInsertionAtPoint:(CGPoint)arg1;
- (void)mouseExited:(id _Nullable)sender;
- (void)mouseEntered:(id _Nullable)sender;
- (void)mouseMoved:(id _Nullable)sender;
- (void)rightMouseUp:(id _Nullable)sender;
- (void)mouseUp:(id _Nullable)sender;
- (void)mouseDragged:(id _Nullable)sender;
- (void)rightMouseDown:(id _Nullable)sender;
- (void)mouseDown:(id _Nullable)sender;
- (void)insertText:(id _Nullable)sender;
- (void)selectWord:(id _Nullable)sender;
- (void)selectLine:(id _Nullable)sender;
- (void)selectParagraph:(id _Nullable)sender;
- (void)selectAll:(id _Nullable)sender;
- (void)scrollToEndOfDocument:(id _Nullable)sender;
- (void)scrollToBeginningOfDocument:(id _Nullable)sender;
- (void)scrollLineDown:(id _Nullable)sender;
- (void)scrollLineUp:(id _Nullable)sender;
- (void)scrollPageDown:(id _Nullable)sender;
- (void)scrollPageUp:(id _Nullable)sender;
- (void)centerSelectionInVisibleArea:(id _Nullable)sender;
- (void)pageUpAndModifySelection:(id _Nullable)sender;
- (void)pageDownAndModifySelection:(id _Nullable)sender;
- (void)pageUp:(id _Nullable)sender;
- (void)pageDown:(id _Nullable)sender;
- (void)moveToEndOfDocumentAndModifySelection:(id _Nullable)sender;
- (void)moveToBeginningOfDocumentAndModifySelection:(id _Nullable)sender;
- (void)moveToEndOfDocument:(id _Nullable)sender;
- (void)moveToBeginningOfDocument:(id _Nullable)sender;
- (void)moveParagraphBackwardAndModifySelection:(id _Nullable)sender;
- (void)moveParagraphForwardAndModifySelection:(id _Nullable)sender;
- (void)moveToEndOfParagraphAndModifySelection:(id _Nullable)sender;
- (void)moveToBeginningOfParagraphAndModifySelection:(id _Nullable)sender;
- (void)moveToEndOfParagraph:(id _Nullable)sender;
- (void)moveToBeginningOfParagraph:(id _Nullable)sender;
- (void)moveToEndOfTextAndModifySelection:(id _Nullable)sender;
- (void)moveToEndOfText:(id _Nullable)sender;
- (void)moveToBeginningOfTextAndModifySelection:(id _Nullable)sender;
- (void)moveToBeginningOfText:(id _Nullable)sender;
- (void)moveToRightEndOfLineAndModifySelection:(id _Nullable)sender;
- (void)moveToLeftEndOfLineAndModifySelection:(id _Nullable)sender;
- (void)moveToRightEndOfLine:(id _Nullable)sender;
- (void)moveToLeftEndOfLine:(id _Nullable)sender;
- (void)moveToEndOfLineAndModifySelection:(id _Nullable)sender;
- (void)moveToBeginningOfLineAndModifySelection:(id _Nullable)sender;
- (void)moveToEndOfLine:(id _Nullable)sender;
- (void)moveToBeginningOfLine:(id _Nullable)sender;
- (void)moveExpressionBackwardAndModifySelection:(id _Nullable)sender;
- (void)moveExpressionForwardAndModifySelection:(id _Nullable)sender;
- (void)moveExpressionBackward:(id _Nullable)sender;
- (void)moveExpressionForward:(id _Nullable)sender;
- (void)moveSubWordBackwardAndModifySelection:(id _Nullable)sender;
- (void)moveSubWordForwardAndModifySelection:(id _Nullable)sender;
- (void)moveSubWordBackward:(id _Nullable)sender;
- (void)moveSubWordForward:(id _Nullable)sender;
- (void)moveWordLeftAndModifySelection:(id _Nullable)sender;
- (void)moveWordRightAndModifySelection:(id _Nullable)sender;
- (void)moveWordLeft:(id _Nullable)sender;
- (void)moveWordRight:(id _Nullable)sender;
- (void)moveWordBackwardAndModifySelection:(id _Nullable)sender;
- (void)moveWordForwardAndModifySelection:(id _Nullable)sender;
- (void)moveWordBackward:(id _Nullable)sender;
- (void)moveWordForward:(id _Nullable)sender;
- (void)moveDownAndModifySelection:(id _Nullable)sender;
- (void)moveUpAndModifySelection:(id _Nullable)sender;
- (void)moveDown:(id _Nullable)sender;
- (void)moveUp:(id _Nullable)sender;
- (void)moveLeftAndModifySelection:(id _Nullable)sender;
- (void)moveRightAndModifySelection:(id _Nullable)sender;
- (void)moveLeft:(id _Nullable)sender;
- (void)moveRight:(id _Nullable)sender;
- (void)moveBackwardAndModifySelection:(id _Nullable)sender;
- (void)moveForwardAndModifySelection:(id _Nullable)sender;
- (void)moveBackward:(id _Nullable)sender;
- (void)moveForward:(id _Nullable)sender;
- (void)unfoldAllComments:(id _Nullable)sender;
- (void)foldAllComments:(id _Nullable)sender;
- (void)unfoldAllMethods:(id _Nullable)sender;
- (void)foldAllMethods:(id _Nullable)sender;
- (void)unfoldAll:(id _Nullable)sender;
- (void)unfold:(id _Nullable)sender;
- (void)fold:(id _Nullable)sender;
- (void)balance:(id _Nullable)sender;
- (void)selectStructure:(id _Nullable)sender;
- (void)shiftRight:(id _Nullable)sender;
- (void)shiftLeft:(id _Nullable)sender;
- (void)indentSelection:(id _Nullable)sender;
- (void)moveCurrentLineDown:(id _Nullable)sender;
- (void)moveCurrentLineUp:(id _Nullable)sender;
- (void)complete:(id _Nullable)sender;
- (void)swapWithMark:(id _Nullable)sender;
- (void)selectToMark:(id _Nullable)sender;
- (void)deleteToMark:(id _Nullable)sender;
- (void)setMark:(id _Nullable)sender;
- (void)yankAndSelect:(id _Nullable)sender;
- (void)yank:(id _Nullable)sender;
- (void)capitalizeWord:(id _Nullable)sender;
- (void)lowercaseWord:(id _Nullable)sender;
- (void)uppercaseWord:(id _Nullable)sender;
- (void)transpose:(id _Nullable)sender;
- (void)deleteToEndOfText:(id _Nullable)sender;
- (void)deleteToBeginningOfText:(id _Nullable)sender;
- (void)deleteToEndOfParagraph:(id _Nullable)sender;
- (void)deleteToBeginningOfParagraph:(id _Nullable)sender;
- (void)deleteToEndOfLine:(id _Nullable)sender;
- (void)deleteToBeginningOfLine:(id _Nullable)sender;
- (void)deleteExpressionBackward:(id _Nullable)sender;
- (void)deleteExpressionForward:(id _Nullable)sender;
- (void)deleteSubWordBackward:(id _Nullable)sender;
- (void)deleteSubWordForward:(id _Nullable)sender;
- (void)deleteWordBackward:(id _Nullable)sender;
- (void)deleteWordForward:(id _Nullable)sender;
- (void)deleteBackwardByDecomposingPreviousCharacter:(id _Nullable)sender;
- (void)deleteBackward:(id _Nullable)sender;
- (void)deleteForward:(id _Nullable)sender;
- (void) delete:(id _Nullable)sender;
- (void)insertDoubleQuoteIgnoringSubstitution:(id _Nullable)sender;
- (void)insertSingleQuoteIgnoringSubstitution:(id _Nullable)sender;
- (void)insertContainerBreak:(id _Nullable)sender;
- (void)insertLineBreak:(id _Nullable)sender;
- (void)insertTabIgnoringFieldEditor:(id _Nullable)sender;
- (void)insertNewlineIgnoringFieldEditor:(id _Nullable)sender;
- (void)insertParagraphSeparator:(id _Nullable)sender;
- (void)insertNewline:(id _Nullable)sender;
- (void)insertBacktab:(id _Nullable)sender;
- (void)insertTab:(id _Nullable)sender;
- (void)flagsChanged:(id _Nullable)sender;
- (void)keyDown:(id _Nullable)sender;
- (void)concludeDragOperation:(id _Nullable)sender;
- (void)draggingExited:(id _Nullable)sender;
- (void)pasteAsPlainText:(id _Nullable)sender;
- (void)pasteAndPreserveFormatting:(id _Nullable)sender;
- (void)paste:(id _Nullable)sender;
- (void)cut:(id _Nullable)sender;
- (void)copy:(id _Nullable)sender;
- (void)showFindIndicatorForRange:(NSRange)arg1;

- (NSRect)bounds;
- (NSRect)frame;
- (NSSize)contentSize;
// Utilities
- (void)scrollRangeToVisible:(NSRange)arg1;
@property (readonly) NSInteger linesPerPage;
@property (readonly) NSInteger lineCount;
- (void)insertText:(id _Nullable)string replacementRange:(NSRange)replacementRange;
- (void)scrollPageBackward:(NSUInteger)numPages;
- (void)scrollPageForward:(NSUInteger)numPages;
- (void)setSelectedRanges:(nonnull NSArray<NSValue*>*)ranges
                     affinity:(NSSelectionAffinity)affinity
               stillSelecting:(BOOL)stillSelectingFlag;

- (void)beginEditTransaction;
- (void)endEditTransaction;

@end
