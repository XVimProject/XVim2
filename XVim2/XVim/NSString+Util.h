//
//  NSString+Util.h
//  XVim2
//
//  Created by pebble8888 on 2017/09/20.
//  Copyright © 2017年 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (Util)
+ (NSUInteger)lineWithPath:(NSString*)path pos:(NSUInteger)pos;
@end

NS_ASSUME_NONNULL_END
