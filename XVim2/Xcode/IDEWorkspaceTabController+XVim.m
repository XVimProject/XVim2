//
//  IDEWorkspaceTabController+XVim.m
//  XVim
//
//  Created by Suzuki Shuichiro on 10/23/14.
//
//

#import "Geometry.h"
#import "IDEWorkspaceTabController+XVim.h"
#import "Logger.h"
#import "NSObject+Swizzle.h"
#import "SourceEditorViewProxy.h"
#import "XVimWindow.h"
#import "XcodeUtils.h"
#import <IDEKit/IDEComparisonEditorSubmode.h>
#import <IDEKit/IDEEditorArea.h>
#import <IDEKit/IDEEditorContext.h>
#import <IDEKit/IDEEditorGeniusMode.h>
#import <IDEKit/IDEEditorMultipleContext.h>
#import <IDEKit/IDEEditorOpenSpecifier.h>
#import <IDEKit/IDEEditorVersionsMode.h>
#import <IDEKit/IDEWorkspaceTabController.h>
#import <IDEKit/IDEWorkspaceWindowController.h>

IDEEditorOpenSpecifier* xvim_openSpecifierForContext(IDEEditorContext* context);
/**
 * XVim Window - View structure:
 *
 * IDEWorkspaceWindowController  --- IDEWorkSpaceWindow
 *       |- IDEWorkspaceTabController
 *       |           |- Navigation Area
 *       |           |- Editor Area
 *       |           |- Debug Area
 *       |- IDEWorkspaceTabController
 *                   |- Navigation Area
 *                   |- Editor Area
 *                   |- Debug Area
 *
 *
 * The top level window is IDEWorkspaceWindow.
 * If you double click a file in navigator then you'll get another IDEWorkspaceWindow.
 * Actuall manipulations on the window is taken by IDEWorkspaceWindowController which you can get by
 *IDEWorkspaceWindow's windowController method. IDEWordspaceWindowController(IDEWSC) has multiple tabs and each tab is
 *controlled by IDEWorkspaceTabController(IDEWTC). IDEWTC manages all the view's in a tab. It means that it has
 *navigation, editor, debug areas. If you have multiple tabs it means you have multiple navigations or editors or debug
 *areas since each tab has its own these areas. Only one IDEWTC is active at once and you can get the active one
 *through "activeWorkspaceTabContrller" method in IDEWSC.
 *
 * Most of the editor view manipulation can be done vie the IDEWTC.
 * You can get the all the areas in an IDEWTC by _keyboardFocusAreas method.
 * It returns array of IDEViewController derived classes such as IDENavigationArea, IDEEditorContext,
 *IDEDefaultDebugArea.
 **/

typedef NS_ENUM(NSInteger, GeniusLayoutMode) {
    NOT_GENIUS = -1,
    GENIUS_RV,
    GENIUS_RH,
    GENIUS_LV, /* Not used in Xcode */
    GENIUS_LH, /* Not used in Xcode */
    GENIUS_TV, /* Not used in Xcode */
    GENIUS_TH, /* Not used in Xcode */
    GENIUS_BV,
    GENIUS_BH
};

static inline BOOL xvim_verticallyStackingModeForMode(GeniusLayoutMode mode)
{
    return (mode % 2) == 1 ? mode - 1 : mode;
}
static inline BOOL xvim_horizontallyStackingModeForMode(GeniusLayoutMode mode)
{
    return (mode % 2) == 0 ? mode + 1 : mode;
}

#define SELF ((IDEWorkspaceTabController*)self)

@implementation IDEWorkspaceTabController_XVim

+ (void)xvim_hook
{
    Class wtc = NSClassFromString(@"IDEWorkspaceTabController");
    [self xvim_addInstanceMethod:@selector(xvim_allEditorArea) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_keyboardFocusAreas) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_currentLayout) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_addEditorVertically) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_addEditorHorizontally) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_jumpFocus:relative:) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_addEditor) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_moveFocusDown) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_moveFocusUp) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_moveFocusLeft) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_moveFocusRight) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_closeOtherEditors) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_closeCurrentEditor) toClass:wtc];
    [self xvim_addInstanceMethod:@selector(xvim_removeAssistantEditor) toClass:wtc];
}

- (NSArray*)xvim_allEditorArea
{
    NSMutableArray* otherViews = [[NSMutableArray alloc] init];
    for (IDEViewController* c in [self xvim_keyboardFocusAreas]) {
        if ([[[c class] description] isEqualToString:@"IDEEditorContext"]) {
            [otherViews addObject:c];
        }
    }
    return otherViews;
}

- (id)xvim_keyboardFocusAreas
{
    if ([self respondsToSelector:@selector(_keyboardFocusAreas:)]) {
        return [self performSelector:@selector(_keyboardFocusAreas:) withObject:@YES];
    }
    return nil;
}

- (GeniusLayoutMode)xvim_currentLayout
{
    return (SELF.editorArea.editorMode == GENIUS) ? SELF.assistantEditorsLayout : NOT_GENIUS;
}

// It's not possible to get the full flexibility of Vim windows in Xcode, so we have to compromise.
// We keep horizontally stacking windows for vsplits, until a horizontal split is requested, and then
// we flip the assitant editor layout to stack vertically.
// We do the corresponding actions for splits --> vsplits
// To get more flexibility, we probably need to add new versions of split/vsplit to change the
// assistant layout as required.
- (void)xvim_addEditorVertically
{

    GeniusLayoutMode layout = [self xvim_currentLayout];
    [self xvim_addEditor];
    if (layout == NOT_GENIUS) {
        // Xcode11
        //[SELF changeToAssistantLayout_RH:self];
    }
    else {
        SELF.assistantEditorsLayout = xvim_horizontallyStackingModeForMode(layout);
    }
}

- (void)xvim_addEditorHorizontally
{
    GeniusLayoutMode layout = [self xvim_currentLayout];
    [self xvim_addEditor];
    if (layout == NOT_GENIUS) {
        // Xcode11
        //[SELF changeToAssistantLayout_BV:self];
    }
    else {
        SELF.assistantEditorsLayout = xvim_verticallyStackingModeForMode(layout);
    }
}

// Vim does not jump focus more than 1 when it is relative jump
// but this method generalizes it and takes count to jump from current editor when relative is YES.
- (void)xvim_jumpFocus:(NSInteger)count relative:(BOOL)relative
{
    if (count == 0 || count == NSIntegerMin) {
        return;
    }

    /**
     I have no idea what is `GENIUS`µ Mode but once I cancel this pre-condition,
     we can do the relative jump.
     I don't want to change something I don't know, maybe there is something
     wrong somewhere 🤔
     IDEEditorArea* editorArea = [SELF editorArea];
     if ([editorArea editorMode] != GENIUS) {
         DEBUG_LOG(@"editor not in genius mode, nothing to jump to");
         return;
     }
     */

    IDEViewController* current = [SELF _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];
    NSInteger numEditors = (NSInteger)[allEditors count]; // Should be no problem to cast it to NSInteger
    if (0 >= numEditors) {
        // Just in case
        return;
    }

    if (relative) {
        // Relative index (rotation)
        NSInteger idx = (NSInteger)[allEditors indexOfObject:current] + (count % numEditors)
                        + numEditors; // add numEditors to make it always positive
        [allEditors[(NSUInteger)(idx % numEditors)] takeFocus];
    }
    else {
        // Absolute index (Note: both count and numEditors are not 0 here)
        count = MIN(ABS(count), numEditors) - 1; // -1 to convert it to array index
        [allEditors[(NSUInteger)(count % numEditors)] takeFocus];
    }
    // redraw caret
    [current.view setNeedsDisplay:YES];
}

- (void)xvim_addEditor
{
    IDEWorkspaceTabController* workspaceTabController = SELF;
    IDEEditorArea* editorArea = [SELF editorArea];
    if ([editorArea editorMode] != GENIUS) {
        [workspaceTabController changeToGeniusEditor:SELF];
    }
    else {
        // Xcode11
        //[workspaceTabController addAssistantEditor:SELF];
    }
}

/**
 * For move focus calculations.
 * The basic thing doing here is ...
 *   Enumerate all the editors and
 *   for each editors compare the position of the corner to current editors corner.
 *    For example if its Ctrl-w + h, we compare "current editor's left edge" and "others right edge".
 *    If we find the right edge on the left of current editors left edge we take it as a candidate to move forcus on.
 *    But there may be more than 1 editor which is on the left of current editor we have to find
 *    the editor whose right edge is closest to the current editors right edge.
 **/

- (void)xvim_moveFocusDown
{
    IDEWorkspaceTabController* tabCtrl = SELF;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];

    // Compare current view's bottom and other views' top positions.(Find the top is bigger the the bottom but nearest
    // one) Remember that y gets bigger when gose to upper side.
    CGPoint current_point = [current.view frame].origin; // Left bottom
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is
    // smaller than this left value.
    CGPoint point;
    CGFloat maximum_top = 0; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for (IDEEditorContext* c in allEditors) {
        point = LeftTop([[c view] convertRect:[c.view frame] toView:nil]);
        if (point.y <= current_point.y) {
            if (maximum_top < point.y) {
                targetEditor = c;
                maximum_top = point.y;
            }
        }
    }
    [targetEditor takeFocus];
    // redraw caret
    [current.view setNeedsDisplay:YES];
}

- (void)xvim_moveFocusUp
{
    IDEWorkspaceTabController* tabCtrl = SELF;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];

    // Compare current view's bottom and other views' top positions.(Find the top is bigger the the bottom but nearest
    // one) Remember that y gets bigger when gose to upper side.
    CGPoint current_point = LeftTop([current.view frame]);
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is
    // smaller than this left value.
    CGPoint point;
    CGFloat minimum_top = FLT_MAX; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for (IDEEditorContext* c in allEditors) {
        point = [[c view] convertRect:[c.view frame] toView:nil].origin;
        if (point.y >= current_point.y) {
            if (minimum_top > point.y) {
                targetEditor = c;
                minimum_top = point.y;
            }
        }
    }
    [targetEditor takeFocus];
    // redraw caret
    [current.view setNeedsDisplay:YES];
}

- (void)xvim_moveFocusLeft
{
    IDEEditorArea* editorArea = [SELF editorArea];
    if ([editorArea editorMode] == VERSION) {
        // This implementation is not correct for precise moveFocusLeft behavior but it is useful.

        // preserve current line number.
        // NSUInteger line_number = (NSUInteger)editorArea.xvim_window.sourceView.currentLineNumber;
        // change window focus.
        //IDEEditorVersionsMode* mode = (IDEEditorVersionsMode*)[editorArea editorModeViewController];
        //IDEComparisonEditorSubmode* submode = mode.comparisonEditorSubmode;
        // XCODE93
        //[submode.primaryEditor takeFocus];
        // set current line number
        // XVimMotion* motion = [XVimMotion style:MOTION_LINENUMBER type:LINEWISE option:LEFT_RIGHT_NOWRAP count:1];
        // motion.line = line_number;
        //[editorArea.xvim_window.sourceView xvim_move:motion];

        return;
    }
    IDEWorkspaceTabController* tabCtrl = SELF;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];

    CGPoint current_point = [[current view] frame].origin; // Left bottom point
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is
    // smaller than this left value.
    CGPoint point;
    CGFloat maximum_right = 0; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for (IDEEditorContext* c in allEditors) {
        point = RightBottom([[c view] convertRect:[c.view frame] toView:nil]);
        if (point.x <= current_point.x) {
            // This view is at least on the left of the current view.
            if (maximum_right < point.x) {
                targetEditor = c;
                maximum_right = point.x;
            }
        }
    }
    [targetEditor takeFocus];
    // redraw caret
    [current.view setNeedsDisplay:YES];
}

- (void)xvim_moveFocusRight
{
    IDEEditorArea* editorArea = [SELF editorArea];
    if ([editorArea editorMode] == VERSION) {
        // This implementation is not correct for precise moveFocusRight behavior but it is useful.
        // The behavior in comparison view is like diff mode on the original vim.

        // preserve current line number.
        // NSUInteger line_number = (NSUInteger)editorArea.xvim_window.sourceView.currentLineNumber;
        // change window focus.
        //IDEEditorVersionsMode* mode = (IDEEditorVersionsMode*)[editorArea editorModeViewController];
        //IDEComparisonEditorSubmode* submode = mode.comparisonEditorSubmode;
        // XCODE93
        //[submode.secondaryEditor takeFocus];
        // set current line number
        // XVimMotion* motion = [XVimMotion style:MOTION_LINENUMBER type:LINEWISE option:LEFT_RIGHT_NOWRAP count:1];
        // motion.line = line_number;
        //[editorArea.xvim_window.sourceView xvim_move:motion];

        return;
    }
    IDEWorkspaceTabController* tabCtrl = SELF;
    IDEViewController* current = [tabCtrl _currentFirstResponderArea];
    NSArray* allEditors = [self xvim_allEditorArea];

    CGPoint current_point = RightBottom([[current view] frame]);
    current_point = [[current view] convertPoint:current_point toView:nil];
    // To find a view left of this editor we walk around the view and find if there is a view whose right side is
    // smaller than this left value.
    CGPoint point;
    CGFloat minimum_left = FLT_MAX; // To keep nearest view
    IDEEditorContext* targetEditor = nil;
    for (IDEEditorContext* c in allEditors) {
        point = [[c view] convertRect:[c.view frame] toView:nil].origin; // Left Bottom
        if (point.x >= current_point.x) {
            if (minimum_left > point.x) {
                targetEditor = c;
                minimum_left = point.x;
            }
        }
    }
    [targetEditor takeFocus];
    // redraw caret
    [current.view setNeedsDisplay:YES];
}

- (void)xvim_closeOtherEditors
{
    IDEEditorArea* editorArea = [SELF editorArea];
    if ([editorArea editorMode] != GENIUS) {
        return;
    }
    IDEEditorGeniusMode* geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
    IDEEditorMultipleContext* multipleContext = [geniusMode alternateEditorMultipleContext];
    IDEEditorContext* primaryContext = [geniusMode primaryEditorContext];
    IDEEditorContext* selectedContext = [editorArea lastActiveEditorContext];
    if (!selectedContext.isPrimaryEditorContext) {
        IDEEditorOpenSpecifier* openSpecifier = xvim_openSpecifierForContext(selectedContext);
        if (openSpecifier) {
            [primaryContext openEditorOpenSpecifier:openSpecifier];
        }
    }
    if ([multipleContext canCloseEditorContexts]) {
        [multipleContext closeAllEditorContextsKeeping:[multipleContext selectedEditorContext]];
    }
    [SELF changeToStandardEditor:SELF];
}

- (void)xvim_closeCurrentEditor
{
    IDEEditorArea* editorArea = [SELF editorArea];
    EditorMode editorMode = (EditorMode)[editorArea editorMode];
    if (editorMode == STANDARD) {
        if ([SELF.windowController.workspaceTabControllers count] > 1) {
            [SELF.windowController.window.tabGroup.selectedWindow performClose:nil];
        }
        else {
            [SELF.windowController.window performSelector:@selector(performClose:) withObject:nil afterDelay:0];
        }
        return;
    }
    else if (editorMode == GENIUS) {
        IDEEditorGeniusMode* geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
        IDEEditorMultipleContext* multipleContext = [geniusMode alternateEditorMultipleContext];
        IDEEditorContext* primaryContext = [geniusMode primaryEditorContext];
        IDEEditorContext* selectedContext = [editorArea lastActiveEditorContext];
        if (selectedContext.isPrimaryEditorContext) {
            IDEEditorContext* otherContext = [multipleContext firstEditorContext];
            if (otherContext) {
                IDEEditorOpenSpecifier* openSpecifier = xvim_openSpecifierForContext(otherContext);
                if (openSpecifier) {
                    [primaryContext openEditorOpenSpecifier:openSpecifier];
                    [otherContext takeFocus];
                    [self xvim_removeAssistantEditor];
                    [primaryContext takeFocus];
                }
            }
        }
        else {
            [self xvim_removeAssistantEditor];
        }
    }
}

- (void)xvim_removeAssistantEditor
{
    IDEEditorArea* editorArea = SELF.editorArea;
    switch ([editorArea editorMode]) {
    case STANDARD:
        break;
    case GENIUS:
        {
            IDEEditorGeniusMode* geniusMode = (IDEEditorGeniusMode*)[editorArea editorModeViewController];
            if ([geniusMode canRemoveAssistantEditor] == NO) {
                [SELF changeToStandardEditor:SELF];
            }
            else {
                //[SELF removeAssistantEditor:SELF];
            }
        }
        break;
    case VERSION:
        break;
    }
}
@end

IDEEditorOpenSpecifier* xvim_openSpecifierForContext(IDEEditorContext* context)
{
    NSArray* locations = context._currentSelectedDocumentLocations;
    return XVimOpenSpecifier(context.navigableItem, locations.firstObject);
}
