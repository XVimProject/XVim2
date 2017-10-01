//
//  SourceViewProtocol.h
//  XVim2
//
//  Created by Ant on 30/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef SourceViewProtocol_h
#define SourceViewProtocol_h

@class XVimMotion;

@protocol SourceViewProtocol <NSObject>
- (void) insertText:(id)insertString;
- (id) performSelector:(SEL)aSelector withObject:(id)object;
- (void) scrollPageForward:(NSUInteger)numPages;
- (void) scrollPageBackward:(NSUInteger)numPages;
- (void) xvim_move:(XVimMotion*)motion;
- (void) xvim_insert:(XVimInsertionPoint)mode blockColumn:(NSUInteger *)column blockLines:(XVimRange *)lines;
- (void) xvim_blockInsertFixupWithText:(NSString *)text mode:(XVimInsertionPoint)mode
                                count:(NSUInteger)count column:(NSUInteger)column lines:(XVimRange)lines;
@property (readonly) NSRange selectedRange;
@property (readonly) NSString *string;
@property (readonly) XVIM_VISUAL_MODE selectionMode;
@end

#endif /* SourceViewProtocol_h */
