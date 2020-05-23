//
//  IDEWorkspaceTabController+XVim.h
//  XVim
//
//  Created by Suzuki Shuichiro on 10/23/14.
//
//

#import <IDEKit/IDEWorkspaceTabController.h>

typedef NS_ENUM(NSInteger, EditorMode) {
    STANDARD,
    GENIUS,
    VERSION
};

NS_ASSUME_NONNULL_BEGIN

@interface IDEWorkspaceTabController_XVim : NSObject
+ (void)xvim_hook;
- (void)xvim_jumpFocus:(NSInteger)count relative:(BOOL)relative;
- (void)xvim_addEditor;
- (void)xvim_addEditorVertically;
- (void)xvim_addEditorHorizontally;
- (void)xvim_moveFocusDown;
- (void)xvim_moveFocusUp;
- (void)xvim_moveFocusLeft;
- (void)xvim_moveFocusRight;
- (void)xvim_removeAssistantEditor;
- (void)xvim_closeOtherEditors;
- (void)xvim_closeCurrentEditor;
@end

NS_ASSUME_NONNULL_END
