//
//  SourceEditorViewProxy+Operations.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import <Foundation/Foundation.h>
#import "XVimMotionType.h"

NS_ASSUME_NONNULL_BEGIN

@interface SourceEditorViewProxy (Operations) <SourceEditorViewOperationsProtocol>
- (BOOL)xvim_delete:(XVimMotion*)motion withMotionPoint:(NSUInteger)motionPoint andYank:(BOOL)yank;
- (BOOL)xvim_delete:(XVimMotion*)motion andYank:(BOOL)yank;
- (NSRange)xvim_getOperationRangeFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;
@end

NS_ASSUME_NONNULL_END
