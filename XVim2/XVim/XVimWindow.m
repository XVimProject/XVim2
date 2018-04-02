//
//  XVimWindow.m
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import "XVimWindow.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceViewProtocol.h"
#import "XVim.h"
#import "XVimCommandLine.h"
#import "XVimEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimKeymap.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimNormalEvaluator.h"
#import "XVimOptions.h"
#import <objc/runtime.h>


@interface XVimWindow () {
    NSMutableArray* _defaultEvaluatorStack;
    NSMutableArray* _currentEvaluatorStack;
    XVimKeymapContext* _keymapContext;
    BOOL _handlingMouseEvent;
    NSString* _staticString;
    NSTextInputContext* _inputContext;
    id _enabledNotificationObserver;
}
@property (strong, atomic) NSEvent* tmpBuffer;
@property (strong) id<SourceViewProtocol> lastTextView;

- (void)_resetEvaluatorStack:(NSMutableArray*)stack activateNormalHandler:(BOOL)activate;

@end

@implementation XVimWindow
@synthesize tmpBuffer = _tmpBuffer;

- (instancetype)initWithEditorView:
            (id<SourceViewProtocol, SourceViewXVimProtocol, SourceViewScrollingProtocol, SourceViewOperationsProtocol, NSTextInputClient>)
                        editorArea
{
    if (self = [super init]) {
        _staticString = @"";
        _keymapContext = [[XVimKeymapContext alloc] init];
        _sourceView = editorArea;
        _defaultEvaluatorStack = [[NSMutableArray alloc] init];
        _currentEvaluatorStack = _defaultEvaluatorStack;
        _inputContext = [[NSTextInputContext alloc] initWithClient:self];
        [self _resetEvaluatorStack:_defaultEvaluatorStack activateNormalHandler:YES];
    }
    return self;
}


- (void)setupAfterEditorViewSetup
{
    __weak XVimWindow* weakSelf = self;
    [NSOperationQueue.mainQueue addOperationWithBlock:^{
        XVimWindow* strongSelf = weakSelf;
        strongSelf.sourceView.cursorMode = CURSOR_MODE_COMMAND;
    }];
    _enabledNotificationObserver = [NSNotificationCenter.defaultCenter
                addObserverForName:XVimNotificationEnabled
                            object:nil
                             queue:nil
                        usingBlock:^(NSNotification* _Nonnull note) {
                            XVimWindow* strongSelf = weakSelf;
                            BOOL enabled = [note.userInfo[XVimNotificationEnabledFlag] boolValue];
                            strongSelf.enabled = enabled;
                        }];
    self.enabled = XVIM.enabled;
    [XVIM registerWindow:self];
}

- (void)dealloc
{
    _enabledNotificationObserver = nil;
    [NSNotificationCenter.defaultCenter removeObserver:self.sourceView];
}


- (void)dumpEvaluatorStack:(NSMutableArray*)stack
{
    for (NSUInteger i = 0; i < stack.count; i++) {
        XVimEvaluator* e = [stack objectAtIndex:i];
        (void)(e);
        //DEBUG_LOG("Evaluator %lu :%@   argStr:%@   yankReg:%@", (unsigned long)i, NSStringFromClass([e class]),
        //          e.argumentString, e.yankRegister);
    }
}

#pragma mark - Handling keystrokes and evaluation stack

- (XVimEvaluator*)currentEvaluator { return [_currentEvaluatorStack lastObject]; }

- (void)_resetEvaluatorStack:(NSMutableArray*)stack activateNormalHandler:(BOOL)activate
{
    // Initialize evlauator stack
    [stack removeAllObjects];
    XVimEvaluator* firstEvaluator = [[XVimNormalEvaluator alloc] initWithWindow:self];
    [stack addObject:firstEvaluator];
    if (activate) {
        [firstEvaluator becameHandler];
    }
}

- (void)_documentChangedNotification:(NSNotification*)notification
{
    // Take strong reference to self, because the last remaining strong reference may be
    // in one of the evaluators we are about to dealloc with 'removeAllObjects'
    XVimWindow* this = self;
    [this.currentEvaluator cancelHandler];
    [_currentEvaluatorStack removeAllObjects];
    [this syncEvaluatorStack];
}

- (void)setEnabled:(BOOL)enable
{
    if (enable != _enabled) {
        _enabled = enable;
        if (enable) {
            [self _enable];
        }
        else {
            [self _disable];
        }
    }
}

- (void)_enable
{
    [NSNotificationCenter.defaultCenter addObserver:self.sourceView
                                           selector:@selector(selectionChanged:)
                                               name:@"SourceEditorSelectedSourceRangeChangedNotification"
                                             object:self.sourceView.view];
    self.sourceView.enabled = YES;
    ;
}

- (void)_disable
{
    [NSNotificationCenter.defaultCenter removeObserver:self.sourceView
                                                  name:@"SourceEditorSelectedSourceRangeChangedNotification"
                                                object:self.sourceView.view];
    self.sourceView.enabled = NO;
}


/**
 * handleKeyEvent:
 * This is the entry point of handling one key down event.
 * In Cocoa a key event is handled in following order by default.
 *  - keyDown: method in NSTextView (raw key event. Default impl calls interpertKeyEvents: method)
 *  - interpertKey: method in NSTextView
 *  - handleEvent: method in NSInputTextContext
 *  - (Some processing by Input Method Service such as Japanese or Chinese input system)
 *  - Callback methods(insertText: or doCommandBySelector:) in NSTextView are called from NSInpuTextContext
 *  -
 * See
 *https://developer.apple.com/library/mac/#documentation/TextFonts/Conceptual/CocoaTextArchitecture/TextEditing/TextEditing.html#//apple_ref/doc/uid/TP40009459-CH3-SW2
 *
 *  So the point is that if we intercept keyDwon: method and do not pass it to "interpretKeyEvent" or subsequent methods
 * we can not input Japanese or Chinese correctly.
 *
 *  So what we do here is that
 *    - Save original key input if it is INSERT or CMDLINE mode
 *    - Call handleEvent in NSInputTextContext with the event
 *      (The NSInputTextContext object is created with this XVimWindow object as its client)
 *    - If insertText: or doCommandBySelector: is called it just passes saved key event(XVimString) to
 *XVimInsertEvaluator or XVimCommandLineEvaluator. - If they are not called it means that the key input is handled by
 *the input method.
 **/
- (BOOL)handleKeyEvent:(NSEvent*)event
{
    if (!XVIM.isEnabled)
        return NO;

    // useinputsourcealways option forces to use input source to input on any mode.
    // This is for French or other keyborads.
    // The reason why we do not want to set this option always on is because
    // under some language (like Japanese) we do not want to let the input source obsorb a key event.
    // Under such language input source waits next input to fix the character to input.
    // Because in normal mode we never send Japanese character to Vim and so thats just nothing but trouble.
    // On the other hand, Franch language uses input source to send character like "}". So they need the help of input
    // source to send command to Vim.

    if (XVIM.options.alwaysuseinputsource || self.currentEvaluator.mode == XVIM_MODE_INSERT
        || self.currentEvaluator.mode == XVIM_MODE_CMDLINE) {
        // We must pass the event to the current input method
        // If it is obserbed we do not do anything anymore and handle insertText: or doCommandBySelector:

        // Keep the key input temporary buffer
        self.tmpBuffer = event;

        // The apple document says that we can not call 'activate' method directly
        // but if we do not call this the input is not handled by the input context we own.
        // So we call this every time key input comes.
        [_inputContext activate];

        // Pass it to the input context.
        // This is necesarry for languages like Japanese or Chinese.
        if ([_inputContext handleEvent:event]) {
            return YES;
        }
        else {
            return [self handleXVimString:[event toXVimString]];
        }
    }
    return [self handleXVimString:[event toXVimString]];
}

- (BOOL)handleOneXVimString:(XVimString*)oneChar
{
    XVimKeymap* keymap = [self.currentEvaluator selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:oneChar withContext:_keymapContext forceFix:NO];

    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(handleTimeout) object:nil];
    if (mapped) {
        //DEBUG_LOG("Mapped = %@", mapped);

        [_keymapContext clear];
        for (XVimKeyStroke* keyStroke in XVimKeyStrokesFromXVimString(mapped)) {
            [self handleKeyStroke:keyStroke onStack:_currentEvaluatorStack];
        }
    }
    else {
        NSTimeInterval delay = [XVIM.options.timeoutlen integerValue] / 1000.0;
        if (delay > 0) {
            [self performSelector:@selector(handleTimeout) withObject:nil afterDelay:delay];
        }
    }

    [self.commandLine setArgumentString:[self.currentEvaluator argumentDisplayString]];
    [self.commandLine setNeedsDisplay:YES];
    return YES;
}


- (BOOL)handleXVimString:(XVimString*)strokes
{
    BOOL last = NO;
    for (XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(strokes)) {
        last = [self handleOneXVimString:[stroke xvimString]];
    }
    return last;
}

- (void)handleTimeout
{
    XVimKeymap* keymap = [self.currentEvaluator selectKeymapWithProvider:[XVim instance]];
    XVimString* mapped = [keymap mapKeys:@"" withContext:_keymapContext forceFix:YES];
    for (XVimKeyStroke* keyStroke in XVimKeyStrokesFromXVimString(mapped)) {
        [self handleKeyStroke:keyStroke onStack:_currentEvaluatorStack];
    }
    [_keymapContext clear];
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke onStack:(NSMutableArray*)evaluatorStack
{
    _currentEvaluatorStack = (evaluatorStack ?: _defaultEvaluatorStack);

    if (_currentEvaluatorStack.count == 0) {
        [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
    }
    [self dumpEvaluatorStack:_currentEvaluatorStack];

    [self clearErrorMessage];

    // Record the event
    XVim* xvim = [XVim instance];
    [xvim appendOperationKeyStroke:[keyStroke xvimString]];

    // Evaluate key stroke
    XVimEvaluator* currentEvaluator = [_currentEvaluatorStack lastObject];
    currentEvaluator.window = self;

    if (self.tmpBuffer) {
        keyStroke.event = self.tmpBuffer;
        self.tmpBuffer = nil;
    }

    // Evaluate
    XVimEvaluator* nextEvaluator = nil;
    @try {
        nextEvaluator = [currentEvaluator eval:keyStroke];
    }
    @catch (NSException* ex) {
        ERROR_LOG(@"Exception caught while evaluating. Current evaluator = %@. Exception = %@", currentEvaluator, ex);
        [XVIM ringBell];
        [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
        return;
    }

    // Manipulate evaluator stack
    while (YES) {
        if (nil == nextEvaluator || nextEvaluator == [XVimEvaluator popEvaluator]) {

            // current evaluator finished its task
            XVimEvaluator* completeEvaluator = [_currentEvaluatorStack
                        lastObject]; // We have to retain here not to be dealloced in didEndHandler method.
            [_currentEvaluatorStack removeLastObject]; // remove current evaluator from the stack
            [completeEvaluator didEndHandler];

            if ([_currentEvaluatorStack count] == 0) {
                // Current Evaluator is the root evaluator of the stack
                [xvim cancelOperationCommands];
                [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
                break;
            }
            else {
                // Pass current evaluator to the evaluator below the current evaluator
                currentEvaluator = [_currentEvaluatorStack lastObject];
                [currentEvaluator becameHandler];

                if (nextEvaluator) {
                    break;
                }
                SEL onCompleteHandler = currentEvaluator.onChildCompleteHandler;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                nextEvaluator = [currentEvaluator performSelector:onCompleteHandler withObject:completeEvaluator];
#pragma clang diagnostic pop
                [currentEvaluator resetCompletionHandler];
            }
        }
        else if (nextEvaluator == [XVimEvaluator invalidEvaluator]) {
            [xvim cancelOperationCommands];
            [XVIM ringBell];
            [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:YES];
            break;
        }
        else if (nextEvaluator == [XVimEvaluator noOperationEvaluator]) {
            // Do nothing
            // This is only used by XVimNormalEvaluator AT handler.
            break;
        }
        else if (currentEvaluator != nextEvaluator) {
            // A new evaluator has been returned by the current evaluator: push it
            [_currentEvaluatorStack addObject:nextEvaluator];
            nextEvaluator.parent = currentEvaluator;
            //[currentEvaluator didEndHandler];
            [nextEvaluator becameHandler];
            // Not break here. check the nextEvaluator repeatedly.
            break;
        }
        else {
            // if current and next evaluator is the same do nothing.
            break;
        }
    }

    currentEvaluator = [_currentEvaluatorStack lastObject];

    [self.commandLine setModeString:[[currentEvaluator modeString] stringByAppendingString:_staticString]];
    [self.commandLine setArgumentString:[currentEvaluator argumentDisplayString]];

    _currentEvaluatorStack = _defaultEvaluatorStack;
}

- (void)syncEvaluatorStack
{
    BOOL needsVisual = (self.sourceView.selectedRange.length != 0);

    // if (!needsVisual && [self.currentEvaluator isKindOfClass:[XVimInsertEvaluator class]]) return;


    [self.currentEvaluator cancelHandler];
    [self _resetEvaluatorStack:_currentEvaluatorStack activateNormalHandler:!needsVisual];
    [[XVim instance] cancelOperationCommands];

    if (needsVisual) {
        // FIXME:JAS this doesn't work if v is remaped (yeah I know it's silly but...)
        [self handleOneXVimString:@"v"];
    }
    else {
        [self.sourceView xvim_adjustCursorPosition];
    }

    [self.commandLine setModeString:[self.currentEvaluator.modeString stringByAppendingString:_staticString]];
}


- (BOOL)shouldAutoCompleteAtLocation:(unsigned long long)location { return NO; }

// STATUS LINE
#pragma mark - Status Line

- (void)errorMessage:(NSString*)message ringBell:(BOOL)ringBell
{
    [self.commandLine errorMessage:message Timer:YES RedColorSetting:YES];
    if (ringBell) {
        [XVIM ringBell];
    }
    return;
}

- (void)statusMessage:(NSString*)message { [self.commandLine errorMessage:message Timer:NO RedColorSetting:NO]; }

- (void)clearErrorMessage { [self.commandLine errorMessage:@"" Timer:NO RedColorSetting:YES]; }

- (void)setForcusBackToSourceView { [self.sourceView.window makeFirstResponder:self.sourceView.view]; }

- (void)beginCommandEntry
{
    self.commandLine.modeHidden = YES;
    XVimCommandField* commandField = self.commandLine.commandField;
    [commandField setDelegate:self];
    [self.sourceView.window makeFirstResponder:commandField];
}

- (void)endCommandEntry
{
    XVimCommandField* commandField = self.commandLine.commandField;
    [commandField setDelegate:nil];
    [commandField setHidden:YES];
    self.commandLine.modeHidden = NO;
    [self setForcusBackToSourceView];
}

#pragma mark - NSTextInputClient Protocol

- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange
{
    @try {
        [self handleXVimString:aString];
    }
    @catch (NSException* exception) {
        ERROR_LOG("Exception %s: %s", [exception name], [exception reason]);
    }
}

- (void)doCommandBySelector:(SEL)aSelector
{
    @try {
        [self handleXVimString:[self.tmpBuffer toXVimString]];
        self.tmpBuffer = nil;
    }
    @catch (NSException* exception) {
        ERROR_LOG("Exception %s: %s", [exception name], [exception reason]);
    }
}

- (id<NSTextInputClient>)inputView
{
    if (self.currentEvaluator.mode == XVIM_MODE_CMDLINE) {
        return self.commandLine.commandField;
    }
    return self.sourceView;
}

- (void)setMarkedText:(id)aString selectedRange:(NSRange)selectedRange replacementRange:(NSRange)replacementRange
{
    if (self.currentEvaluator.mode == XVIM_MODE_INSERT || self.currentEvaluator.mode == XVIM_MODE_CMDLINE) {
        return [self.inputView setMarkedText:aString selectedRange:selectedRange replacementRange:replacementRange];
    }
    else {
        // Prohibit marked text # Issue 746 (Must be use with alwaysuseinputsource)
    }
}

- (void)unmarkText { return [self.inputView unmarkText]; }

- (NSRange)selectedRange { return [self.inputView selectedRange]; }

- (NSRange)markedRange { return [self.inputView markedRange]; }

- (BOOL)hasMarkedText { return [self.inputView hasMarkedText]; }

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
    return [self.inputView attributedSubstringForProposedRange:aRange actualRange:actualRange];
}

- (NSArray*)validAttributesForMarkedText { return [self.inputView validAttributesForMarkedText]; }

- (NSRect)firstRectForCharacterRange:(NSRange)aRange actualRange:(NSRangePointer)actualRange
{
    return [self.inputView firstRectForCharacterRange:aRange actualRange:actualRange];
}

- (NSUInteger)characterIndexForPoint:(NSPoint)aPoint { return [self.inputView characterIndexForPoint:aPoint]; }

- (XVimCommandLine*)commandLine { return self.sourceView.commandLine; }

- (XVimMark*)currentPositionMark
{
    XVimMark* mark = [[XVimMark alloc] init];
    NSRange r = [self.sourceView selectedRange];
    mark.document = [[self.sourceView documentURL] path];
    if (nil == mark.document) {
        return nil;
    }
    mark.line = [self.sourceView.textStorage xvim_lineNumberAtIndex:r.location];
    mark.column = [self.sourceView.textStorage xvim_columnOfIndex:r.location];
    return mark;
}

- (void)preMotion:(XVimMotion*)motion
{
    if (![motion isJumpMotion])
        return;

    XVimMark* mark = [self currentPositionMark];
    if (mark == nil)
        return;

    if (motion.jumpToAnotherFile) {
        // do nothing for jumping to another file
    }
    else {
        // update single quote mark
        [XVIM.marks setMark:mark forName:@"'"];
    }

    [XVIM.marks addToJumpListWithMark:mark KeepJumpMarkIndex:motion.keepJumpMarkIndex];
}

@end
