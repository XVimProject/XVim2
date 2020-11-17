//
//  XVimIDESourceEditorView.m
//  XVim2
//
//  Created by pebble8888 on 2018/03/31.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#import "XVimIDESourceEditorView.h"

#import "_TtC15IDESourceEditor19IDESourceEditorView+XVim.h"
#import <SourceEditor/_TtC12SourceEditor16SourceEditorView.h>
#import "Logger.h"
#import "NSObject+ExtraData.h"
#import "NSObject+Swizzle.h"
#import "SourceEditorViewProxy.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimOptions.h"
#import <QuartzCore/QuartzCore.h>

#import "NSObject+ExtraData.h"
#import <IDEKit/IDEEditorArea.h>
#import <IDEKit/IDEEditorContext.h>
#import <IDEKit/IDEEditorDocument.h>
#import "XVimTaskRunner.h"
#import "NSString+Util.h"
#import "XVimXcode.h"
#import "XcodeUtils.h"
#import "NSView+ViewRecursion.h"

CONST_STR(EDLastEvent);
CONST_STR(EDMode);
CONST_STR(EDWindow);

#define SELF ((_TtC15IDESourceEditor19IDESourceEditorView*)self)

@implementation XVimIDESourceEditorView

+ (void)xvim_hook
{
    [XVimIDESourceEditorView
     xvim_swizzleInstanceMethodOfClassName: SourceEditorViewClassName
     selector:@selector(keyDown:)
     with:@selector(xvim_keyDown:)];
    [XVimIDESourceEditorView
     xvim_swizzleInstanceMethodOfClassName: IDESourceEditorViewClassName
     selector:@selector(viewWillMoveToWindow:)
     with:@selector(xvim_viewWillMoveToWindow:)];
    [XVimIDESourceEditorView
     xvim_swizzleInstanceMethodOfClassName:IDESourceEditorViewClassName
     selector:@selector(scrollRangeToVisible:)
     with:@selector(xvim_scrollRangeToVisible:)];
    
    [XVimIDESourceEditorView xvim_addInstanceMethod: @selector(xvim_window)
         toClassName:IDESourceEditorViewClassName];
    [XVimIDESourceEditorView xvim_addInstanceMethod: @selector(xvim_setupOnFirstAppearance)
         toClassName:IDESourceEditorViewClassName];
    [XVimIDESourceEditorView xvim_addInstanceMethod: @selector(xvim_setupRelativeNumbers)
         toClassName:IDESourceEditorViewClassName];
    
}



- (void)xvim_scrollRangeToVisible:(NSRange)range
{
    if (self.xvim_window != nil && self.xvim_window.scrollHalt){
        // skip to prevent crash in Xcode9.3
    } else {
        [self xvim_scrollRangeToVisible:range];
    }
    [self xvim_setupRelativeNumbers];
}

- (void)xvim_viewWillMoveToWindow:(id)window
{
    [self xvim_viewWillMoveToWindow:window];
    if (window != nil) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self xvim_setupOnFirstAppearance];
        }];
    }
}

- (void)xvim_keyDown:(NSEvent*)event
{
    if (![self respondsToSelector:@selector(xvim_window)] ||
        ![self.xvim_window handleKeyEvent:event]){
        [self xvim_keyDown:event];
    }
}

- (void)xvim_setupOnFirstAppearance
{
    [self.xvim_window setupAfterEditorViewSetup];
}

- (XVimWindow*)xvim_window
{
    XVimWindow* w = [self extraDataForName:EDWindow];
    if ((w == nil || (NSNull*)w == NSNull.null)
            && [self.class isEqual:NSClassFromString(IDESourceEditorViewClassName)]) {
        let p = [[SourceEditorViewProxy alloc] initWithSourceEditorView:SELF];
        w = [[XVimWindow alloc] initWithSourceView:p];
        [self setExtraData:w forName:EDWindow];
    }
    return w;
}

- (void)xvim_setupRelativeNumbers
{
    if (!XVim.instance.options.relativenumber) return;
    NSView *this = (NSView *) self;
    NSArray *subviews = [this allSubViews];
    NSView *gutterMarginContentView;
    for (NSView *v in subviews) {
        if ([[v className] isEqualToString:@"SourceEditor.SourceEditorGutterMarginContentView"]) {
            gutterMarginContentView = v;
            break;
        }
    }
    
    if (gutterMarginContentView == nil) return;
    
    long pos = [[self.xvim_window currentPositionMark] line];
    long numberOfLines = [self.xvim_window numberOfLines];

    CALayer *superLayer;
    for (CALayer *layer in [gutterMarginContentView.layer sublayers]) {
        if ([[layer className] containsString:@"LineNumbersHostingLayer"]) {
            superLayer = layer;
            break;
        }
    }
    if (superLayer == nil) return;
    
    CGRect referenceFrame = [[[superLayer sublayers] firstObject] frame];
    referenceFrame.size.width = referenceFrame.size.width + referenceFrame.origin.x;

    NSMutableArray *relativeLayers = [[NSMutableArray alloc] initWithCapacity:numberOfLines];
    NSArray *numberLayers = [superLayer sublayers];
    for (long i = [numberLayers count] - 1; i >= 0; i--) {
        CALayer *layer = [numberLayers objectAtIndex:i];
        CGRect frame = [layer frame];
        frame.size.width = referenceFrame.size.width;
        frame.origin.x = 0;
        NSUInteger currentNumber = (frame.origin.y - 4) / (frame.size.height + 5) + 1; // 4 = first top padding, 5 = padding between numbers
        NSUInteger relativeLineNumber = (NSUInteger)llabs(((long long)currentNumber - pos));
        NSString *text = [NSString stringWithFormat: @"%ld", relativeLineNumber];
        
        CATextLayer *label = [[CATextLayer alloc] init];
        [label setFont:@"SFMono-Medium"];
        [label setFontSize:11];
        [label setFrame:frame];
        [label setString:text];
        [label setAlignmentMode:kCAAlignmentRight];
        [label setForegroundColor: [[NSColor colorWithWhite:0.7 alpha:1.0] CGColor]];
        [relativeLayers addObject:label];
        
        [layer removeFromSuperlayer];
    }
    
    for (CALayer *layer in relativeLayers) {
        [superLayer addSublayer:layer];
    }
}

@end
