//
//  SourceCodeEditorViewProxy+Operations.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceCodeEditorViewProxy.h"

@interface SourceCodeEditorViewProxy(Operations) <SourceViewOperationsProtocol>
- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank;
- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank;
@end
