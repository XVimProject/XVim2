#import "SourceEditorScrollView.h"
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>

@interface _TtC12SourceEditor16SourceEditorView : NSView <NSTextInputClient, NSServicesMenuRequestor> {
    // Error parsing type: , name: delegate
    // Error parsing type: , name: contentViewOffset
    // Error parsing type: , name: layoutManager
    // Error parsing type: , name: contentView
    // Error parsing type: , name: scrollView
    // Error parsing type: , name: editAssistant
    // Error parsing type: , name: structuredEditingController
    // Error parsing type: , name: foldingController
    // Error parsing type: , name: dataSource
    // Error parsing type: , name: boundsChangeObserver
    // Error parsing type: , name: frameChangeObserver
    // Error parsing type: , name: contentViewWidthConstraint
    // Error parsing type: , name: contentViewWidthLimitConstraint
    // Error parsing type: , name: contentViewHeightConstraint
    // Error parsing type: , name: contentViewHeightLimitConstraint
    // Error parsing type: , name: trimTrailingWhitespaceController
    // Error parsing type: , name: automaticallyAdjustsContentMargins
    // Error parsing type: , name: lineAnnotationManager.storage
    // Error parsing type: , name: gutter
    // Error parsing type: , name: draggingSource
    // Error parsing type: , name: registeredDraggingExtensions
    // Error parsing type: , name: textFindableDisplay.storage
    // Error parsing type: , name: textFindPanel.storage
    // Error parsing type: , name: textFindPanelDisplayed
    // Error parsing type: , name: findQuery
    // Error parsing type: , name: findResult
    // Error parsing type: , name: findReplaceWith
    // Error parsing type: , name: findResultNeedUpdate
    // Error parsing type: , name: selectedSymbolHighlight.storage
    // Error parsing type: , name: lineHighlightLayoutVisualization
    // Error parsing type: , name: delimiterHighlight.storage
    // Error parsing type: , name: coverageLayoutVisualization
    // Error parsing type: , name: isEditingEnabled
    // Error parsing type: , name: selectionController.storage
    // Error parsing type: , name: selectionDisplay
    // Error parsing type: , name: selection
    // Error parsing type: , name: oldSubstitutionView
    // Error parsing type: , name: calloutVisualization.storage
    // Error parsing type: , name: isCodeCompletionEnabled
    // Error parsing type: , name: languageServiceCompletionStrategy
    // Error parsing type: , name: codeCompletionController
    // Error parsing type: , name: currentListShownExplicitly
    // Error parsing type: , name: currentListWordStart
    // Error parsing type: , name: shouldProvideCodeCompletion
    // Error parsing type: , name: markedSourceRange
    // Error parsing type: , name: markedSourceSelection
    // Error parsing type: , name: markedEditTransaction
    // Error parsing type: , name: asyncContinuations
    // Error parsing type: , name: postLayoutContinuations
    // Error parsing type: , name: emacsMarkedSourceRange
    // Error parsing type: , name: continueKillRing
    // Error parsing type: , name: contextualMenuEventConsumer
    // Error parsing type: , name: contextualMenuItemProvider
    // Error parsing type: , name: structuredSelectionDelegate
    // Error parsing type: , name: eventConsumers
    // Error parsing type: , name: editing
    // Error parsing type: , name: isInLiveResize
    // Error parsing type: , name: contentSizeIsValid
    // Error parsing type: , name: contentSize
    // Error parsing type: , name: annotationsAccessibilityGroup_
}

+ (id)identifierCharacters;
+ (id)defaultMenu;
//- (CDUnknownBlockType).cxx_destruct;
//@property(nonatomic, readonly) NSString *description;
//@property(nonatomic, readonly) _TtC12SourceEditor29AnnotationsAccessibilityGroup *annotationsAccessibilityGroup;
- (void)contentViewDidFinishLayout;
- (void)removeContentVerticalShiftEffect:(BOOL)arg1;
- (void)setContentVerticalShiftEffect:(double)arg1;
@property (nonatomic, readonly) NSColor* tintColor;
@property (nonatomic, readonly) long long lineCount;
- (void)updateContentSizeIfNeeded;
@property (nonatomic) double contentSize; // @synthesize contentSize;
- (void)invalidateContentSize;
@property (nonatomic) BOOL contentSizeIsValid; // @synthesize contentSizeIsValid;
- (void)viewDidEndLiveResize;
- (void)viewWillStartLiveResize;
@property (nonatomic) BOOL isInLiveResize; // @synthesize isInLiveResize;
@property (nonatomic) BOOL editing; // @synthesize editing;
- (void)dataSourceEndEditTransaction;
- (void)dataSourceBeginEditTransaction;
- (void)dataSourceDidDeleteLines:(id)arg1;
- (void)dataSourceDidInsertLines:(id)arg1;
- (id)closestLineLayerToPoint:(struct CGPoint)arg1;
- (id)lineLayersInRect:(struct CGRect)arg1;
- (id)lineLayerAtPoint:(struct CGPoint)arg1;
- (void)applyScrollStateWithLine:(long long)arg1 offset:(double)arg2;
@property (nonatomic) BOOL continueKillRing; // @synthesize continueKillRing;
@property (nonatomic) BOOL markedEditTransaction; // @synthesize markedEditTransaction;
- (BOOL)shouldSuppressCodeCompletion;
- (void)showCodeCompletionSuggestionList;
- (void)queueCodeCompletionWithExplicitly:(BOOL)arg1;
- (void)codeCompletionAvailabilityChangedWithDuringReload:(BOOL)arg1;
- (void)overrideCompletionDisplayWithShouldDisplay:(BOOL)arg1;
@property (nonatomic) BOOL shouldProvideCodeCompletionInCurrentRange;
@property (nonatomic) BOOL currentListShownExplicitly; // @synthesize currentListShownExplicitly;
@property (nonatomic) BOOL isCodeCompletionEnabled; // @synthesize isCodeCompletionEnabled;
@property (nonatomic, readonly) BOOL isShowingCodeCompletion;
@property (nonatomic, readonly) BOOL escapeKeyTriggersCodeCompletion;
- (void)selectionWillChange;
@property (nonatomic) BOOL isEditingEnabled; // @synthesize isEditingEnabled;
@property (nonatomic) BOOL delimiterHighlightEnabled;
@property (nonatomic, readonly) NSLayoutYAxisAnchor* findPanelTopAnchor;
- (void)pushFindConfigurationForFindQuery;
- (void)pullFindConfigurationForFindQuery;
- (void)performTextFinderAction:(id)arg1;
- (void)performFindPanelAction:(id)arg1;
@property (nonatomic) BOOL findResultNeedUpdate; // @synthesize findResultNeedUpdate;
@property (nonatomic) BOOL textFindPanelDisplayed; // @synthesize textFindPanelDisplayed;
- (void)unregisterDraggingExtensionWithIdentifier:(id)arg1;
//@property(nonatomic, readonly) _TtC12SourceEditor30SourceEditorViewDraggingSource *draggingSource; // @synthesize
//draggingSource;
//@property(nonatomic, retain) _TtC12SourceEditor18SourceEditorGutter *gutter; // @synthesize gutter;
@property (nonatomic) BOOL allowLineAnnotationAnimations;
- (void)expandLineAnnotationsOnLine:(long long)arg1 animated:(BOOL)arg2;
- (id)mouseCursorForStructuredSelectionWith:(id)arg1;
- (void)resetCursorRects;
- (struct CGRect)contentRectForCursor;
- (void)invalidateCursorRects;
@property (nonatomic) BOOL automaticallyAdjustsContentMargins; // @synthesize automaticallyAdjustsContentMargins;
- (void)queueTrimTrailingWhitespace;
- (void)setupStructuredEditingController;
- (id)editorViewSnapshotsIn:(id)arg1;
@property (nonatomic, readonly)
            NSLayoutConstraint* contentViewHeightLimitConstraint; // @synthesize contentViewHeightLimitConstraint;
@property (nonatomic, readonly)
            NSLayoutConstraint* contentViewHeightConstraint; // @synthesize contentViewHeightConstraint;
@property (nonatomic, readonly)
            NSLayoutConstraint* contentViewWidthLimitConstraint; // @synthesize contentViewWidthLimitConstraint;
@property (nonatomic, readonly)
            NSLayoutConstraint* contentViewWidthConstraint; // @synthesize contentViewWidthConstraint;
- (BOOL)_wantsKeyDownForEvent:(id)arg1;
- (void)updateSelectionManagerIsActive;
- (BOOL)resignFirstResponder;
- (BOOL)becomeFirstResponder;
@property (nonatomic, readonly) BOOL acceptsFirstResponder;
- (void)viewDidMoveToWindow;
- (BOOL)isFlipped;
- (void)dealloc;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
- (id)initWithCoder:(id)arg1 sourceEditorScrollViewClass:(Class)arg2;
- (id)initWithFrame:(struct CGRect)arg1 sourceEditorScrollViewClass:(Class)arg2;
@property (nonatomic, readonly) SourceEditorScrollView* scrollView; // @synthesize scrollView;
//@property(nonatomic, readonly) _TtC12SourceEditor23SourceEditorContentView *contentView; // @synthesize contentView;
@property (nonatomic) double contentViewOffset; // @synthesize contentViewOffset;
- (void)mouseExited:(id)arg1;
- (void)mouseEntered:(id)arg1;
- (void)mouseMoved:(id)arg1;
- (void)rightMouseUp:(id)arg1;
- (void)mouseUp:(id)arg1;
- (void)mouseDragged:(id)arg1;
- (void)rightMouseDown:(id)arg1;
- (void)mouseDown:(id)arg1;
@property (nonatomic, readonly) id accessibilityFocusedUIElement;
- (long long)characterIndexForPoint:(struct CGPoint)arg1;
- (struct CGRect)firstRectForCharacterRange:(struct _NSRange)arg1 actualRange:(struct _NSRange*)arg2;
- (id)validAttributesForMarkedText;
- (id)attributedSubstringForProposedRange:(struct _NSRange)arg1 actualRange:(struct _NSRange*)arg2;
- (BOOL)hasMarkedText;
- (struct _NSRange)markedRange;
- (struct _NSRange)selectedRange;
- (void)unmarkText;
- (void)setMarkedText:(id)arg1 selectedRange:(struct _NSRange)arg2 replacementRange:(struct _NSRange)arg3;
- (void)insertText:(id)arg1 replacementRange:(struct _NSRange)arg2;
- (void)insertText:(id)arg1;
- (id)menuForEvent:(id)arg1;
- (void)selectWord:(id)arg1;
- (void)selectLine:(id)arg1;
- (void)selectParagraph:(id)arg1;
- (void)selectAll:(id)arg1;
- (void)scrollToEndOfDocument:(id)arg1;
- (void)scrollToBeginningOfDocument:(id)arg1;
- (void)scrollLineDown:(id)arg1;
- (void)scrollLineUp:(id)arg1;
- (void)scrollPageDown:(id)arg1;
- (void)scrollPageUp:(id)arg1;
- (void)centerSelectionInVisibleArea:(id)arg1;
- (void)pageUpAndModifySelection:(id)arg1;
- (void)pageDownAndModifySelection:(id)arg1;
- (void)pageUp:(id)arg1;
- (void)pageDown:(id)arg1;
- (long long)linesPerPage;
- (void)moveToEndOfDocumentAndModifySelection:(id)arg1;
- (void)moveToBeginningOfDocumentAndModifySelection:(id)arg1;
- (void)moveToEndOfDocument:(id)arg1;
- (void)moveToBeginningOfDocument:(id)arg1;
- (void)moveParagraphBackwardAndModifySelection:(id)arg1;
- (void)moveParagraphForwardAndModifySelection:(id)arg1;
- (void)moveToEndOfParagraphAndModifySelection:(id)arg1;
- (void)moveToBeginningOfParagraphAndModifySelection:(id)arg1;
- (void)moveToEndOfParagraph:(id)arg1;
- (void)moveToBeginningOfParagraph:(id)arg1;
- (void)moveToEndOfTextAndModifySelection:(id)arg1;
- (void)moveToEndOfText:(id)arg1;
- (void)moveToBeginningOfTextAndModifySelection:(id)arg1;
- (void)moveToBeginningOfText:(id)arg1;
- (void)moveToRightEndOfLineAndModifySelection:(id)arg1;
- (void)moveToLeftEndOfLineAndModifySelection:(id)arg1;
- (void)moveToRightEndOfLine:(id)arg1;
- (void)moveToLeftEndOfLine:(id)arg1;
- (void)moveToEndOfLineAndModifySelection:(id)arg1;
- (void)moveToBeginningOfLineAndModifySelection:(id)arg1;
- (void)moveToEndOfLine:(id)arg1;
- (void)moveToBeginningOfLine:(id)arg1;
- (void)moveExpressionBackwardAndModifySelection:(id)arg1;
- (void)moveExpressionForwardAndModifySelection:(id)arg1;
- (void)moveExpressionBackward:(id)arg1;
- (void)moveExpressionForward:(id)arg1;
- (void)moveSubWordBackwardAndModifySelection:(id)arg1;
- (void)moveSubWordForwardAndModifySelection:(id)arg1;
- (void)moveSubWordBackward:(id)arg1;
- (void)moveSubWordForward:(id)arg1;
- (void)moveWordLeftAndModifySelection:(id)arg1;
- (void)moveWordRightAndModifySelection:(id)arg1;
- (void)moveWordLeft:(id)arg1;
- (void)moveWordRight:(id)arg1;
- (void)moveWordBackwardAndModifySelection:(id)arg1;
- (void)moveWordForwardAndModifySelection:(id)arg1;
- (void)moveWordBackward:(id)arg1;
- (void)moveWordForward:(id)arg1;
- (void)moveDownAndModifySelection:(id)arg1;
- (void)_moveDownAndModifySelectionBy:(long long)arg1;
- (void)moveUpAndModifySelection:(id)arg1;
- (void)_moveUpAndModifySelectionBy:(long long)arg1;
- (void)moveDown:(id)arg1;
- (void)_moveDownBy:(long long)arg1;
- (void)moveUp:(id)arg1;
- (void)_moveUpBy:(long long)arg1;
- (void)moveLeftAndModifySelection:(id)arg1;
- (void)moveRightAndModifySelection:(id)arg1;
- (void)moveLeft:(id)arg1;
- (void)moveRight:(id)arg1;
- (void)moveBackwardAndModifySelection:(id)arg1;
- (void)moveForwardAndModifySelection:(id)arg1;
- (void)moveBackward:(id)arg1;
- (void)moveForward:(id)arg1;
- (void)unfoldAllComments:(id)arg1;
- (void)foldAllComments:(id)arg1;
- (void)unfoldAllMethods:(id)arg1;
- (void)foldAllMethods:(id)arg1;
- (void)unfoldAll:(id)arg1;
- (void)unfold:(id)arg1;
- (void)fold:(id)arg1;
- (void)balance:(id)arg1;
- (void)selectStructure:(id)arg1;
- (int)syntaxTypeWithLocation:(unsigned long long)arg1 effectiveRange:(struct _NSRange*)arg2;
- (void)shiftRight:(id)arg1;
- (void)shiftLeft:(id)arg1;
- (BOOL)indentSelectionWithAllowUnindent:(BOOL)arg1;
- (void)indentSelection:(id)arg1;
- (void)moveCurrentLineDown:(id)arg1;
- (void)moveCurrentLineUp:(id)arg1;
- (void)complete:(id)arg1;
- (void)swapWithMark:(id)arg1;
- (void)selectToMark:(id)arg1;
- (void)deleteToMark:(id)arg1;
- (void)setMark:(id)arg1;
- (void)yankAndSelect:(id)arg1;
- (void)yank:(id)arg1;
- (void)capitalizeWord:(id)arg1;
- (void)lowercaseWord:(id)arg1;
- (void)uppercaseWord:(id)arg1;
- (void)transpose:(id)arg1;
- (void)deleteToEndOfText:(id)arg1;
- (void)deleteToBeginningOfText:(id)arg1;
- (void)deleteToEndOfParagraph:(id)arg1;
- (void)deleteToBeginningOfParagraph:(id)arg1;
- (void)deleteToEndOfLine:(id)arg1;
- (void)deleteToBeginningOfLine:(id)arg1;
- (void)deleteExpressionBackward:(id)arg1;
- (void)deleteExpressionForward:(id)arg1;
- (void)deleteSubWordBackward:(id)arg1;
- (void)deleteSubWordForward:(id)arg1;
- (void)deleteWordBackward:(id)arg1;
- (void)deleteWordForward:(id)arg1;
- (void)deleteBackwardByDecomposingPreviousCharacter:(id)arg1;
- (void)deleteBackward:(id)arg1;
- (void)deleteForward:(id)arg1;
- (void) delete:(id)arg1;
- (void)insertDoubleQuoteIgnoringSubstitution:(id)arg1;
- (void)insertSingleQuoteIgnoringSubstitution:(id)arg1;
- (void)insertContainerBreak:(id)arg1;
- (void)insertLineBreak:(id)arg1;
- (void)insertTabIgnoringFieldEditor:(id)arg1;
- (void)insertNewlineIgnoringFieldEditor:(id)arg1;
- (void)insertParagraphSeparator:(id)arg1;
- (void)insertNewline:(id)arg1;
- (void)insertBacktab:(id)arg1;
- (void)insertTab:(id)arg1;
- (BOOL)shouldPerformActionAfterOptionallyDismissingCodeCompletion:(SEL)arg1;
- (void)doCommandBySelector:(SEL)arg1;
- (BOOL)validateMenuItem:(id)arg1;
- (void)flagsChanged:(id)arg1;
- (void)keyDown:(id)arg1;
- (void)concludeDragOperation:(id)arg1;
- (BOOL)performDragOperation:(id)arg1;
- (BOOL)prepareForDragOperation:(id)arg1;
- (void)draggingExited:(id)arg1;
- (unsigned long long)draggingUpdated:(id)arg1;
- (unsigned long long)draggingEntered:(id)arg1;
- (BOOL)performDragOperation:(unsigned long long)arg1 from:(id)arg2 with:(id)arg3 at:(struct CGPoint)arg4;
- (unsigned long long)dragOperationFor:(id)arg1
                      draggingLocation:(struct CGPoint)arg2
                   sourceOperationMask:(unsigned long long)arg3;
- (unsigned long long)dragOperationForDraggingInfo:(id)arg1;
@property (nonatomic, readonly) NSArray* defaultDragTypes;
- (BOOL)readSelectionFromPasteboard:(id)arg1;
- (BOOL)writeSelectionToPasteboard:(id)arg1 types:(id)arg2;
- (id)validRequestorForSendType:(id)arg1 returnType:(id)arg2;
- (void)pasteAsPlainText:(id)arg1;
- (void)pasteAndPreserveFormatting:(id)arg1;
- (void)paste:(id)arg1;
- (void)cut:(id)arg1;
- (void)copy:(id)arg1;

// Remaining properties
// @property(nonatomic, readonly) BOOL flipped;

@end

typedef _TtC12SourceEditor16SourceEditorView SourceEditorView;

@interface _TtC12SourceEditor16SourceEditorView(XVim)
-(void)xvim_keyDown:(NSEvent*)event;
@end

static NSString * const SourceEditorViewClassName = @"SourceEditor.SourceEditorView";
