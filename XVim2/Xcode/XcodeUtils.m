//
//  XcodeUtils.m
//  XVim2
//
//  Created by Ant on 09/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "XcodeUtils.h"
#import <IDEKit/IDEWorkspaceWindow.h>
#import <IDEKit/IDEEditorArea.h>
#import <IDEKit/IDEWorkspaceWindowController.h>
#import <IDEKit/IDEWorkspaceTabController.h>
#import <IDEKit/IDEEditorOpenSpecifier.h>
#import <DVTKit/DVTDocumentLocation.h>


IDEWorkspaceWindowController* XVimLastActiveWindowController()
{
    return [IDEWorkspaceWindow lastActiveWorkspaceWindowController];
}

IDEWorkspaceTabController* XVimLastActiveWorkspaceTabController()
{
    return [XVimLastActiveWindowController() activeWorkspaceTabController];
}

IDEEditorArea* XVimLastActiveEditorArea() { return [XVimLastActiveWindowController() editorArea]; }

#ifdef TODO
DVTSourceTextView* XVimLastActiveSourceView()
{
    return [[[[XVimLastActiveEditorArea() lastActiveEditorContext] editor] mainScrollView] documentView];
}
#endif

BOOL XVimOpenDocumentAtPath(NSString *path) {
    NSError* error;
    NSURL* doc = [NSURL fileURLWithPath:path];
    DVTDocumentLocation* loc = [[NSClassFromString(@"DVTDocumentLocation") alloc] initWithDocumentURL:doc timestamp:nil];
    if (loc) {
        IDEEditorOpenSpecifier* spec = [IDEEditorOpenSpecifier
                                        structureEditorOpenSpecifierForDocumentLocation:loc
                                        inWorkspace:[XVimLastActiveWorkspaceTabController() workspace]
                                        error:&error];
        if (error == nil) {
            [XVimLastActiveEditorArea() _openEditorOpenSpecifier:spec
                                                   editorContext:[XVimLastActiveEditorArea() lastActiveEditorContext]
                                                       takeFocus:YES];
        }
        else {
            ERROR_LOG(@"Failed to create IDEEditorOpenSpecifier from %@. Error = %@", path, error.localizedDescription);
            return NO;
        }
    }
    else {
        ERROR_LOG(@"Cannot create DVTDocumentLocation from %@", path);
        return NO;
    }
    return YES;
}
