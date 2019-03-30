//
//  XVimRangeUtil.m
//
//  Created by pebble8888 on 2018/04/06.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#import "XVimRangeUtil.h"

NSRange NSMakeNormalizedRangeFromRange(NSRange r, NSUInteger maxloc)
{
    var begin = r.location;
    var end = r.location + r.length;
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
    let r = NSMakeRange(loc, len);
    return NSMakeNormalizedRangeFromRange(r, maxloc);
}
