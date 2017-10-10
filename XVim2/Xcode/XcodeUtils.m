//
//  XcodeUtils.m
//  XVim2
//
//  Created by Ant on 09/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "XcodeUtils.h"
#import <IDEKit/IDEWorkspaceWindow.h>
#import <IDEKit/IDEWorkspaceWindowController.h>


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
