//
//  XVimUtil.m
//  XVim2
//
//  Created by pebble8888 on 2018/04/06.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#import "XVimUtil.h"

NSRange NSMakeNormalizedRangeFromRange(NSRange r, NSUInteger maxloc)
{
    _auto begin = r.location;
    _auto end = r.location + r.length;
    if (maxloc < begin){
        begin = maxloc;
    }
    if (maxloc < end){
        end = maxloc;
    }
    return NSMakeRange(begin, end - begin);
}

NSRange NSMakeNormalizedRange(NSUInteger loc, NSUInteger len, NSUInteger maxloc)
{
    _auto r = NSMakeRange(loc, len);
    return NSMakeNormalizedRangeFromRange(r, maxloc);
}
