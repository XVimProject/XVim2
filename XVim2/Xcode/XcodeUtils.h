//
//  XcodeUtils.h
//  XVim2
//
//  Created by Ant on 09/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceWindow;
@class IDEWorkspaceWindowController;
@class IDEWorkspaceTabController;
@class IDEEditorArea;

IDEWorkspaceWindowController* XVimLastActiveWindowController(void);
IDEWorkspaceTabController* XVimLastActiveWorkspaceTabController(void);
IDEEditorArea* XVimLastActiveEditorArea(void);
