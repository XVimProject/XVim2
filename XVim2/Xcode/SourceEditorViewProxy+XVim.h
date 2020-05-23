//
//  SourceCodeEditorViewProxy+XVim.h
//  XVim2
//
//  Created by Ant on 02/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import "XVimMotionOption.h"
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SourceEditorViewProxy (XVim)
- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line;
- (NSUInteger)xvim_indexOfLineNumber:(NSUInteger)line column:(NSUInteger)col;
- (NSUInteger)xvim_lineNumberAtIndex:(NSUInteger)idx;
- (NSUInteger)xvim_endOfLine:(NSUInteger)startIdx;
- (NSArray<NSValue *>*)xvim_selectedRanges;
- (NSRange)xvim_indexRangeForLines:(NSRange)lineRange;
- (NSRange)xvim_indexRangeForLines:(NSRange)lineRange includeEOL:(BOOL)includeEOL;
- (void)xvim_beginEditTransaction;
- (void)xvim_endEditTransaction;
- (void)xvim_blockInsertFixupWithText:(NSString*)text insertMode:(XVimInsertMode)insertMode
                                 count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines;
- (void)xvim_syncStateFromView;
- (void)xvim_syncStateWithScroll:(BOOL)scroll;
- (void)xvim_changeSelectionMode:(XVIM_VISUAL_MODE)mode;
- (NSRange)xvim_selectedRange;
- (NSRange)xvim_currentNumber;
- (void)xvim_registerPositionForUndo:(NSUInteger)pos;
- (void)xvim_registerInsertionPointForUndo;
- (XVimSelection)xvim_selectedBlock;
- (XVimRange)xvim_getMotionRange:(NSUInteger)current Motion:(XVimMotion*)motion;
- (void)xvim_moveCursor:(NSUInteger)pos preserveColumn:(BOOL)preserve;
- (XVimRange)xvim_selectedLines;
- (void)xvim_insertSpaces:(NSUInteger)count replacementRange:(NSRange)replacementRange;
@end

NS_ASSUME_NONNULL_END
