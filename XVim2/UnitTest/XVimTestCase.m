//
//  XVimTestCase.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import "XVimTestCase.h"
#import "Logger.h"
#import "SourceEditorViewProxy.h"
#import "SourceEditorViewProxy+XVim.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XcodeUtils.h"
#import <stdatomic.h>


@interface XVimTestCase()
@property (class, readonly) NSOperationQueue * keySendQueue;
@property (weak) NSWindow * window;
@property dispatch_group_t group;
@property (readonly) dispatch_queue_t testCompletionDispatchQueue;
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
        let val = atomic_fetch_add(&dispatchQueueCount, 1);
        let queue_name = [NSString stringWithFormat:@"XVimTestCompletionDispatchQueue%u", val];
        _testCompletionDispatchQueue = dispatch_queue_create(queue_name.UTF8String, NULL);
    }
    return _testCompletionDispatchQueue;
}

+ (XVimTestCase*)testCaseWithInitialText:(NSString*)initialText
                                        :(NSRange)initialRange
                                        :(NSString*)inputText
                                        :(NSString*)expectedText
                                        :(NSRange)expectedRange
                                        :(NSString*)file
                                        :(NSUInteger)line

{
    XVimTestCase* test = [[XVimTestCase alloc] init];
    test.initialText = initialText;
    test.initialRange = initialRange;
    test.inputText = inputText;
    test.expectedText = expectedText;
    test.expectedRange = expectedRange;
    test.message = @"";
    test.exception = NO;
    test.finished = NO;
    test.desc = inputText;
    test.file = file;
    test.line = line;
    test.group = dispatch_group_create();
    return test;
}

- (void)setUp
{
    [XVimLastActiveSourceView() xvim_changeSelectionMode:XVIM_VISUAL_NONE];
    // in some case, setString:@"" will be ignored.
    // this selectAll then delete pair is workaround to remove all strings before set initial string.
    [XVimLastActiveSourceView() selectAll:nil];
    [XVimLastActiveSourceView() delete:nil];
    [XVimLastActiveSourceView() setString:self.initialText];
    [XVimLastActiveSourceView() setSelectedRange:self.initialRange];
}

- (BOOL)assert
{
    if (self.exception) {
        self.message = @"Exception raiesed.";
        return NO;
    }
    NSString * editorString = XVimLastActiveSourceView().string;
    
    // Xcode9 ALWAYS adds an extra \n
    if (editorString.length
        && self.expectedText.length
        && [self.expectedText characterAtIndex:self.expectedText.length-1] != '\n')
    {
        editorString = [editorString substringToIndex:editorString.length-1];
    }
    self.actualText = editorString;
    
    if (![self.expectedText isEqualToString:editorString]) {
        self.message = [NSString stringWithFormat:@"Result text is different from expected text. %@:%ld\n",
                                                  self.file, self.line];
        return NO;
    }

    NSRange resultRange = XVimLastActiveSourceView().selectedRange;
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
    NSString *notation = [self.inputText stringByAppendingString:@"<ESC>:mapclear<CR>"];
    NSArray* strokes = XVimKeyStrokesFromKeyNotation(notation);

    for (XVimKeyStroke* stroke in strokes) {
        dispatch_group_enter(self.group);
        [XVimTestCase.keySendQueue addOperationWithBlock:^{
            [NSOperationQueue.mainQueue addOperationWithBlock:^{
                if (self.window == nil || !self.window.isVisible) {
                    dispatch_group_leave(self.group);
                    return;
                }
                @try {
                    NSEvent* event = [stroke toEventwithWindowNumber:self.window.windowNumber
                                                             context:self.window.graphicsContext];
                    [self.window makeKeyAndOrderFront:self];
                    [NSApp sendEvent:event];
                    dispatch_group_leave(self.group);
                }
                @catch (NSException* ex) {
                    self.exception = YES;
                    dispatch_group_leave(self.group);
                }
                [NSThread sleepForTimeInterval:0.01];
            }];
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
    dispatch_async(self.testCompletionDispatchQueue, ^{
        dispatch_group_wait(self.group, DISPATCH_TIME_FOREVER);
        [NSOperationQueue.mainQueue addOperationWithBlock:continuation];
    });
}

- (void)runInWindow:(NSWindow*)window withContinuation:(void(^)(void))continuation
{
    UNIT_TEST_LOG(@"testing case: %@", self.desc);
    self.window = window;

    [self setUp];
    [self executeInput];
    
    [self waitForCompletionWithConinuation:^{
        self.finished = (self.window != nil && self.window.isVisible);
        self.success = self.finished && self.assert;
        [self tearDown];
        continuation();
    }];
}

- (BOOL)isFinishedAndFailed
{
	return _finished && !_success;
}

- (NSString *)resultDescription
{
	return _finished ? (_success ? @"Pass" : @"Fail") : @"Cancelled";
}

- (NSString *)description
{
	NSMutableString* s = [NSMutableString string];;
	[s appendString:_desc];
	[s appendString:@" "];
	[s appendString:self.resultDescription];
	[s appendString:@" "];
	[s appendString:self.message];
	[s appendString:@" "];	
	[s appendFormat:@"'%@'", _expectedText];
	[s appendString:@" "];		
	[s appendFormat:@"'%@'", _actualText];
	return s;
}

@end
