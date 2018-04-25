//
//  XVimTestCase.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import "XVimTestCase.h"
#import "Logger.h"
#import "SourceCodeEditorViewProxy.h"
#import "SourceCodeEditorViewProxy+XVim.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XcodeUtils.h"
#import <stdatomic.h>

@interface XVimTestCase()
@property (class, readonly) NSOperationQueue * keySendQueue;
@property (weak) NSWindow * window;
@property dispatch_semaphore_t keySemaphore;
@property (readonly) dispatch_queue_t testCompletionDispatchQueue;
@property NSInteger keyStrokesCount;
@end

static NSOperationQueue *_keySendQueue = nil;
static dispatch_queue_t _keySendDispatchQueue = nil;
static dispatch_queue_t _testCompletionDispatchQueue = nil;
static atomic_uint dispatchQueueCount = ATOMIC_VAR_INIT(0);

@implementation XVimTestCase

+(NSOperationQueue *)keySendQueue
{
    if (_keySendQueue == nil) {
        _keySendQueue = [[NSOperationQueue alloc] init];
        _keySendDispatchQueue = dispatch_queue_create("XVimTestKeySendQueue", NULL);
        _keySendQueue.underlyingQueue = _keySendDispatchQueue;
        _keySendQueue.suspended = NO;
    }
    return _keySendQueue;
}

-(dispatch_queue_t)testCompletionDispatchQueue
{
    if (_testCompletionDispatchQueue == nil) {
        _auto val = atomic_fetch_add(&dispatchQueueCount, 1);
        _auto queue_name = [NSString stringWithFormat:@"XVimTestCompletionDispatchQueue%u", val];
        _testCompletionDispatchQueue = dispatch_queue_create(queue_name.UTF8String, NULL);
    }
    return _testCompletionDispatchQueue;
}

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                                    file:(NSString*)file
                                    line:(NSUInteger)line
{
    return [self testCaseWithInitialText:it
                            initialRange:ir
                                   input:in
                            expectedText:et
                           expectedRange:er
                             description:in
                                    file:file
                                    line:line];
}

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)it
                            initialRange:(NSRange)ir
                                   input:(NSString*)in
                            expectedText:(NSString*)et
                           expectedRange:(NSRange)er
                             description:(NSString*)desc
                                    file:(NSString*)file
                                    line:(NSUInteger)line

{
    XVimTestCase* test = [[XVimTestCase alloc] init];
    test.initialText = it;
    test.initialRange = ir;
    test.input = in;
    test.expectedText = et;
    test.expectedRange = er;
    test.message = @"";
    test.exception = NO;
    test.keyStrokesCount = 0;
    test.finished = NO;
    
    if (nil != desc) {
        test.desc = desc;
    }
    else {
        test.desc = in;
    }
    test.file = file;
    test.line = line;

    return test;
}


- (void)setUp
{
    [XVimLastActiveSourceView() xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    [XVimLastActiveSourceView() setString:self.initialText];
    [XVimLastActiveSourceView() setSelectedRange:self.initialRange];
}

- (BOOL)assert
{
    if (self.exception) {
        self.message = @"Exception raiesed.";
        return NO;
    }
    NSString * editorString = [XVimLastActiveSourceView() string];
    
    // Xcode9 ALWAYS adds an extra \n
    if (editorString.length
        && self.expectedText.length
        && [self.expectedText characterAtIndex:self.expectedText.length-1] != '\n')
    {
        editorString = [editorString substringToIndex:editorString.length-1];
    }
    self.actualText = editorString;
    
    if (![self.expectedText isEqualToString:editorString]) {
        self.message = [NSString stringWithFormat:@"Result text is different from expected text.\n[%@:%ld]\n",
                                                  self.file,
                                                  self.line];
        return NO;
    }

    NSRange resultRange = [XVimLastActiveSourceView() selectedRange];
    if (self.expectedRange.location != resultRange.location || self.expectedRange.length != resultRange.length) {
        self.message = [NSString
                    stringWithFormat:@"Result range(%lu,%lu) is different from expected range(%lu,%lu) [%@:%ld]",
                                     resultRange.location, resultRange.length, self.expectedRange.location,
                                     (unsigned long)self.expectedRange.length, self.file, self.line];
        return NO;
    }
    return YES;
}

- (void)executeInput
{
    NSString *notation = [self.input stringByAppendingString:@"<ESC>:mapclear<CR>"];
    NSArray* strokes = XVimKeyStrokesFromKeyNotation(notation);
    self.keySemaphore = dispatch_semaphore_create(0);
    self.keyStrokesCount = strokes.count;
    
    for (XVimKeyStroke* stroke in strokes) {
        [XVimTestCase.keySendQueue addOperationWithBlock:^{
                [NSOperationQueue.mainQueue addOperationWithBlock:^{
                    if (self.window == nil || !self.window.isVisible) {
                        dispatch_semaphore_signal(self.keySemaphore);
                        return;
                    }
                    @try {
                        NSEvent* event = [stroke toEventwithWindowNumber:self.window.windowNumber context:self.window.graphicsContext];
                        [self.window makeKeyAndOrderFront:self];
                        [NSApp sendEvent:event];
                        dispatch_semaphore_signal(self.keySemaphore);
                    }
                    @catch (NSException* ex) {
                        self.exception = YES;
                    }
                }];
            [NSThread sleepForTimeInterval:0.01];
        }];

        // Tells NSUndoManager to end grouping (Little hacky)
        // This is because the loop here emulates NSApplication's run loop.
        // To make NSUndoManager work properly we have to call this after each event
        // [NSUndoManager performSelector:@selector(_endTopLevelGroupings)];
    }
}

- (void)tearDown
{
    [XVimLastActiveSourceView().view display];
}

- (void)waitForCompletionWithConinuation:(void(^)(void))continuation
{
    if (self.keyStrokesCount == 0) {
        [NSOperationQueue.mainQueue addOperationWithBlock:continuation];
        return;
    }
    
    dispatch_async(self.testCompletionDispatchQueue, ^{
        dispatch_semaphore_wait(self.keySemaphore, DISPATCH_TIME_FOREVER);
        self.keyStrokesCount--;
        [self waitForCompletionWithConinuation:continuation];
    });
}

- (void)runInWindow:(NSWindow*)window withContinuation:(void(^)(void))continuation
{
    self.window = window;

    [self setUp];
    [self executeInput];
    
    [self waitForCompletionWithConinuation:^{
        self.finished = (self.window != nil && self.window.isVisible);
        self.success = self.finished && [self assert];
        [self tearDown];
        continuation();
    }];
}
@end
