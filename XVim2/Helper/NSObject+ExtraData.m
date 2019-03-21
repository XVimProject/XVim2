//
//  NSObject+ExtraData.m
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//

#import "Logger.h"
#import "NSObject+ExtraData.h"
#import <objc/runtime.h>

static const NSString* EXTRA_DATA_KEY = @"EXTRADATAKEY";
@implementation NSObject (ExtraData)

- (id)extraDataForName:(NSString*)name
{
    NSMutableDictionary* dic = objc_getAssociatedObject(self, (__bridge const void*)(EXTRA_DATA_KEY));
    if (nil == dic) {
        return nil;
    }

    id ret = [dic objectForKey:name];
    if ([NSNull null] == ret) {
        return nil;
    }
    else {
        return ret;
    }
}

- (void)setExtraData:(id)data forName:(NSString*)name
{
    NSMutableDictionary* dic = objc_getAssociatedObject(self, (__bridge const void*)(EXTRA_DATA_KEY));
    if (nil == dic) {
        dic = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, (__bridge const void*)(EXTRA_DATA_KEY), dic, OBJC_ASSOCIATION_RETAIN);
    }

    if (nil == data) {
        data = [NSNull null];
    }
    [dic setObject:data forKey:name];
}

- (void)setBool:(BOOL)b forName:(NSString*)name
{
    NSNumber* n = [NSNumber numberWithBool:b];
    [self setExtraData:n forName:name];
}

- (BOOL)boolForName:(NSString*)name
{
    NSNumber* n = [self extraDataForName:name];
    return n ? n.boolValue : NO;
}

- (void)setUnsignedInteger:(NSUInteger)b forName:(NSString*)name
{
    NSNumber* n = [NSNumber numberWithUnsignedInteger:b];
    [self setExtraData:n forName:name];
}

- (NSUInteger)unsignedIntegerForName:(NSString*)name
{
    NSNumber* n = [self extraDataForName:name];
    return n ? n.unsignedIntegerValue : 0;
}

- (void)setInteger:(NSInteger)b forName:(NSString*)name
{
    NSNumber* n = [NSNumber numberWithInteger:b];
    [self setExtraData:n forName:name];
}

- (NSInteger)integerForName:(NSString*)name
{
    NSNumber* n = [self extraDataForName:name];
    return n ? n.integerValue : 0;
}

@end
