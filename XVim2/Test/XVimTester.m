//
//  XVimTest.m
//  XVim
//
//  Created by Suzuki Shuichiro on 8/18/12.
//
//

#import "XVimTester.h"
#import "Logger.h"
#import "SourceCodeEditorViewProxy.h"
#import "XVimKeyStroke.h"
#import "XVimTestCase.h"
#import "XcodeUtils.h"
#import <IDEKit/IDEEditorCoordinator.h>
#import <objc/runtime.h>

/**
 * How to run test:
 *
 * 1 Write following line in .xvimrc (This makes Run Test menu command appeard)
 *     set debug
 *
 * 2 Set forcus on text source view
 *
 * 3 Select menu [XVim]-[Run Test] and follow the dialog.
 *
 **/

/**
 * How to create test cases:
 *
 * 1. Create category for XVimTester (unless you can find proper file to write test case)
 *    For example, create file with name "XVimTester+mytest.m" and write
 *       #import "XVimTester.h"
 *       @implementation XVimTester(mytest)
 *       @end
 *
 *    (You do not need to create .h for the category)
 *
 * 2. Define method named "*_testcases" where * is wildcard. The method must return NSArray*.
 *    For example
 *       - (NSArra*)mytest_testcases{ ... }
 *
 * 3. Create array of test cases and return it. A test case must be created with XVimMakeTestCase Macro.
 *    For example
 *       return [NSArray arrayWithObjects:
 *                   XVimMakeTestCase("abc", 0, 0, "l", "abc", 1, 0),
 *                   XVimMakeTestCase("abc", 0, 0, "x",  "bc", 0, 0),
 *               nil];
 *
 *    XVimMakeTestCase arguments are...
 *     Initial text,
 *     Initial selected range location,
 *     Initial selected range length,
 *     Vim command to test,
 *     Expected result text,
 *     Expected result selected range location,
 *     Expected result selected range length
 *
 *    The first example above means
 *     With the test "abc" and insertion point on "a" and input "l"
 *     must result in with the uncahnged text with the cursor at "b"
 *
 *
 * Test cases you wrote automatically included and run.
 **/


@interface XVimTester () {
    NSWindow* results;
    NSTableView* _tableView;
    NSTextField* resultsString;
    BOOL showPassing;
    NSNumber* totalTests;
    NSNumber* passingTests;
}
@property (strong) NSMutableArray* testCases;
@property (strong) NSArray* currentTestsCases;;
@property (weak) NSWindow* testWindow;
@property NSUInteger currentTestCaseIndex;
@end


@implementation XVimTester

- (id)init
{
    if (self = [super init]) {
        self.testCases = [NSMutableArray array];
        showPassing = false;
    }
    return self;
}


- (NSArray*)categories
{
    NSMutableArray* arr = [[NSMutableArray alloc] init];
    unsigned int count = 0;
    Method* m = 0;
    m = class_copyMethodList([XVimTester class], &count);
    for (unsigned int i = 0; i < count; i++) {
        SEL sel = method_getName(m[i]);
        if ([NSStringFromSelector(sel) hasSuffix:@"_testcases"]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [arr addObject:[[NSStringFromSelector(sel) componentsSeparatedByString:@"_"] objectAtIndex:0]];
#pragma clang diagnostic pop
        }
    }
    // category names need to be sorted alphabetically
    return [arr sortedArrayUsingSelector:@selector(compare:)];
}

- (void)selectCategories:(NSArray*)categories
{
    [self.testCases removeAllObjects];
    for (NSString* c in categories) {
        SEL sel = NSSelectorFromString([c stringByAppendingString:@"_testcases"]);
        if ([self respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            NSArray* ary = [self performSelector:sel];
#pragma clang diagnostic pop
            [self.testCases addObjectsFromArray:ary];
        }
    }
}

- (void)runTest
{
    // Create Test Cases
    self.currentTestsCases = self.testCases;
    self.currentTestCaseIndex = 0;

    NSFileManager* fm = [[NSFileManager alloc] init];
    NSString* filename = @"/tmp/xvimtest.cpp"; // The tmp file extension must be .cpp , .m or other source file
                                               // extension. This is because some test case depend on source code format
                                               // feature. If it is .txt or .tmp source code format is not invoked and
                                               // some test cases fails.
    BOOL isDirectory;
    if (![fm fileExistsAtPath:filename isDirectory:&isDirectory]) {
        [fm createFileAtPath:filename contents:nil attributes:nil];
    }


    // Open another window to open temporary file
    NSError* error;
    NSURL* doc = [NSURL fileURLWithPath:filename];
    DVTDocumentLocation* loc = [[DVTDocumentLocationClass() alloc] initWithDocumentURL:doc timestamp:nil];
    id lastActiveWorkspace = [(IDEWorkspaceTabController*)XVimLastActiveWorkspaceTabController() workspace];
    if (lastActiveWorkspace == nil) {
        NSBeep();
        return;
    }
    IDEEditorOpenSpecifier* spec =
                [IDEEditorOpenSpecifierClass() structureEditorOpenSpecifierForDocumentLocation:loc
                                                                                   inWorkspace:lastActiveWorkspace
                                                                                         error:&error];

    // IDEDocumentController* ctrl = [IDEDocumentController sharedDocumentController];
    // [ctrl openDocumentWithContentsOfURL:doc display:YES error:&error]; // This doesn't work anymore after Xcode 7 GM

    [IDEEditorCoordinatorClass()
                _doOpenIn_NewWindow_withWorkspaceTabController:XVimLastActiveWorkspaceTabController()
                                                   documentURL:doc
                                                    usingBlock:^(IDEEditorContext* context) {
                                                        [context openEditorOpenSpecifier:spec updateHistory:NO];
                                                    }];

    // Close NSWindow to make test run properly
    [results close];
    results = nil;
    self.testWindow = [XVimLastActiveWindowController() window];
    
    [self runNextTest];
}

-(void)runNextTest
{
    if ((self.currentTestCaseIndex == self.currentTestsCases.count) ||
        (self.testWindow == nil || !self.testWindow.isVisible))
    {
        self.currentTestsCases = nil;
        [self.testWindow performClose:self];
        [self showResultsTable];
        return;
    }
    
    XVimTestCase *test = self.currentTestsCases[self.currentTestCaseIndex];
    self.currentTestCaseIndex++;
    
    [test runInWindow:self.testWindow withContinuation:^{
        [self runNextTest];
    }];
}

- (void)showResultsTable
{
    // Setup Table view to show result
    _tableView = [[NSTableView alloc] init];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];

    // Create Columns
    NSTableColumn* column1 = [[NSTableColumn alloc] initWithIdentifier:@"Description"];
    [column1.headerCell setStringValue:@"Description"];
    NSTableColumn* column2 = [[NSTableColumn alloc] initWithIdentifier:@"Pass/Fail"];
    [column2 setWidth:52.0];
    [column2.headerCell setStringValue:@"Pass/Fail"];
    NSTableColumn* column3 = [[NSTableColumn alloc] initWithIdentifier:@"Message"];
    [column3.headerCell setStringValue:@"Message"];
    [column3 setWidth:200.0];
    NSTableColumn* column4 = [[NSTableColumn alloc] initWithIdentifier:@"Expected"];
    [column4 setWidth:200.0];
    [column4.headerCell setStringValue:@"Expected"];
    NSTableColumn* column5 = [[NSTableColumn alloc] initWithIdentifier:@"Actual"];
    [column5.headerCell setStringValue:@"Actual"];
    [column5 setWidth:200.0];

    [_tableView addTableColumn:column1];
    [_tableView addTableColumn:column2];
    [_tableView addTableColumn:column3];
    [_tableView addTableColumn:column4];
    [_tableView addTableColumn:column5];
    _tableView.usesAutomaticRowHeights = YES;
    _tableView.usesAlternatingRowBackgroundColors = YES;

    [_tableView setAllowsMultipleSelection:YES];
    [_tableView reloadData];

    // setup a window to show the tableview, scrollview, and results toggling button.
    NSUInteger mask = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable
                      | NSWindowStyleMaskResizable;
    results = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 700, 500)
                                          styleMask:mask
                                            backing:NSBackingStoreBuffered
                                              defer:false];
    // Prevent from crashing on ARC
    [results setReleasedWhenClosed:NO];

    // Setup the table view into scroll view
    NSScrollView* scroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 40, 700, 445)];
    [scroll setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [scroll setDocumentView:_tableView];
    [scroll setHasVerticalScroller:YES];
    [scroll setHasHorizontalScroller:YES];

    // setup the results toggle button
    NSButton* toggleResultsButton = [[NSButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 30)];
    [toggleResultsButton setTitle:@"Toggle Results"];
    [toggleResultsButton setBezelStyle:NSRoundedBezelStyle];
    [toggleResultsButton setTarget:self];
    [toggleResultsButton setAction:@selector(toggleResults:)];


    resultsString = [[NSTextField alloc] initWithFrame:NSMakeRect(550, 0, 200, 40)];
    [resultsString setStringValue:@"0 out of 0 test passing"];
    [resultsString setAutoresizingMask:NSViewMinXMargin | NSViewMaxYMargin];
    [resultsString setBezeled:NO];
    [resultsString setDrawsBackground:NO];
    [resultsString setEditable:NO];
    [resultsString setSelectable:NO];

    // setup the main content view for the window and add the controls to it.
    NSView* resultsView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 450)];

    [results setContentView:resultsView];

    [resultsView addSubview:scroll];
    [resultsView addSubview:resultsString];
    [resultsView addSubview:toggleResultsButton];
    [resultsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];

    [self updateResultsString];

    [results makeKeyAndOrderFront:results];
}

- (void)updateResultsString
{
    NSInteger totalCases = 0;
    NSInteger passingCases = 0;
    NSInteger failingCases = 0;

    for (XVimTestCase* tc in self.testCases) {
        if (!tc.success) {
            failingCases++;
        }
        else {
            passingCases++;
        }
        totalCases++;
    }

    [resultsString setStringValue:[NSString stringWithFormat:@"%lu Passing Tests\n%lu Failing Tests", passingCases,
                                                             failingCases]];
}

- (IBAction)toggleResults:(id)sender
{
    showPassing = !showPassing;
    [_tableView reloadData];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView*)aTableView
{
    if (showPassing) {
        return (NSInteger)[self.testCases count];
    }
    else {
        NSInteger runningCount = 0;
        for (XVimTestCase* tc in self.testCases) {
            if (!tc.success) {
                runningCount++;
            }
        }
        return runningCount;
    }
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    XVimTestCase * resultRow = nil;
    NSTextField *cellView = [tableView makeViewWithIdentifier:aTableColumn.identifier owner:self];
    if (!cellView) {
        cellView = [NSTextField wrappingLabelWithString:@""];
        cellView.editable = YES;
    }
    
    if (showPassing) {
        resultRow = (XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)rowIndex];
    }
    else {
        NSInteger index = [self getIndexOfNthFailingTestcase:rowIndex];
        resultRow = (XVimTestCase*)[self.testCases objectAtIndex:(NSUInteger)index];
    }
    NSString *string = @"";
    
    if ([aTableColumn.identifier isEqualToString:@"Description"]
        || [aTableColumn.identifier isEqualToString:@"Expected"]
        || [aTableColumn.identifier isEqualToString:@"Actual"]
        ) {
        cellView.font = [NSFont userFixedPitchFontOfSize:11.0];
    }
    else {
        cellView.font = [NSFont userFontOfSize:11.0];
    }
    
    if ([aTableColumn.identifier isEqualToString:@"Pass/Fail"]) {
        cellView.alignment = NSTextAlignmentCenter;
        cellView.textColor = (resultRow.success ? NSColor.greenColor : NSColor.redColor);
    }
    else {
        cellView.alignment = NSTextAlignmentLeft;
        cellView.textColor = NSColor.labelColor;
    }
    
    if ([aTableColumn.identifier isEqualToString:@"Description"]) {
        string = resultRow.desc;
    }
    else if ([aTableColumn.identifier isEqualToString:@"Pass/Fail"]) {
        string = resultRow.finished ? ((resultRow.success) ? @"Pass" : @"Fail") : @"Cancelled";
    }
    else if ([aTableColumn.identifier isEqualToString:@"Message"]) {
        string = resultRow.message;
    }
    else if ([aTableColumn.identifier isEqualToString:@"Expected"]) {
        string = [NSString stringWithFormat:@"'%@'", resultRow.expectedText];
    }
    else if ([aTableColumn.identifier isEqualToString:@"Actual"]) {
        string = [NSString stringWithFormat:@"'%@'", resultRow.actualText];
    }
    cellView.stringValue = string;
    return cellView;
}


- (NSInteger)getIndexOfNthFailingTestcase:(NSInteger)nth
{
    NSInteger runningCount = -1;
    NSInteger retval = -1;
    for (XVimTestCase* tc in self.testCases) {
        retval++;
        if (!tc.success) {
            runningCount++;
            if (runningCount == nth) {
                break;
            }
        }
    }
    return retval;
}

-(CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
    return 200.0;
}
@end


DVTTextPreferences* XcodeTextPreferences(void) { return [DVTTextPreferencesClass() preferences]; }
