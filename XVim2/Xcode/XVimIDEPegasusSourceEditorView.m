//
//  XVimIDEPegasusSourceEditorView.m
//  XVim2
//
//  Created by pebble8888 on 2018/03/31.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#import "XVimIDEPegasusSourceEditorView.h"

#import "_TtC15IDESourceEditor19IDESourceEditorView.h"
#import "_TtC15IDESourceEditor19IDESourceEditorView+XVim.h"
#import "_TtC12SourceEditor16SourceEditorView.h"
#import "Logger.h"
#import "NSObject+ExtraData.h"
#import "NSObject+Swizzle.h"
#import "SourceCodeEditorViewProxy.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import <QuartzCore/QuartzCore.h>

#import "NSObject+ExtraData.h"
#import "IDEEditorArea.h"
#import "IDEEditorContext.h"
#import "IDEEditorDocument.h"
#import "XVimTaskRunner.h"
#import "StringUtil.h"
#import "XVimXcode.h"
#import "XcodeUtils.h"

CONST_STR(EDLastEvent);
CONST_STR(EDMode);
CONST_STR(EDWindow);

#define SELF ((_TtC15IDESourceEditor19IDESourceEditorView*)self)

@implementation XVimIDEPegasusSourceEditorView

+(void)xvim_hook
{
    [XVimIDEPegasusSourceEditorView
     xvim_swizzleInstanceMethodOfClassName: SourceEditorViewClassName
     selector:@selector(keyDown:)
     with:@selector(xvim_keyDown:)];
    [XVimIDEPegasusSourceEditorView
     xvim_swizzleInstanceMethodOfClassName: IDEPegasusSourceCodeEditorViewClassName
     selector:@selector(viewWillMoveToWindow:)
     with:@selector(xvim_viewWillMoveToWindow:)];
    [XVimIDEPegasusSourceEditorView
     xvim_swizzleInstanceMethodOfClassName:IDEPegasusSourceCodeEditorViewClassName
     selector:@selector(scrollRangeToVisible:)
     with:@selector(xvim_scrollRangeToVisible:)];
    
    [XVimIDEPegasusSourceEditorView xvim_addInstanceMethod:@selector(xvim_window)
         toClassName:IDEPegasusSourceCodeEditorViewClassName];
    [XVimIDEPegasusSourceEditorView xvim_addInstanceMethod: @selector(xvim_setupOnFirstAppearance)
         toClassName:IDEPegasusSourceCodeEditorViewClassName];
    
}

- (void)xvim_scrollRangeToVisible:(NSRange)range
{
    if (self.xvim_window != nil && self.xvim_window.scrollHalt){
        // skip to prevent crash in Xcode9.3
    } else {
        [self xvim_scrollRangeToVisible:range];
    }
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
    // <TODO>temporary code until bang implementation
    if (([event modifierFlags] & NSEventModifierFlagControl /* NSControlKeyMask*/) && event.keyCode == 16 /* y */)
    {
        // Ctrl-y
        NSURL* documentURL = self.xvim_window.sourceView.documentURL;
        NSString* filepath = documentURL.path;
        if (filepath != nil){
            NSUInteger pos = self.xvim_window.sourceView.insertionPoint;
            NSUInteger linenumber = [StringUtil lineWithPath:filepath pos:pos];
            // use `brew install macvim`
            NSString* str = [NSString stringWithFormat:@"/usr/local/bin/mvim +%ld %@", linenumber, filepath];
            [XVimTaskRunner runScript:str];
        }
    }
    // </TODO>
    
    if (![self.xvim_window handleKeyEvent:event])
        [self xvim_keyDown:event];
}


// ADDED
- (void)xvim_setupOnFirstAppearance
{
    [self.xvim_window setupAfterEditorViewSetup];
    
}


- (XVimWindow*)xvim_window
{
    XVimWindow* w = [self extraDataForName:EDWindow];
    if (w == nil || (NSNull*)w == NSNull.null) {
        _auto p = [[SourceCodeEditorViewProxy alloc] initWithSourceCodeEditorView:SELF];
        w = [[XVimWindow alloc] initWithEditorView:p];
        [self setExtraData:w forName:EDWindow];
    }
    return w;
}


@end

