#import "_TtC12SourceEditor16SourceEditorView.h"

@class XVimKeyStroke;

@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView : _TtC12SourceEditor16SourceEditorView // <DVTTextCompletionSupportingTextView, DVTSourceCodeLanguageEditorView, DVTMarkedScrollerDelegate>
{
    // Error parsing type: , name: hostingEditor
    // Error parsing type: , name: completionController
    // Error parsing type: , name: realCompletionsDataSource
    // Error parsing type: , name: sharedFindStringNotificationToken
    // Error parsing type: , name: sharedReplaceStringNotificationToken
    // Error parsing type: , name: sharedFindOptionsNotificationToken
    // Error parsing type: , name: isPullingFindConfiguration
    // Error parsing type: , name: markedVerticalScroller
    // Error parsing type: , name: updateMarkedVerticalScrollerContinuation.storage
}

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
@property(nonatomic, readonly) NSScrollView *textCanvasScrollView;
- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)arg1;
- (struct _NSRange)wordRangeAtLocation:(unsigned long long)arg1;
- (BOOL)isCurrentlyDoingNonUserEditing;
@property(nonatomic) struct _NSRange selectedTextRange;
@property(nonatomic, readonly) double autoCompletionDelay;
@property(nonatomic, readonly) BOOL shouldSuppressTextCompletion;
@property(nonatomic, readonly) NSString *string;
//@property(nonatomic, readonly) DVTSourceCodeLanguage *language;
//@property(nonatomic, readonly) DVTTextCompletionDataSource *completionsDataSource;
//@property(nonatomic, retain) DVTTextCompletionController *completionController; // @synthesize completionController;
- (id)mouseCursorForStructuredSelectionWith:(id)arg1;
- (void)contentViewDidFinishLayout;
- (void)paste:(id)arg1;
- (void)viewDidMoveToSuperview;
- (void)dealloc;
//@property(nonatomic) __weak _TtC22IDEPegasusSourceEditor16SourceCodeEditor *hostingEditor; // @synthesize hostingEditor;
- (void)selectionWillChange;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;
- (id)initWithCoder:(id)arg1 sourceEditorScrollViewClass:(Class)arg2;
- (id)initWithFrame:(struct CGRect)arg1 sourceEditorScrollViewClass:(Class)arg2;
// Remaining properties
@property(nonatomic, readonly) BOOL currentlyDoingNonUserEditing;


@end

typedef NS_ENUM(NSInteger, XVimMode) {
    XVIM_MODE_NORMAL,
    XVIM_MODE_INSERT,
};

@class SourceEditorViewProxy;
@interface _TtC22IDEPegasusSourceEditor20SourceCodeEditorView(XVim)
+ (void)xvim_hook;
@property (strong, readonly) SourceEditorViewProxy *proxy;
@property (nonatomic) XVimMode xvim_mode;
@end

