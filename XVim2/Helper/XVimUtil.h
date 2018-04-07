//
//  XVimUtil.h
//  XVim2
//
//  Created by pebble8888 on 2018/04/06.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#ifndef XVimUtil_h
#define XVimUtil_h

#import <Foundation/Foundation.h>

NSRange NSMakeNormalizedRangeFromRange(NSRange r, NSUInteger maxloc);
NSRange NSMakeNormalizedRange(NSUInteger loc, NSUInteger len, NSUInteger maxloc);

#endif /* XVimUtil_h */
