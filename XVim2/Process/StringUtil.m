//
//  StringUtil.m
//  XVim2
//
//  Created by pebble8888 on 2017/09/20.
//  Copyright © 2017年 Shuichiro Suzuki. All rights reserved.
//

#import "StringUtil.h"

@implementation StringUtil
+ (NSUInteger)lineWithPath:(NSString*)path pos:(NSUInteger)pos
{
    NSError* error;
    NSString* s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (s == nil){ return 0;}
    NSUInteger end = s.length;
    NSUInteger line = 1;
    for (NSUInteger i = 0; i < end && i < pos; ++i){
        unichar uc = [s characterAtIndex:i];
        if (uc == 0x0A){
            line += 1;
        }
    }
    return line;
}

@end
