//
//  SourceViewProtocol.h
//  XVim2
//
//  Created by Ant on 30/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#ifndef SourceViewProtocol_h
#define SourceViewProtocol_h

@protocol SourceViewProtocol <NSObject>
- (id)performSelector:(SEL)aSelector withObject:(id)object;

-(void)scrollPageForward:(NSUInteger)numPages;
-(void)scrollPageBackward:(NSUInteger)numPages;
@property (readonly) NSRange selectedRange;

@end

#endif /* SourceViewProtocol_h */
