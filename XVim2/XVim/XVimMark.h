//
//  XVimMark.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/21/13.
//
//

#import <Foundation/Foundation.h>

@interface XVimMark : NSObject
@property NSUInteger line;
@property NSUInteger column;
@property NSString* document;

- (id)initWithLine:(NSUInteger)line column:(NSUInteger)col document:(NSString*)doc;
- (id)initWithMark:(XVimMark*)mark;
- (void)setMark:(XVimMark*)mark;
+ (XVimMark *)markWithLine:(NSUInteger)line column:(NSUInteger)col document:(NSString*)doc;
@end
