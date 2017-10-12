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
@class IDEWorkspaceTabController_XVim;
@class IDEEditorArea;
@class IDENavigableItem;
@class IDEEditorOpenSpecifier;

IDEWorkspaceWindowController* XVimLastActiveWindowController(void);
IDEWorkspaceTabController_XVim* XVimLastActiveWorkspaceTabController(void);
IDEEditorArea* XVimLastActiveEditorArea(void);
BOOL XVimOpenDocumentAtPath(NSString *path);
IDEEditorOpenSpecifier *XVimOpenSpecifier(IDENavigableItem *item, id locationToSelect);
