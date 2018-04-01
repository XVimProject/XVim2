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
#import "IDEWorkspaceTabController+XVim.h"
#import "Logger.h"
#import "XVimAboutDialog.h"
#import "XVimExCommand.h"
#import "XVimHistoryHandler.h"
#import "XVimKeymap.h"
#import "XVimMarks.h"
#import "XVimOptions.h"
#import "XVimRegister.h"
#import "XVimSearch.h"
#import "XVimTester.h"
#import "_TtC12SourceEditor23SourceEditorContentView.h"
#import "_TtC15IDESourceEditor19IDESourceEditorView.h"
#import "XVimXcode.h"
#import "XVimIDEPegasusSourceEditorView.h"

@interface XVim () {
    XVimKeymap* _keymaps[XVIM_MODE_COUNT];
}
@property (strong, nonatomic) XVimMutableString* lastOperationCommands;
@property (strong, nonatomic) XVimMutableString* tempRepeatRegister;
@end

@implementation XVim

+ (void)pluginDidLoad:(NSBundle*)plugin
{
    NSArray* allowedLoaders = [plugin objectForInfoDictionaryKey:@"AllowedLoaders"];
    if ([allowedLoaders containsObject:[[NSBundle mainBundle] bundleIdentifier]]) {
        [self instance];
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
    [Logger defaultLogger].level = LogTrace;

    // Make a list of classes that will be swizzled, so we can check if they have been loaded
    // before swizzling. If not, we will wait, observing NSBundle's class load notifications,
    // until all of these classes have been loaded before swizzling.
    NSArray<NSString*>* swizzleClasses =
                @[ IDEPegasusSourceCodeEditorViewClassName, SourceEditorViewClassName, @"IDEWorkspaceTabController" ];

    NSMutableSet<NSString*>* requiredClassesWaitSet = [[NSMutableSet alloc] initWithArray:swizzleClasses];
    NSMutableSet<NSString*>* loadedClasses = [NSMutableSet new];

    // Remove already loaded classes from wait set
    for (NSString* className in requiredClassesWaitSet) {
        if (NSClassFromString(className))
            [loadedClasses addObject:className];
    }
    [requiredClassesWaitSet minusSet:loadedClasses];

    if (requiredClassesWaitSet.count == 0) {
        [self hookClasses];
    }
    else {
        // Entry Point of the Plugin.
        __weak Class weakXvim = self;
        [NSNotificationCenter.defaultCenter
                    addObserverForName:NSBundleDidLoadNotification
                                object:nil
                                 queue:nil
                            usingBlock:^(NSNotification* _Nonnull note) {
                                Class XVimClass = weakXvim;
                                NSArray<NSString*>* classes = [note.userInfo objectForKey:NSLoadedClasses];
                                if (classes && requiredClassesWaitSet.count > 0) {
                                    [requiredClassesWaitSet minusSet:[NSSet setWithArray:classes]];
                                    if (requiredClassesWaitSet.count == 0) {
                                        [XVimClass hookClasses];
                                    }
                                }
                            }];
    }
}

+ (void)hookClasses
{
    [XVimIDEPegasusSourceEditorView xvim_hook];
    [IDEWorkspaceTabController_XVim xvim_hook];
}

+ (XVim*)instance
{
    static XVim* __instance = nil;
    static dispatch_once_t __once;

    if (__instance == nil) {
        dispatch_once(&__once, ^{
            __instance = [[XVim alloc] init];
            [__instance instanceSetup];
        });
    }
    return __instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init
{
    if (self = [super init]) {
        _searchHistory = [[XVimHistoryHandler alloc] init];
        _searcher = [[XVimSearch alloc] init];
        _lastCharacterSearchMotion = nil;
        _marks = [[XVimMarks alloc] init];
        _testRunner = [[XVimTester alloc] init];
        self.excmd = [[XVimExCommand alloc] init];
        self.lastPlaybackRegister = nil;
        self.lastOperationCommands = [[XVimMutableString alloc] init];
        self.lastVisualPosition = XVimMakePosition(NSNotFound, NSNotFound);
        self.lastVisualSelectionBegin = XVimMakePosition(NSNotFound, NSNotFound);
        _registerManager = [[XVimRegisterManager alloc] init];
        _marks = [[XVimMarks alloc] init];
        self.tempRepeatRegister = [[XVimMutableString alloc] init];
        self.isRepeating = NO;
        self.isExecuting = NO;
        self.enabled = YES;
        self.foundRangesHidden = NO;
        self.options = [[XVimOptions alloc] init];
        [_options addObserver:self forKeyPath:@"debug" options:NSKeyValueObservingOptionNew context:nil];

        for (int i = 0; i < XVIM_MODE_COUNT; ++i) {
            _keymaps[i] = [[XVimKeymap alloc] init];
        }
        if (NSApp && !NSApp.mainMenu) {
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(applicationDidFinishLaunching:)
                                                         name:NSApplicationDidFinishLaunchingNotification
                                                       object:nil];
        }
        else {
            [self addMenuItem];
        }
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification*)note
{
    [self addMenuItem];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSApplicationDidFinishLaunchingNotification
                                                  object:nil];
}

- (void)instanceSetup { [self parseRcFile]; }

- (void)dealloc { [[NSNotificationCenter defaultCenter] removeObserver:self]; }


+ (NSString*)xvimrc
{
    NSString* homeDir = NSHomeDirectoryForUser(NSUserName());
    NSString* keymapPath = [homeDir stringByAppendingString:@"/.xvimrc"];
    return [[NSString alloc] initWithContentsOfFile:keymapPath encoding:NSUTF8StringEncoding error:NULL];
}

- (void)parseRcFile
{
    NSString* rc = [XVim xvimrc];
    for (NSString* string in [rc componentsSeparatedByString:@"\n"]) {
        [self.excmd executeCommand:[@":" stringByAppendingString:string] inWindow:nil];
    }
}

- (void)observeValueForKeyPath:(NSString*)keyPath
                          ofObject:(id)object
                            change:(NSDictionary*)change
                           context:(void*)context
{
    if ([keyPath isEqualToString:@"debug"]) {
        if ([[XVim instance] options].debug) {
            NSString* homeDir = NSHomeDirectoryForUser(NSUserName());
            NSString* logPath = [homeDir stringByAppendingString:@"/.xvimlog"];
            [[Logger defaultLogger] setLogFile:logPath];
        }
        else {
            [[Logger defaultLogger] setLogFile:nil];
        }
    }
}

// For reverse engineering purpose.
+ (void)receiveNotification:(NSNotification*)notification
{
    if ([notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"]) {
        TRACE_LOG(@"Got notification name : %@    object : %@", notification.name,
                  NSStringFromClass([[notification object] class]));
    }
}

static id _startupObservation = nil;
- (XVimKeymap*)keymapForMode:(XVIM_MODE)mode { return _keymaps[(int)mode]; }

- (void)appendOperationKeyStroke:(XVimString*)stroke { [self.tempRepeatRegister appendString:stroke]; }

- (void)fixOperationCommands
{
    if (!self.isRepeating) {
        [self.lastOperationCommands setString:self.tempRepeatRegister];
        [self.tempRepeatRegister setString:@""];
    }
}

- (void)cancelOperationCommands { [self.tempRepeatRegister setString:@""]; }

- (void)startRepeat { self.isRepeating = YES; }

- (void)endRepeat { self.isRepeating = NO; }

- (void)ringBell
{
    if (self.options.errorbells) {
        NSBeep();
    }
    return;
}

- (void)registerWindow:(XVimWindow*)win
{
    // DOES NOTHING, but ensures XVim Instance gets accessed
}

#pragma mark - Menu

- (void)addMenuItem
{
// It will fail in Xcode 6.4
// Check IDEApplicationController+Xvim.m

// Add XVim menu keybinding into keybind preference
#ifdef TODO
    IDEMenuKeyBindingSet* keyset = [(IDEKeyBindingPreferenceSet*)[[IDEKeyBindingPreferenceSet preferenceSetsManager]
                currentPreferenceSet] valueForKey:@"_menuKeyBindingSet"];
    IDEKeyboardShortcut* shortcut =
                [[IDEKeyboardShortcut alloc] initWithKeyEquivalent:@"x" modifierMask:NSCommandKeyMask | NSShiftKeyMask];
    IDEMenuKeyBinding* binding = [[IDEMenuKeyBinding alloc] initWithTitle:@"Enable"
                                                              parentTitle:@"XVim"
                                                                    group:@"XVim"
                                                                  actions:@[ @"toggleXVim:" ]
                                                        keyboardShortcuts:@[ shortcut ]];
    binding.commandIdentifier = XVIM_MENU_TOGGLE_IDENTIFIER; // This must be same as menu items's represented Object.
    [keyset insertObject:binding inKeyBindingsAtIndex:0];
#endif

    NSMenu* menu = [[NSApplication sharedApplication] menu];

    NSMenuItem* editorMenuItem = [menu itemWithTitle:@"Edit"];
    NSMenuItem* xvimMenuItem = [self xvimMenuItem];
    [editorMenuItem.submenu addItem:NSMenuItem.separatorItem];
    [editorMenuItem.submenu addItem:xvimMenuItem];
}


#define XVIM_MENU_TOGGLE_IDENTIFIER @"XVim.Enable";
- (NSMenuItem*)xvimMenuItem
{
    // Add XVim menu
    NSMenuItem* item = [[NSMenuItem alloc] init];
    item.title = @"XVim";
    NSMenu* m = [[NSMenu alloc] initWithTitle:@"XVim"];
    [item setSubmenu:m];

    {
        NSMenuItem* subitem = [[NSMenuItem alloc] init];
        subitem.title = @"Enable";
        [subitem setEnabled:YES];
        [subitem setState:NSOnState];
        subitem.target = [XVim instance];
        subitem.action = @selector(toggleXVim:);
        subitem.representedObject = XVIM_MENU_TOGGLE_IDENTIFIER;
        self.enabledMenuItem = subitem;
        [m addItem:subitem];
    }
    {
        NSMenuItem* subitem = [[NSMenuItem alloc] init];
        subitem.title = @"About XVim";
        [subitem setEnabled:YES];
        subitem.target = [XVim class];
        subitem.action = @selector(about:);
        [m addItem:subitem];
    }

    // Test cases
    if (self.options.debug) {
        // Add category sub menu
        NSMenuItem* subm = [[NSMenuItem alloc] init];
        subm.title = @"Test categories";

        // Create category menu
        NSMenu* cat_menu = [[NSMenu alloc] init];
        // Menu for run all test
        NSMenuItem* subitem = [[NSMenuItem alloc] init];
        subitem.title = @"All";
        subitem.target = [XVim instance];
        subitem.action = @selector(runTest:);
        [cat_menu addItem:subitem];
        [cat_menu addItem:[NSMenuItem separatorItem]];
        for (NSString* c in [[XVim instance].testRunner categories]) {
            subitem = [[NSMenuItem alloc] init];
            subitem.title = c;
            subitem.target = [XVim instance];
            subitem.action = @selector(runTest:);
            [subitem setEnabled:YES];
            [cat_menu addItem:subitem];
        }
        [m addItem:subm];
        [subm setSubmenu:cat_menu];
    }

    return item;
}


+ (void)about:(id)sender
{
    XVimAboutDialog* p = [[XVimAboutDialog alloc] initWithWindowNibName:@"about"];
    NSWindow* win = [p window];
    [[NSApplication sharedApplication] runModalForWindow:win];
}

- (void)enableXVim
{
    self.enabled = YES;
    self.enabledMenuItem.state = NSOnState;
    [self postEnabledChanged];
}
- (void)disableXVim
{
    self.enabled = NO;
    self.enabledMenuItem.state = NSOffState;
    [self postEnabledChanged];
}


- (void)postEnabledChanged
{
    [NSNotificationCenter.defaultCenter postNotificationName:XVimNotificationEnabled
                                                      object:self
                                                    userInfo:@{
                                                        XVimNotificationEnabledFlag : @(self.enabled)
                                                    }];
}

- (void)toggleXVim:(id)sender
{
    if (self.isEnabled) {
        [self disableXVim];
    }
    else {
        [self enableXVim];
    }
}


- (void)writeToConsole:(NSString*)fmt, ...
{
#ifdef TODO
    IDEDefaultDebugArea* debugArea = (IDEDefaultDebugArea*)[XVimLastActiveEditorArea() activeDebuggerArea];
    // On playgorund activateConsole call cause crash.
    if (![debugArea canActivateConsole]) {
        return;
    }
    [XVimLastActiveEditorArea() activateConsole:self];
    IDEConsoleArea* console = [debugArea consoleArea];

    // IDEConsoleArea has IDEConsoleTextView as its view but we do not have public method to access it.
    // It has the view as instance variable named "_consoleView"
    // So use obj-c runtime method to get instance varialbe by its name.
    IDEConsoleTextView* pView = [console valueForKey:@"_consoleView"];

    va_list argumentList;
    va_start(argumentList, fmt);
    NSString* string = [[NSString alloc] initWithFormat:fmt arguments:argumentList];
    pView.logMode = 1; // I do not know well about this value. But we have to set this to write text into the console.
    [pView insertText:string];
    [pView insertNewline:self];
    va_end(argumentList);
#endif
}

- (void)runTest:(id)sender
{
    NSMenuItem* m = sender;
    if ([m.title isEqualToString:@"All"]) {
        [self.testRunner selectCategories:self.testRunner.categories];
    }
    else {
        NSMutableArray* arr = [[NSMutableArray alloc] init];
        [arr addObject:m.title];
        [self.testRunner selectCategories:arr];
    }
    [self.testRunner runTest];
}


@end
