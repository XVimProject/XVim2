//
//  _TtC22IDEPegasusSourceEditor20SourceCodeEditorView.m
//  XVim2
//
//  Created by Shuichiro Suzuki on 8/27/17.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"
#import "_TtC12SourceEditor16SourceEditorView.h"
#import "Logger.h"
#import "NSObject+ExtraData.h"
#import "NSObject+Swizzle.h"
#import "SourceCodeEditorViewProxy.h"
#import "XVimCmdArg.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import <QuartzCore/QuartzCore.h>
#import <SourceEditor/SourceEditorScrollView.h>


CONST_STR(EDLastEvent);
CONST_STR(EDMode);
CONST_STR(EDWindow);

#define SELF ((_TtC22IDEPegasusSourceEditor20SourceCodeEditorView*)self)

@implementation XVimIDEPegasusSourceEditorView

+(void)xvim_hook
{
    [XVimIDEPegasusSourceEditorView xvim_swizzleInstanceMethodOfClassName:SourceEditorViewClassName
                                                                 selector:@selector(keyDown:)
                                                                     with:@selector(xvim_keyDown:)];
    [XVimIDEPegasusSourceEditorView xvim_swizzleInstanceMethodOfClassName:IDEPegasusSourceCodeEditorViewClassName
                                                                 selector:@selector(viewWillMoveToWindow:)
                                                                     with:@selector(xvim_viewWillMoveToWindow:)];
    [XVimIDEPegasusSourceEditorView xvim_swizzleInstanceMethodOfClassName:IDEPegasusSourceCodeEditorViewClassName
                                                                 selector:@selector(selectionWillChange)
                                                                     with:@selector(xvim_selectionWillChange)];
    [XVimIDEPegasusSourceEditorView xvim_addInstanceMethod:@selector(xvim_window)
                                               toClassName:IDEPegasusSourceCodeEditorClassName];
    [XVimIDEPegasusSourceEditorView xvim_addInstanceMethod:@selector(xvim_setupOnFirstAppearance)
                                               toClassName:IDEPegasusSourceCodeEditorClassName];

}

// SWIZZLED
- (void)xvim_selectionWillChange
{
    DEBUG_LOG(@"SELECTION WILL CHANGE");
    [self xvim_selectionWillChange];
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
    if (![self.xvim_window handleKeyEvent:event])
        [self xvim_keyDown:event];
}


// ADDED
- (void)xvim_setupOnFirstAppearance
{
    [self.xvim_window setupAfterEditorViewSetup];
    SourceEditorScrollView* scrollView = SELF.scrollView;
    
    // Add inset at bottom for XVim command line
    if ([scrollView isKindOfClass:NSClassFromString(@"SourceEditorScrollView")]) {
        // TODO: Don't hardwire insets
        NSEdgeInsets insets = scrollView.additionalContentInsets;
        insets.bottom += 20;
        scrollView.additionalContentInsets = insets;
        [scrollView updateAutomaticContentInsets];
    }
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
