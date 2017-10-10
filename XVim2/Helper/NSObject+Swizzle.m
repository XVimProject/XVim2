//
//  NSObject+XVimAdditions.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <objc/runtime.h>
#import "NSObject+Swizzle.h"

@implementation NSObject (Swizzle)


+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel of:(Class)c2{
    Method origMethod = class_getClassMethod(self, origSel);
    Method newMethod  = class_getClassMethod(c2, newSel);
    Class class = object_getClass(self); // meta class for self
    Class class2 = object_getClass(c2);  // meta class for c2

    NSAssert(origMethod, @"+[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(origSel));
    NSAssert(newMethod,  @"+[%@ %@] doesn't exist", NSStringFromClass(c2), NSStringFromSelector(newSel));
    if (class_addMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        class_replaceMethod(class2, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel
{
    [self xvim_swizzleClassMethod:origSel with:newSel of:self];
}


+ (void)xvim_swizzleInstanceMethodOfClass:(Class)destClass selector:(SEL)origSel with:(SEL)newSel
{
    Method origMethod = class_getInstanceMethod(destClass, origSel);
    Method newMethod  = class_getInstanceMethod(self, newSel);

    NSAssert(newMethod,  @"-[%@ %@] doesn't exist", NSStringFromClass(destClass), NSStringFromSelector(newSel));

    if (class_addMethod(destClass, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(destClass, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        class_replaceMethod(destClass, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel
{
        [self xvim_swizzleInstanceMethodOfClass:self selector:origSel with:newSel];
}

@end

