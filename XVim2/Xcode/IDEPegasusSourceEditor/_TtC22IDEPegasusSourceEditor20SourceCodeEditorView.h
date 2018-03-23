#import "XVimDefs.h"
#import <IDEPegasusSourceEditor/_TtC22IDEPegasusSourceEditor16SourceCodeEditor.h>
#import <SourceEditor/_TtC12SourceEditor16SourceEditorView.h>

@class XVimKeyStroke;

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView
    : _TtC12SourceEditor16SourceEditorView

+ (BOOL)appSupportsActionMonitoring;
+ (id)identifierCharacters;
//- (CDUnknownBlockType).cxx_destruct;
- (void)didClickMarkForLine:(long long)arg1;
- (void)pushFindConfigurationForFindQuery;
- (void)pullFindConfigurationForFindQuery;
- (void)resignKeyWindow;
- (BOOL)resignFirstResponder;
- (void)viewWillMoveToWindow:(id)arg1;
- (void)removeFromSuperview;
- (unsigned long long)draggingEntered:(id)arg1;
- (BOOL)readSelectionFromPasteboard:(id)arg1;
- (void)selectPreviousPlaceholder:(id)arg1;
- (void)selectNextPlaceholder:(id)arg1;
- (id)menuForEvent:(id)arg1;
- (void)previousCompletion:(id)arg1;
- (void)nextCompletion:(id)arg1;
- (void)complete:(id)arg1;
- (void)setMarkedText:(id)arg1 selectedRange:(struct _NSRange)arg2 replacementRange:(struct _NSRange)arg3;
- (void)insertText:(id)arg1 replacementRange:(struct _NSRange)arg2;
- (void)doCommandBySelector:(SEL)arg1;
- (struct _NSRange)textCompletionSession:(id)arg1 replacementRangeForSuggestedRange:(struct _NSRange)arg2;
- (id)documentLocationForWordStartLocation:(unsigned long long)arg1;
- (id)contextForCompletionStrategiesAtWordStartLocation:(unsigned long long)arg1;
- (void)textCompletionSession:(id)arg1 didInsertCompletionItem:(id)arg2 range:(struct _NSRange)arg3;
- (struct _NSRange)performTextCompletionReplacementInRange:(struct _NSRange)arg1 withString:(id)arg2;
- (void)showFindIndicatorForRange:(struct _NSRange)arg1;
- (struct CGRect)frameContainingTextRange:(struct _NSRange)arg1;
- (struct CGRect)visibleTextRect;
- (void)scrollRangeToVisible:(struct _NSRange)arg1;
@property (nonatomic, readonly) NSScrollView* textCanvasScrollView;
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)arg1;
- (struct _NSRange)wordRangeAtLocation:(unsigned long long)arg1;
- (BOOL)isCurrentlyDoingNonUserEditing;
@property (nonatomic) struct _NSRange selectedTextRange;
@property (nonatomic, readonly) double autoCompletionDelay;
@property (nonatomic, readonly) BOOL shouldSuppressTextCompletion;
@property (nonatomic, readonly) NSString* string;
//@property(nonatomic, readonly) DVTSourceCodeLanguage *language;
//@property(nonatomic, readonly) DVTTextCompletionDataSource *completionsDataSource;
//@property(nonatomic, retain) DVTTextCompletionController *completionController; // @synthesize completionController;
- (id)mouseCursorForStructuredSelectionWith:(id)arg1;
- (void)contentViewDidFinishLayout;
- (void)paste:(id)arg1;
- (void)viewDidMoveToSuperview;
- (void)dealloc;
@property (nonatomic)
            __weak _TtC22IDEPegasusSourceEditor16SourceCodeEditor* hostingEditor; // @synthesize hostingEditor;
- (void)selectionWillChange;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
- (id)initWithCoder:(id)arg1 sourceEditorScrollViewClass:(Class)arg2;
- (id)initWithFrame:(struct CGRect)arg1 sourceEditorScrollViewClass:(Class)arg2;
// Remaining properties
@property (nonatomic, readonly) BOOL currentlyDoingNonUserEditing;


@end

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (IDEPegasusSourceEditor) // <DVTSourceModelProvider>
- (id)sourceModel;
@end

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (
            IDEPegasusSourceEditor1) // <DVTSourceLandmarkItemContainer>
- (id)sourceLandmarkAtCharacterIndex:(unsigned long long)arg1;
@end

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (
            IDEPegasusSourceEditor2) // <DVTLineRangeCharacterRangeConverter>
- (struct _NSRange)lineRangeForCharacterRange:(struct _NSRange)arg1;
- (struct _NSRange)characterRangeForLineRange:(struct _NSRange)arg1;
@end

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (
            IDEPegasusSourceEditor3) // <DVTCharacterRangeFrameConverter>
- (struct CGRect)frameForRange:(struct _NSRange)arg1 ignoreWhitespace:(BOOL)arg2;
@end

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (
            IDEPegasusSourceEditor4) // <DVTTextInsertionPointLocator>
- (unsigned long long)characterIndexForInsertionAtPoint:(struct CGPoint)arg1;
@end


typedef _TtC22IDEPegasusSourceEditor20SourceCodeEditorView SourceCodeEditorView;
@class XVimWindow;

@class SourceCodeEditorViewProxy;
@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView (XVim)
+ (void)xvim_hook;
@property (strong, readonly) XVimWindow* xvim_window;
@end

static NSString * const IDEPegasusSourceCodeEditorViewClassName = @"IDEPegasusSourceEditor.SourceCodeEditorView";

@interface XVimIDEPegasusSourceEditorView : NSObject
+(void)xvim_hook;
@end
