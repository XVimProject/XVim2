//
//  SourceCodeEditorViewProxy+XVim.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceCodeEditorViewProxy.h"
#import "XVimMotionOption.h"
#import <Foundation/Foundation.h>

@interface SourceCodeEditorViewProxy (XVim)
- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line;
- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line column:(NSUInteger)col;
- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)idx;
- (NSUInteger)xvim_endOfLine:(NSUInteger)startIdx;
- (NSArray*)xvim_selectedRanges;
- (NSRange)xvim_indexRangeForLines:(NSRange)lineRange;
- (NSRange)xvim_indexRangeForLines:(NSRange)lineRange includeEOL:(BOOL)includeEOL;
- (void)xvim_beginEditTransaction;
- (void)xvim_endEditTransaction;
- (void)xvim_blockInsertFixupWithText :(NSString*)text mode:(XVimInsertionPoint)mode
                                 count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines;
- (void)xvim_syncStateFromView;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
@end
