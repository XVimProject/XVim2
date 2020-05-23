//
//  XVimMark.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/21/13.
//
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XVimMark : NSObject
@property NSUInteger line;
@property NSUInteger column;
@property NSString* document;

- (id)initWithLine:(NSUInteger)line column:(NSUInteger)col document:(nullable NSString*)doc;
- (id)initWithMark:(nullable XVimMark*)mark;
- (void)setMark:(XVimMark*)mark;
+ (XVimMark *)markWithLine:(NSUInteger)line column:(NSUInteger)col document:(nullable NSString*)doc;
@end

NS_ASSUME_NONNULL_END
