//
//  SourceCodeEditorViewProxy+Yank.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import "XVimMotionType.h"
#import <Foundation/Foundation.h>

@interface SourceEditorViewProxy (Yank) <SourceViewYankProtocol>
- (void)__xvim_startYankWithType:(MOTION_TYPE)type;
- (void)_xvim_yankRange:(NSRange)range withType:(MOTION_TYPE)type;
- (void)_xvim_yankSelection:(XVimSelection)sel;
- (void)_xvim_killSelection:(XVimSelection)sel;
@end
