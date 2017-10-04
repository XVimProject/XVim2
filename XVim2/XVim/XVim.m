//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

// This is the main class of XVim
// The main role of XVim class is followings.
//    - create hooks.
//    - provide methods used by all over the XVim features.
//
// Hooks:
// The plugin entry point is "load" but does little thing.
// The important method after that is hook method.
// In this method we create hooks necessary for XVim initializing.
// The most important hook is hook for IDEEditorArea and DVTSourceTextView.
// These hook setup command line and intercept key input to the editors.
//
// Methods:
// XVim is a singleton instance and holds objects which can be used by all the features in XVim.
// See the implementation to know what kind of objects it has. They are not difficult to understand.
//

#import "XVim.h"
#import "XVimKeymap.h"
#import "XVimRegister.h"
#import "XVimPreferences.h"
#import "XVimMarks.h"
#import "Logger.h"
#import "_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"

@interface XVim () {
        XVimKeymap* _keymaps[XVIM_MODE_COUNT];
}
@property (strong, nonatomic) XVimMutableString* lastOperationCommands;
@property (strong, nonatomic) XVimMutableString* tempRepeatRegister;
@end

@implementation XVim


// For reverse engineering purpose.
+ (void)receiveNotification:(NSNotification*)notification
{
        if ([notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"]) {
                TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
        }
}

+ (void)load
{
        NSBundle* app = [NSBundle mainBundle];
        NSString* identifier = [app bundleIdentifier];

        // Load only into Xcode
        if (![identifier isEqualToString:@"com.apple.dt.Xcode"]) {
                return;
        }

        // Entry Point of the Plugin.
        [Logger defaultLogger].level = LogTrace;

        [_TtC22IDEPegasusSourceEditor20SourceCodeEditorView xvim_hook];
}

+ (XVim*)instance
{
        static XVim* __instance = nil;
        static dispatch_once_t __once;

        dispatch_once(&__once, ^{
          // Allocate singleton instance
          __instance = [[XVim alloc] init];
        });
        return __instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init
{
        if (self = [super init]) {
                _lastCharacterSearchMotion = nil;
                self.lastPlaybackRegister = nil;
                self.lastOperationCommands = [[XVimMutableString alloc] init];
                self.lastVisualPosition = XVimMakePosition(NSNotFound, NSNotFound);
                self.lastVisualSelectionBegin = XVimMakePosition(NSNotFound, NSNotFound);
                _registerManager = [[XVimRegisterManager alloc] init];
                _marks = [[XVimMarks alloc] init];
                self.tempRepeatRegister = [[XVimMutableString alloc] init];
                self.isRepeating = NO;
                self.isExecuting = NO;
                self.foundRangesHidden = NO;
                self.options = @{
                        XVimPref_AlwaysUseInputSource : @NO,
                        XVimPref_Timeout : @(2000),
                        XVimPref_ExpandTab : @YES
                };

                for (int i = 0; i < XVIM_MODE_COUNT; ++i) {
                        _keymaps[i] = [[XVimKeymap alloc] init];
                }
        }
        return self;
}

- (void)dealloc
{
        [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (XVimKeymap*)keymapForMode:(XVIM_MODE)mode
{
        return _keymaps[(int)mode];
}

- (void)appendOperationKeyStroke:(XVimString*)stroke
{
        [self.tempRepeatRegister appendString:stroke];
}

- (void)fixOperationCommands
{
        if (!self.isRepeating) {
                [self.lastOperationCommands setString:self.tempRepeatRegister];
                [self.tempRepeatRegister setString:@""];
        }
}

- (void)cancelOperationCommands
{
        [self.tempRepeatRegister setString:@""];
}

- (void)startRepeat
{
        self.isRepeating = YES;
}

- (void)endRepeat
{
        self.isRepeating = NO;
}

- (void)ringBell
{

        return;
}


@end
