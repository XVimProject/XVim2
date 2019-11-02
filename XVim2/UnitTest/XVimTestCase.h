//
//  XVimTestCase.h
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import <AppKit/AppKit.h>

#define XVimMakeTestCase(initialText, initialRangeLoc, initialRangeLen, \
    inputText, expectedText, expectedRangeLoc, expectedrangeLen) \
    [XVimTestCase testCaseWithInitialText:initialText \
        :NSMakeRange(initialRangeLoc, initialRangeLen) :inputText :expectedText \
        :NSMakeRange(expectedRangeLoc, expectedrangeLen) \
        :[NSString stringWithUTF8String:__FILE__] :__LINE__]

@interface XVimTestCase : NSObject
@property NSString* initialText;
@property NSRange initialRange;
@property NSString* inputText;
@property NSString* expectedText;
@property NSString* actualText;
@property NSRange expectedRange;
@property NSString* desc; // description is declared in NSObject and readonly.
@property NSString* message;
@property BOOL success;
@property BOOL exception;
@property BOOL finished;
@property NSString* file;
@property NSUInteger line;
@property (readonly) BOOL isFinishedAndFailed;
@property (readonly) NSString* resultDescription;
+ (XVimTestCase*)testCaseWithInitialText:(NSString*)initialText
                                        :(NSRange)initialRange
                                        :(NSString*)inputText
                                        :(NSString*)expectedText
                                        :(NSRange)expectedRange
                                        :(NSString*)file
                                        :(NSUInteger)line;
- (void)runInWindow:(NSWindow*)window withContinuation:(void(^)(void))continuation;
@end
