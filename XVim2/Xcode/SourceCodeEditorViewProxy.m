//
//  SourceEditorProxy.m
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceCodeEditorViewProxy.h"
#import "NSTextStorage+VimOperation.h"
#import "NSString+VimHelper.h"
#import "XVim.h"
#import <IDEPegasusSourceEditor/_TtC22IDEPegasusSourceEditor16SourceCodeEditor.h>
#import <IDEPegasusSourceEditor/_TtC22IDEPegasusSourceEditor18SourceCodeDocument.h>
#import "XVimMotion.h"
#import "rd_route.h"
#import "ffi.h"

static void (*fpSetCursorStyle)(int style, id obj);
static void (*fpGetCursorStyle)(int style, id obj);
static void (*fpGetTextStorage)(void);
static void (*fpGetSourceEditorDataSource)(void);
static void (*fpBeginEditingTransaction)(void);
static void (*fpEndEditingTransaction)(void);


@interface SourceCodeEditorViewProxy ()
@property (weak) SourceCodeEditorView* sourceCodeEditorView;
@property (readwrite) NSUInteger selectionBegin;
@property (readwrite) NSUInteger insertionPoint;
@property (readwrite) NSUInteger preservedColumn;
@property (readwrite) BOOL selectionToEOL;
@property (readonly) NSTextStorage* textStorage;
@property (strong) NSString* lastYankedText;
@property TEXT_TYPE lastYankedType;
@property NSRange selectedRange;
@property BOOL xvim_lockSyncStateFromView;
@end

#define LOG_STATE()

@implementation SourceCodeEditorViewProxy {
        NSMutableArray<NSValue*>* _foundRanges;
}

+ (void)initialize
{
        if (self == [SourceCodeEditorViewProxy class]) {
                // SourceEditorView.cursorStyle.setter
                fpSetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofs", NULL);
                fpGetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofg", NULL);
                fpGetTextStorage = function_ptr_from_name("_T022IDEPegasusSourceEditor0B12CodeDocumentC16sdefSupport_textSo13NSTextStorageCyF", NULL);
                fpGetSourceEditorDataSource = function_ptr_from_name("_T012SourceEditor0aB4ViewC04dataA0AA0ab4DataA0Cfg", NULL);
                // Methdos on data source
                fpBeginEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C20beginEditTransactionyyF", NULL);
                fpEndEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C18endEditTransactionyyF", NULL);
        }
}

- (instancetype)initWithSourceCodeEditorView:(SourceCodeEditorView*)sourceCodeEditorView
{
        self = [super init];
        if (self) {
                self.sourceCodeEditorView = sourceCodeEditorView;
                self.cursorMode = CURSOR_MODE_COMMAND;
                [NSNotificationCenter.defaultCenter addObserver:self
                                                       selector:@selector(selectionChanged:)
                                                           name:@"SourceEditorSelectedSourceRangeChangedNotification"
                                                         object:sourceCodeEditorView];
        }
        return self;
}


- (NSRange)lineRangeForCharacterRange:(NSRange)arg1
{
        return [self.sourceCodeEditorView lineRangeForCharacterRange:arg1];
}
- (NSRange)characterRangeForLineRange:(NSRange)arg1
{
        return [self.sourceCodeEditorView characterRangeForLineRange:arg1];
}
- (NSInteger)linesPerPage
{
        return self.sourceCodeEditorView.linesPerPage;
}
- (NSInteger)lineCount
{
        return self.sourceCodeEditorView.lineCount;
}
- (void)scrollRangeToVisible:(NSRange)arg1
{
        [self.sourceCodeEditorView scrollRangeToVisible:arg1];
}
- (void)setCursorStyle:(CursorStyle)cursorStyle
{
        void* sev = (__bridge_retained void*)self.sourceCodeEditorView;

        __asm__(
                    "movq %[CursorStyle], %%rdi\n\t"
                    "movq %[SourceEditorView], %%r13\n\t"
                    "call *%[SetCursorStyle]\n\t"
                    :
                    : [CursorStyle] "r"(cursorStyle), [SourceEditorView] "r"(sev), [SetCursorStyle] "m"(fpSetCursorStyle)
                    : "memory", "cc", "%rdi", "%r13");
}

- (CursorStyle)cursorStyle
{
        void* sev = (__bridge_retained void*)self.sourceCodeEditorView;
        uint64_t cstyle = 0;
        __asm__(
                    "movq %[SourceEditorView], %%r13\n\t"
                    "call *%[GetCursorStyle]\n\t"
                    "movq %%rax, %[CursorStyle]\n\t"

                    : [CursorStyle] "=r"(cstyle)
                    : [SourceEditorView] "r"(sev), [GetCursorStyle] "m"(fpGetCursorStyle)
                    : "memory", "%rax", "%r13");
        cstyle = cstyle & 0xFF;
        return cstyle;
}


- (id)dataSource
{
        void* sev = (__bridge_retained void*)self.sourceCodeEditorView;
        uint64_t cstyle = 0;
        __asm__(
                    "movq %1, %%r13\n\t"
                    "call *%2\n\t"
                    "movq %%rax, %0\n\t"

                    : "=r"(cstyle)
                    : "r"(sev), "m"(fpGetSourceEditorDataSource)
                    : "memory", "%rax");
        id dataSource = (__bridge id)(void*)cstyle;
        return dataSource;
}

- (void)beginEditTransaction
{
        void* sev = (__bridge_retained void*)self.sourceCodeEditorView;
        __asm__(
                    "movq %[SourceEditorView], %%r13\n\t"
                    "call *%[DataSourceGetter]\n\t"
                    "movq %%rax, %%r13\n\t"
                    "call *%[BeginEditTransaction]\n\t"
                    :
                    : [SourceEditorView] "r"(sev), [DataSourceGetter] "m"(fpGetSourceEditorDataSource), [BeginEditTransaction] "m"(fpBeginEditingTransaction)
                    : "memory", "%rax", "%r13");
}

- (void)endEditTransaction
{
        void* sev = (__bridge_retained void*)self.sourceCodeEditorView;
        __asm__(
                    "movq %[SourceEditorView], %%r13\n\t"
                    "call *%[DataSourceGetter]\n\t"
                    "movq %%rax, %%r13\n\t"
                    "call *%[EndEditTransaction]\n\t"
                    :
                    : [SourceEditorView] "r"(sev), [DataSourceGetter] "m"(fpGetSourceEditorDataSource), [EndEditTransaction] "m"(fpEndEditingTransaction)
                    : "memory", "%rax", "%r13");
}


- (void)keyDown:(NSEvent*)event
{
        [self.sourceCodeEditorView xvim_keyDown:event];
}

- (NSString*)string
{
        return self.sourceCodeEditorView.string;
}


- (void)insertText:(id)string replacementRange:(NSRange)replacementRange
{
        [self.sourceCodeEditorView insertText:string replacementRange:replacementRange];
}

- (void)insertText:(NSString*)text
{
        [self.sourceCodeEditorView insertText:text];
}

- (NSTextStorage*)textStorage
{
        NSTextStorage* storage = [[NSTextStorage alloc] initWithString:self.string];
        return storage;
}

- (NSUndoManager*)undoManager
{
        return self.sourceCodeEditorView.undoManager;
}

- (void)scrollPageBackward:(NSUInteger)numPages
{
        for (int i = 0; i < numPages; ++i)
                [self.sourceCodeEditorView scrollPageUp:self];
}

- (void)scrollPageForward:(NSUInteger)numPages
{
        for (int i = 0; i < numPages; ++i)
                [self.sourceCodeEditorView scrollPageDown:self];
}


- (void)interpretKeyEvents:(NSArray<NSEvent*>*)eventArray
{
        [self.sourceCodeEditorView interpretKeyEvents:eventArray];
}

#pragma mark-- NSTextInputClient

- (void)setSelectedRange:(NSRange)range
{
        self.sourceCodeEditorView.selectedTextRange = range;
}

- (NSRange)selectedRange
{
        return self.sourceCodeEditorView.selectedTextRange;
}

- (nullable NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range actualRange:(nullable NSRangePointer)actualRange
{
        return [self.sourceCodeEditorView attributedSubstringForProposedRange:range actualRange:actualRange];
}


- (NSUInteger)characterIndexForPoint:(NSPoint)point
{
        return [self.sourceCodeEditorView characterIndexForPoint:point];
}


- (void)doCommandBySelector:(nonnull SEL)selector
{
        [self.sourceCodeEditorView doCommandBySelector:selector];
}


- (NSRect)firstRectForCharacterRange:(NSRange)range actualRange:(nullable NSRangePointer)actualRange
{
        return [self.sourceCodeEditorView firstRectForCharacterRange:range actualRange:actualRange];
}


- (BOOL)hasMarkedText
{
        return self.sourceCodeEditorView.hasMarkedText;
}


- (NSRange)markedRange
{
        return self.sourceCodeEditorView.markedRange;
}


- (void)setMarkedText:(nonnull id)string selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange
{
        [self.sourceCodeEditorView setMarkedText:string selectedRange:selectedRange replacementRange:replacementRange];
}


- (void)unmarkText
{
        [self.sourceCodeEditorView unmarkText];
}


- (nonnull NSArray<NSAttributedStringKey>*)validAttributesForMarkedText
{
        return self.sourceCodeEditorView.validAttributesForMarkedText;
}

#pragma mark-- selection

- (void)setSelectedRanges:(NSArray<NSValue*>*)ranges
                 affinity:(NSSelectionAffinity)affinity
           stillSelecting:(BOOL)stillSelectingFlag
{
        // TODO
        if (ranges.count == 0)
                return;
        [self.sourceCodeEditorView setSelectedTextRange:ranges[0].rangeValue];
        for (NSValue* val in ranges)
                DEBUG_LOG("Range: %@", NSStringFromRange(val.rangeValue));
}


- (void)selectionChanged:(NSNotification*)changeNotification
{
        if (!self.xvim_lockSyncStateFromView) {
                DEBUG_LOG(@"SELECTION CHANGED from %@! Locked = %@", changeNotification.object, self.xvim_lockSyncStateFromView ? @"YES" : @"NO");
                [self xvim_syncStateFromView];
        }
}

- (void)setSelectionMode:(XVIM_VISUAL_MODE)selectionMode
{
        if (_selectionMode != selectionMode) {
                self.selectionToEOL = NO;
                _selectionMode = selectionMode;
        }
}

- (CURSOR_MODE)cursorMode
{
        return self.cursorStyle == CursorStyleVerticalBar ? CURSOR_MODE_INSERT : CURSOR_MODE_COMMAND;
}

- (void)setCursorMode:(CURSOR_MODE)cursorMode
{
        self.cursorStyle = (cursorMode == CURSOR_MODE_INSERT) ? CursorStyleVerticalBar : CursorStyleBlock;
}

- (NSInteger)currentLineNumber
{
        _auto ln = [self.sourceCodeEditorView lineRangeForCharacterRange:self.sourceCodeEditorView.selectedTextRange].location;
        return ln == NSNotFound ? 0 : (NSInteger)ln;
}

- (XVimPosition)insertionPosition
{
        return XVimMakePosition(self.insertionLine, self.insertionColumn);
}

- (void)setInsertionPosition:(XVimPosition)pos
{
        // Not implemented yet (Just update corresponding insertionPoint)
}

- (NSUInteger)insertionColumn
{
        return self.sourceCodeEditorView.accessibilityColumnIndexRange.location;
}

- (NSUInteger)insertionLine
{
        return [self.textStorage xvim_lineNumberAtIndex:self.insertionPoint];
}


- (XVimPosition)selectionBeginPosition
{
        return XVimMakePosition([self.textStorage xvim_lineNumberAtIndex:self.selectionBegin], [self.textStorage xvim_columnOfIndex:self.selectionBegin]);
}


- (NSURL*)documentURL
{
        if ([self.sourceCodeEditorView.hostingEditor isKindOfClass:NSClassFromString(@"IDEEditor")]) {
                return [(IDEEditorDocument*)((IDEEditor*)self.sourceCodeEditorView.hostingEditor).document fileURL];
        }
        else {
                return nil;
        }
}

// Proxy methods

- (void)mouseExited:(id)sender { [self.sourceCodeEditorView mouseExited:self]; }
- (void)mouseEntered:(id)sender { [self.sourceCodeEditorView mouseEntered:self]; }
- (void)mouseMoved:(id)sender { [self.sourceCodeEditorView mouseMoved:self]; }
- (void)rightMouseUp:(id)sender { [self.sourceCodeEditorView rightMouseUp:self]; }
- (void)mouseUp:(id)sender { [self.sourceCodeEditorView mouseUp:self]; }
- (void)mouseDragged:(id)sender { [self.sourceCodeEditorView mouseDragged:self]; }
- (void)rightMouseDown:(id)sender { [self.sourceCodeEditorView rightMouseDown:self]; }
- (void)mouseDown:(id)sender { [self.sourceCodeEditorView mouseDown:self]; }
- (void)selectWord:(id)sender { [self.sourceCodeEditorView selectWord:self]; }
- (void)selectLine:(id)sender { [self.sourceCodeEditorView selectLine:self]; }
- (void)selectParagraph:(id)sender { [self.sourceCodeEditorView selectParagraph:self]; }
- (void)selectAll:(id)sender { [self.sourceCodeEditorView selectAll:self]; }
- (void)scrollToEndOfDocument:(id)sender { [self.sourceCodeEditorView scrollToEndOfDocument:self]; }
- (void)scrollToBeginningOfDocument:(id)sender { [self.sourceCodeEditorView scrollToBeginningOfDocument:self]; }
- (void)scrollLineDown:(id)sender { [self.sourceCodeEditorView scrollLineDown:self]; }
- (void)scrollLineUp:(id)sender { [self.sourceCodeEditorView scrollLineUp:self]; }
- (void)scrollPageDown:(id)sender { [self.sourceCodeEditorView scrollPageDown:self]; }
- (void)scrollPageUp:(id)sender { [self.sourceCodeEditorView scrollPageUp:self]; }
- (void)centerSelectionInVisibleArea:(id)sender { [self.sourceCodeEditorView centerSelectionInVisibleArea:self]; }
- (void)pageUpAndModifySelection:(id)sender { [self.sourceCodeEditorView pageUpAndModifySelection:self]; }
- (void)pageDownAndModifySelection:(id)sender { [self.sourceCodeEditorView pageDownAndModifySelection:self]; }
- (void)pageUp:(id)sender { [self.sourceCodeEditorView pageUp:self]; }
- (void)pageDown:(id)sender { [self.sourceCodeEditorView pageDown:self]; }
- (void)moveToEndOfDocumentAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToEndOfDocumentAndModifySelection:self]; }
- (void)moveToBeginningOfDocumentAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToBeginningOfDocumentAndModifySelection:self]; }
- (void)moveToEndOfDocument:(id)sender { [self.sourceCodeEditorView moveToEndOfDocument:self]; }
- (void)moveToBeginningOfDocument:(id)sender { [self.sourceCodeEditorView moveToBeginningOfDocument:self]; }
- (void)moveParagraphBackwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveParagraphBackwardAndModifySelection:self]; }
- (void)moveParagraphForwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveParagraphForwardAndModifySelection:self]; }
- (void)moveToEndOfParagraphAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToEndOfParagraphAndModifySelection:self]; }
- (void)moveToBeginningOfParagraphAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToBeginningOfParagraphAndModifySelection:self]; }
- (void)moveToEndOfParagraph:(id)sender { [self.sourceCodeEditorView moveToEndOfParagraph:self]; }
- (void)moveToBeginningOfParagraph:(id)sender { [self.sourceCodeEditorView moveToBeginningOfParagraph:self]; }
- (void)moveToEndOfTextAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToEndOfTextAndModifySelection:self]; }
- (void)moveToEndOfText:(id)sender { [self.sourceCodeEditorView moveToEndOfText:self]; }
- (void)moveToBeginningOfTextAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToBeginningOfTextAndModifySelection:self]; }
- (void)moveToBeginningOfText:(id)sender { [self.sourceCodeEditorView moveToBeginningOfText:self]; }
- (void)moveToRightEndOfLineAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToRightEndOfLineAndModifySelection:self]; }
- (void)moveToLeftEndOfLineAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToLeftEndOfLineAndModifySelection:self]; }
- (void)moveToRightEndOfLine:(id)sender { [self.sourceCodeEditorView moveToRightEndOfLine:self]; }
- (void)moveToLeftEndOfLine:(id)sender { [self.sourceCodeEditorView moveToLeftEndOfLine:self]; }
- (void)moveToEndOfLineAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToEndOfLineAndModifySelection:self]; }
- (void)moveToBeginningOfLineAndModifySelection:(id)sender { [self.sourceCodeEditorView moveToBeginningOfLineAndModifySelection:self]; }
- (void)moveToEndOfLine:(id)sender { [self.sourceCodeEditorView moveToEndOfLine:self]; }
- (void)moveToBeginningOfLine:(id)sender { [self.sourceCodeEditorView moveToBeginningOfLine:self]; }
- (void)moveExpressionBackwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveExpressionBackwardAndModifySelection:self]; }
- (void)moveExpressionForwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveExpressionForwardAndModifySelection:self]; }
- (void)moveExpressionBackward:(id)sender { [self.sourceCodeEditorView moveExpressionBackward:self]; }
- (void)moveExpressionForward:(id)sender { [self.sourceCodeEditorView moveExpressionForward:self]; }
- (void)moveSubWordBackwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveSubWordBackwardAndModifySelection:self]; }
- (void)moveSubWordForwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveSubWordForwardAndModifySelection:self]; }
- (void)moveSubWordBackward:(id)sender { [self.sourceCodeEditorView moveSubWordBackward:self]; }
- (void)moveSubWordForward:(id)sender { [self.sourceCodeEditorView moveSubWordForward:self]; }
- (void)moveWordLeftAndModifySelection:(id)sender { [self.sourceCodeEditorView moveWordLeftAndModifySelection:self]; }
- (void)moveWordRightAndModifySelection:(id)sender { [self.sourceCodeEditorView moveWordRightAndModifySelection:self]; }
- (void)moveWordLeft:(id)sender { [self.sourceCodeEditorView moveWordLeft:self]; }
- (void)moveWordRight:(id)sender { [self.sourceCodeEditorView moveWordRight:self]; }
- (void)moveWordBackwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveWordBackwardAndModifySelection:self]; }
- (void)moveWordForwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveWordForwardAndModifySelection:self]; }
- (void)moveWordBackward:(id)sender { [self.sourceCodeEditorView moveWordBackward:self]; }
- (void)moveWordForward:(id)sender { [self.sourceCodeEditorView moveWordForward:self]; }
- (void)moveDownAndModifySelection:(id)sender { [self.sourceCodeEditorView moveDownAndModifySelection:self]; }
- (void)moveUpAndModifySelection:(id)sender { [self.sourceCodeEditorView moveUpAndModifySelection:self]; }
- (void)moveDown:(id)sender { [self.sourceCodeEditorView moveDown:self]; }
- (void)moveUp:(id)sender { [self.sourceCodeEditorView moveUp:self]; }
- (void)moveLeftAndModifySelection:(id)sender { [self.sourceCodeEditorView moveLeftAndModifySelection:self]; }
- (void)moveRightAndModifySelection:(id)sender { [self.sourceCodeEditorView moveRightAndModifySelection:self]; }
- (void)moveLeft:(id)sender { [self.sourceCodeEditorView moveLeft:self]; }
- (void)moveRight:(id)sender { [self.sourceCodeEditorView moveRight:self]; }
- (void)moveBackwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveBackwardAndModifySelection:self]; }
- (void)moveForwardAndModifySelection:(id)sender { [self.sourceCodeEditorView moveForwardAndModifySelection:self]; }
- (void)moveBackward:(id)sender { [self.sourceCodeEditorView moveBackward:self]; }
- (void)moveForward:(id)sender { [self.sourceCodeEditorView moveForward:self]; }
- (void)unfoldAllComments:(id)sender { [self.sourceCodeEditorView unfoldAllComments:self]; }
- (void)foldAllComments:(id)sender { [self.sourceCodeEditorView foldAllComments:self]; }
- (void)unfoldAllMethods:(id)sender { [self.sourceCodeEditorView unfoldAllMethods:self]; }
- (void)foldAllMethods:(id)sender { [self.sourceCodeEditorView foldAllMethods:self]; }
- (void)unfoldAll:(id)sender { [self.sourceCodeEditorView unfoldAll:self]; }
- (void)unfold:(id)sender { [self.sourceCodeEditorView unfold:self]; }
- (void)fold:(id)sender { [self.sourceCodeEditorView fold:self]; }
- (void)balance:(id)sender { [self.sourceCodeEditorView balance:self]; }
- (void)selectStructure:(id)sender { [self.sourceCodeEditorView selectStructure:self]; }
- (void)shiftRight:(id)sender { [self.sourceCodeEditorView shiftRight:self]; }
- (void)shiftLeft:(id)sender { [self.sourceCodeEditorView shiftLeft:self]; }
- (void)indentSelection:(id)sender { [self.sourceCodeEditorView indentSelection:self]; }
- (void)moveCurrentLineDown:(id)sender { [self.sourceCodeEditorView moveCurrentLineDown:self]; }
- (void)moveCurrentLineUp:(id)sender { [self.sourceCodeEditorView moveCurrentLineUp:self]; }
- (void)complete:(id)sender { [self.sourceCodeEditorView complete:self]; }
- (void)swapWithMark:(id)sender { [self.sourceCodeEditorView swapWithMark:self]; }
- (void)selectToMark:(id)sender { [self.sourceCodeEditorView selectToMark:self]; }
- (void)deleteToMark:(id)sender { [self.sourceCodeEditorView deleteToMark:self]; }
- (void)setMark:(id)sender { [self.sourceCodeEditorView setMark:self]; }
- (void)yankAndSelect:(id)sender { [self.sourceCodeEditorView yankAndSelect:self]; }
- (void)yank:(id)sender { [self.sourceCodeEditorView yank:self]; }
- (void)capitalizeWord:(id)sender { [self.sourceCodeEditorView capitalizeWord:self]; }
- (void)lowercaseWord:(id)sender { [self.sourceCodeEditorView lowercaseWord:self]; }
- (void)uppercaseWord:(id)sender { [self.sourceCodeEditorView uppercaseWord:self]; }
- (void)transpose:(id)sender { [self.sourceCodeEditorView transpose:self]; }
- (void)deleteToEndOfText:(id)sender { [self.sourceCodeEditorView deleteToEndOfText:self]; }
- (void)deleteToBeginningOfText:(id)sender { [self.sourceCodeEditorView deleteToBeginningOfText:self]; }
- (void)deleteToEndOfParagraph:(id)sender { [self.sourceCodeEditorView deleteToEndOfParagraph:self]; }
- (void)deleteToBeginningOfParagraph:(id)sender { [self.sourceCodeEditorView deleteToBeginningOfParagraph:self]; }
- (void)deleteToEndOfLine:(id)sender { [self.sourceCodeEditorView deleteToEndOfLine:self]; }
- (void)deleteToBeginningOfLine:(id)sender { [self.sourceCodeEditorView deleteToBeginningOfLine:self]; }
- (void)deleteExpressionBackward:(id)sender { [self.sourceCodeEditorView deleteExpressionBackward:self]; }
- (void)deleteExpressionForward:(id)sender { [self.sourceCodeEditorView deleteExpressionForward:self]; }
- (void)deleteSubWordBackward:(id)sender { [self.sourceCodeEditorView deleteSubWordBackward:self]; }
- (void)deleteSubWordForward:(id)sender { [self.sourceCodeEditorView deleteSubWordForward:self]; }
- (void)deleteWordBackward:(id)sender { [self.sourceCodeEditorView deleteWordBackward:self]; }
- (void)deleteWordForward:(id)sender { [self.sourceCodeEditorView deleteWordForward:self]; }
- (void)deleteBackwardByDecomposingPreviousCharacter:(id)sender { [self.sourceCodeEditorView deleteBackwardByDecomposingPreviousCharacter:self]; }
- (void)deleteBackward:(id)sender { [self.sourceCodeEditorView deleteBackward:self]; }
- (void)deleteForward:(id)sender { [self.sourceCodeEditorView deleteForward:self]; }
- (void) delete:(id)sender { [self.sourceCodeEditorView delete:self]; }
- (void)insertDoubleQuoteIgnoringSubstitution:(id)sender { [self.sourceCodeEditorView insertDoubleQuoteIgnoringSubstitution:self]; }
- (void)insertSingleQuoteIgnoringSubstitution:(id)sender { [self.sourceCodeEditorView insertSingleQuoteIgnoringSubstitution:self]; }
- (void)insertContainerBreak:(id)sender { [self.sourceCodeEditorView insertContainerBreak:self]; }
- (void)insertLineBreak:(id)sender { [self.sourceCodeEditorView insertLineBreak:self]; }
- (void)insertTabIgnoringFieldEditor:(id)sender { [self.sourceCodeEditorView insertTabIgnoringFieldEditor:self]; }
- (void)insertNewlineIgnoringFieldEditor:(id)sender { [self.sourceCodeEditorView insertNewlineIgnoringFieldEditor:self]; }
- (void)insertParagraphSeparator:(id)sender { [self.sourceCodeEditorView insertParagraphSeparator:self]; }
- (void)insertNewline:(id)sender { [self.sourceCodeEditorView insertNewline:self]; }
- (void)insertBacktab:(id)sender { [self.sourceCodeEditorView insertBacktab:self]; }
- (void)insertTab:(id)sender { [self.sourceCodeEditorView insertTab:self]; }
- (void)flagsChanged:(id)sender { [self.sourceCodeEditorView flagsChanged:self]; }
- (void)concludeDragOperation:(id)sender { [self.sourceCodeEditorView concludeDragOperation:self]; }
- (void)draggingExited:(id)sender { [self.sourceCodeEditorView draggingExited:self]; }
- (void)pasteAsPlainText:(id)sender { [self.sourceCodeEditorView pasteAsPlainText:self]; }
- (void)pasteAndPreserveFormatting:(id)sender { [self.sourceCodeEditorView pasteAndPreserveFormatting:self]; }
- (void)paste:(id)sender { [self.sourceCodeEditorView paste:self]; }
- (void)cut:(id)sender { [self.sourceCodeEditorView cut:self]; }
- (void)copy:(id)sender { [self.sourceCodeEditorView copy:self]; }

- (NSUInteger)characterIndexForInsertionAtPoint:(CGPoint)arg1{
        return [self.sourceCodeEditorView characterIndexForInsertionAtPoint:arg1];
}

-(NSRect)bounds { return self.sourceCodeEditorView.bounds; }
-(NSRect)frame { return self.sourceCodeEditorView.frame; }
-(NSSize)contentSize { return self.sourceCodeEditorView.visibleTextRect.size; }
@end
