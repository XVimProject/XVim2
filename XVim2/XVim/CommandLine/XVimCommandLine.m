//
//  XVimCommandLine.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandLine.h"
#import "XVimCommandField.h"
//#import "XVimQuickFixView.h"
#import "Logger.h"
#import "NSAttributedString+Geometrics.h"
#import "XVimWindow.h"
#import <DVTKit/DVTFontAndColorTheme.h>
#import <objc/runtime.h>

@interface XVimCommandLine () {
@private
    XVimCommandField* _command;
    NSTextField* _static;
    NSTextField* _error;
    NSTextField* _argument;

    // TODO: XVimQuickFixView* _quickFixScrollView;
    id _quickFixObservation;
    NSTimer* _errorTimer;
    DVTFontAndColorTheme* _theme;
}
@end

@implementation XVimCommandLine

static const BOOL UseLayers = NO;

- (id)init
{
    self = [super init];
    if (self) {
        _theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
        NSEdgeInsets insets = NSEdgeInsetsMake(3.0, 3.0, 3.0, 3.0);

        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.wantsLayer = UseLayers;
        self.blendingMode = NSVisualEffectBlendingModeWithinWindow;
        if (_theme.hasLightBackground){
            self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
        } else {
            self.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantDark];
        }

        // Static Message ( This is behind the command view if the command is active)
        _static = [NSTextField labelWithString:@""];
        _static.wantsLayer = UseLayers;
        _static.drawsBackground = NO;
        [_static setEditable:NO];
        [_static setSelectable:NO];
        //[_static setBackgroundColor:[NSColor clearColor]];
        [_static setHidden:NO];
        [_static setBordered:NO];
        [_static setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self addSubview:_static];

        //[self.widthAnchor constraintEqualToAnchor:_static.widthAnchor multiplier:1.0].active = YES;
        [self.leftAnchor constraintEqualToAnchor:_static.leftAnchor constant:-insets.left].active = YES;
        [self.rightAnchor constraintEqualToAnchor:_static.rightAnchor constant:insets.right].active = YES;
        [self.bottomAnchor constraintEqualToAnchor:_static.bottomAnchor constant:insets.bottom].active
                    = YES;


        // Error Message
        _error = [NSTextField labelWithString:@""];
        _error.wantsLayer = UseLayers;
        [_error setEditable:NO];
        [_error setSelectable:NO];
        [_error setBackgroundColor:[NSColor redColor]];
        [_error setHidden:YES];
        [_error setBordered:NO];
        [_error setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self addSubview:_error];

        //[self.widthAnchor constraintEqualToAnchor:_error.widthAnchor multiplier:1.0].active = YES;
        [self.leftAnchor constraintEqualToAnchor:_error.leftAnchor constant:-insets.left].active = YES;
        [self.rightAnchor constraintEqualToAnchor:_error.rightAnchor constant:insets.right].active = YES;
        [self.bottomAnchor constraintEqualToAnchor:_error.bottomAnchor constant:insets.bottom].active
                    = YES;


#ifdef TODO
        // TODO: QuickFix view(height) doesn't show properly now
        // Quickfix View
        _quickFixScrollView = [[XVimQuickFixView alloc] init];
        [_quickFixScrollView setHidden:YES];
        [_quickFixScrollView setTranslatesAutoresizingMaskIntoConstraints:NO];
        // Width
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeWidth
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeWidth
                                                        multiplier:1.0
                                                          constant:0.0]];
        // Left edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeLeft
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeLeft
                                                        multiplier:1.0
                                                          constant:0.0]];
        // Top edge
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeTop
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeTop
                                                        multiplier:1.0
                                                          constant:0.0]];
        // Bottom edge (Superview's bottom is greater than _command bottom)
        [self addConstraint:[NSLayoutConstraint constraintWithItem:_quickFixScrollView
                                                         attribute:NSLayoutAttributeBottom
                                                         relatedBy:NSLayoutRelationEqual
                                                            toItem:self
                                                         attribute:NSLayoutAttributeBottom
                                                        multiplier:1.0
                                                          constant:0.0]];
        [self addSubview:_quickFixScrollView];
#endif

        // Command View
        _command = [[XVimCommandField alloc] init];
        _command.wantsLayer = UseLayers;
        _command.drawsBackground = YES;
        [_command setEditable:NO];
        [_command setSelectable:NO];
        [_command setHidden:YES];
        [_command setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self addSubview:_command];

        //[self.widthAnchor constraintEqualToAnchor:_command.widthAnchor multiplier:1.0].active = YES;
        [self.leftAnchor constraintEqualToAnchor:_command.leftAnchor constant:-insets.left].active = YES;
        [self.rightAnchor constraintEqualToAnchor:_command.rightAnchor constant:insets.right].active = YES;
        [self.bottomAnchor constraintEqualToAnchor:_command.bottomAnchor constant:insets.bottom].active
                    = YES;


        // Argument View
        _argument = [NSTextField labelWithString:@""];
        _argument.wantsLayer = UseLayers;
        _command.drawsBackground = NO;
        [_argument setEditable:NO];
        [_argument setSelectable:NO];
        //[_argument setBackgroundColor:[NSColor clearColor]];
        [_argument setHidden:NO];
        [_argument setBordered:NO];
        // TODO: Text alignment here doesn't work as I expected.
        // I want to show the latest input even when the argument string exceeds the max width of the field
        // but now it only shows head of arguments
        [_argument setAlignment:NSTextAlignmentRight]; //
        [_argument setTranslatesAutoresizingMaskIntoConstraints:NO];

        [self addSubview:_argument];

        //[self.widthAnchor constraintEqualToAnchor:_argument.widthAnchor multiplier:1.0].active = YES;
        [self.leftAnchor constraintEqualToAnchor:_argument.leftAnchor constant:-insets.left].active = YES;
        [self.rightAnchor constraintEqualToAnchor:_argument.rightAnchor constant:insets.right].active = YES;
        [self.bottomAnchor constraintEqualToAnchor:_argument.bottomAnchor constant:insets.bottom].active
                    = YES;

        

    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    // set any NSColor for filling, say white:
    [[theme sourceTextBackgroundColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"DVTFontAndColorSourceTextSettingsChangedNotification"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:_quickFixObservation];
}

- (void)errorMsgExpired { [_error setHidden:YES]; }

- (void)setModeString:(NSString*)string { [_static setStringValue:string]; }

- (void)setArgumentString:(NSString*)string
{
    if (nil != string) {
        [_argument setStringValue:string];
    }
}

-(void)setModeHidden:(BOOL)modeHidden {
    _static.hidden = modeHidden;
}
-(BOOL)isModeHidden {
    return _static.hidden;
}

/**
 * (BOOL)aRedColorSetting
 *      YES: red color background
 *      NO : default color background
 */
- (void)errorMessage:(NSString*)string Timer:(BOOL)aTimer RedColorSetting:(BOOL)aRedColorSetting
{
    DVTFontAndColorTheme* theme = [NSClassFromString(@"DVTFontAndColorTheme") performSelector:@selector(currentTheme)];
    if (aRedColorSetting) {
        _error.backgroundColor = [NSColor redColor];
    }
    else {
        _error.backgroundColor = [theme sourceTextBackgroundColor];
    }
    NSString* msg = string;
    if ([msg length] != 0) {
        [_error setStringValue:msg];
        [_error setHidden:NO];
        [_errorTimer invalidate];
        if (aTimer) {

            _errorTimer = [NSTimer timerWithTimeInterval:3.0
                                                  target:self
                                                selector:@selector(errorMsgExpired)
                                                userInfo:nil
                                                 repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:_errorTimer forMode:NSDefaultRunLoopMode];
        }
    }
    else {
        [_errorTimer invalidate];
        [_error setHidden:YES];
    }
}

#ifdef TODO

static NSString* QuickFixPrompt = @"\nPress a key to continue...";

- (void)quickFixWithString:(NSString*)string completionHandler:(void (^)(void))completionHandler
{
    if (string && [string length] != 0) {
        // Set up observation to close the quickfix window when a key is pressed, or it loses focus
        __weak XVimCommandLine* this = self;
        void (^completionHandlerCopy)(void) = [completionHandler copy];
        _quickFixObservation = [[NSNotificationCenter defaultCenter]
                    addObserverForName:XVimNotificationQuickFixDidComplete
                                object:_quickFixScrollView
                                 queue:nil
                            usingBlock:^(NSNotification* note) {
                                [this quickFixWithString:nil completionHandler:completionHandlerCopy];
                            }];
        [_quickFixScrollView setString:string withPrompt:QuickFixPrompt];
        [_quickFixScrollView setHidden:NO];
        [[_quickFixScrollView window] performSelector:@selector(makeFirstResponder:)
                                           withObject:_quickFixScrollView.textView
                                           afterDelay:0];
        [_quickFixScrollView.textView performSelector:@selector(scrollToEndOfDocument:) withObject:self afterDelay:0];
    }
    else {
        [[NSNotificationCenter defaultCenter] removeObserver:_quickFixObservation];
        [_quickFixScrollView setString:@"" withPrompt:@""];
        _quickFixObservation = nil;
        [_quickFixScrollView setHidden:YES];
        if (completionHandler) {
            completionHandler();
        }
    }
}

- (NSUInteger)quickFixColWidth { return _quickFixScrollView.colWidth; }
#endif

- (XVimCommandField*)commandField { return _command; }


@end
