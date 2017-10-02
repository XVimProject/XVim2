//
//  _TtC22IDEPegasusSourceEditor20SourceCodeEditorView.m
//  XVim2
//
//  Created by Shuichiro Suzuki on 8/27/17.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"
#import "SourceCodeEditorViewProxy.h"
#import "NSObject+Swizzle.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimCmdArg.h"
#import <QuartzCore/QuartzCore.h>
#import "NSObject+ExtraData.h"

#define CONST_STR(_name) NSString *_name = @#_name ;

CONST_STR(EDLastEvent);
CONST_STR(EDMode);
CONST_STR(EDWindow);


@implementation _TtC22IDEPegasusSourceEditor20SourceCodeEditorView(XVim)
+ (void)xvim_hook{
    [self xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
    [self xvim_swizzleInstanceMethod:@selector(viewWillMoveToWindow:) with:@selector(xvim_viewWillMoveToWindow:)];
    
}

-(XVimWindow*)xvim_window {
    XVimWindow *w = [self extraDataForName:EDWindow];
    if (w == nil || (NSNull*)w == NSNull.null) {
        _auto p = [[SourceCodeEditorViewProxy alloc] initWithSourceCodeEditorView:self];
        w = [[XVimWindow alloc] initWithEditorView:p];
        [self setExtraData:w forName:EDWindow];
    }
    return w;
}

-(void)xvim_setupOnFirstAppearance
{
        [self.xvim_window setupAfterEditorViewSetup];
}

-(void)xvim_viewWillMoveToWindow:(id)window
{
    [self xvim_viewWillMoveToWindow:window];
    if (window != nil) {
        [NSOperationQueue.mainQueue addOperationWithBlock:^{
            [self xvim_setupOnFirstAppearance];
        }];
    }
}


- (NSMutableArray*)xvim_key_queue{
    NSMutableArray* obj;
    if( nil == (obj = [self extraDataForName:@"xvim_key_queue"]) ){
        obj = [NSMutableArray new];
        [self setExtraData:obj forName:@"xvim_key_queue"];
    }
    return obj;
}
- (CALayer*)xvim_cmd_layer{
    for (CALayer *layer in [self.layer sublayers]) {
        if ([[layer name] isEqualToString:@"xvim_cmd_layer"]) {
            return layer;
        }
    }
    CATextLayer* textLayer = [[CATextLayer alloc] init];
    [textLayer setName:@"xvim_cmd_layer"];
    [self.layer addSublayer:textLayer];
    
    return textLayer;
}

- (void)xvim_keyDown:(NSEvent*)event{
    [self setExtraData:event forName:EDLastEvent];
    [self.xvim_key_queue addObject:[event toXVimKeyStroke]];
    if (![self.xvim_window handleKeyEvent:event])
        [self xvim_keyDown:event];

}

- (void)xvim_updateCommandLine:(XVimCmdArg*)arg{
    CATextLayer* cmd = (CATextLayer*)[self xvim_cmd_layer];
    if( arg.args.length == 0 ){
        [cmd setHidden:YES];
        return;
    }
    [cmd setHidden:NO];
    [cmd setString:arg.args];
    CGRect rect = self.frame;
    rect.origin.y = rect.size.height - 20;
    rect.size.height = 20;
    [cmd setFrame: rect];
    cmd.foregroundColor = [NSColor blackColor].CGColor;
    cmd.backgroundColor = [NSColor colorWithRed:0 green:0 blue:0 alpha:0.2].CGColor;
    cmd.fontSize = 16.0;
    
}
@end

