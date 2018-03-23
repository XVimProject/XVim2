//
//  NSObject+XVimAdditions.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import "NSObject+Swizzle.h"
#import <objc/runtime.h>

Method xvim_getClassSpecificInstanceMethod(Class aClass, SEL aSelector);

@implementation NSObject (Swizzle)


+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel of:(Class)c2
{
    Method origMethod = class_getClassMethod(self, origSel);
    Method newMethod = class_getClassMethod(c2, newSel);
    Class class = object_getClass(self); // meta class for self
    Class class2 = object_getClass(c2); // meta class for c2

    NSAssert(origMethod, @"+[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(origSel));
    NSAssert(newMethod, @"+[%@ %@] doesn't exist", NSStringFromClass(c2), NSStringFromSelector(newSel));
    if (class_addMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        class_replaceMethod(class2, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    }
    else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel
{
    [self xvim_swizzleClassMethod:origSel with:newSel of:self];
}

static void xvim_methodAdd(Class targetClass, Class tempHolderClass, SEL targetSelector, BOOL skipIfMethodAlreadyPresent)
{
    // Check for an existing method of the same name 'blocking' the new method
    Method origMethod __unused = xvim_getClassSpecificInstanceMethod(targetClass, targetSelector);
    NSCAssert(origMethod == NULL || skipIfMethodAlreadyPresent, @"ADDMETHOD ERROR: target class %@ already has method %@.", NSStringFromClass(targetClass), NSStringFromSelector(targetSelector));
    
    Method newMethod = class_getInstanceMethod(tempHolderClass, targetSelector);
    NSCAssert(newMethod != NULL, @"ADDMETHOD ERROR: holder class %@ does not contain source method %@.", NSStringFromClass(tempHolderClass), NSStringFromSelector(targetSelector));
    
    class_addMethod(targetClass, targetSelector, method_getImplementation(newMethod),
                    method_getTypeEncoding(newMethod));
}

Method xvim_getClassSpecificInstanceMethod(Class aClass, SEL aSelector)
{
    unsigned methodCount = 0;
    Method* methods = class_copyMethodList(aClass, &methodCount);
    Method foundMethod = NULL;
    
    for (unsigned methodIndex = 0; methodIndex < methodCount; ++methodIndex) {
        if (method_getName(methods[methodIndex]) == aSelector) {
            foundMethod = methods[methodIndex];
            break;
        }
    }
    
    free(methods);
    return foundMethod;
}

static void xvim_methodSwizzle(Class targetClass, Class tempHolderClass,
                       SEL targetMethod, SEL swizzledSelector)
{
    Method newMethod = class_getInstanceMethod(tempHolderClass, swizzledSelector);
    NSCAssert(newMethod != NULL, @"SWIZZLE ERROR: Holder class %@ does not contain source method %@.", NSStringFromClass(tempHolderClass), NSStringFromSelector(swizzledSelector));
    Method origMethod = xvim_getClassSpecificInstanceMethod(targetClass, targetMethod);
    NSCAssert(origMethod != NULL, @"SWIZZLE ERROR: Could not find method %@ in target class %@.", NSStringFromSelector(targetMethod), NSStringFromClass(targetClass));
    
    BOOL added __unused = class_addMethod(targetClass, swizzledSelector, method_getImplementation(newMethod),
                                          method_getTypeEncoding(newMethod));
    NSCAssert(added, @"SWIZZLE ERROR: Could not add method %@ to class %@", NSStringFromSelector(swizzledSelector), NSStringFromClass(targetClass));
    newMethod = class_getInstanceMethod(targetClass, swizzledSelector);
    method_exchangeImplementations(origMethod, newMethod);
}


+ (void)xvim_swizzleInstanceMethodOfClass:(Class)destClass selector:(SEL)origSel with:(SEL)newSel
{
    xvim_methodSwizzle(destClass, self, origSel, newSel);
}

+ (void)xvim_swizzleInstanceMethodOfClassName:(const NSString*)destClassName selector:(SEL)origSel with:(SEL)newSel
{
    [self xvim_swizzleInstanceMethodOfClass:NSClassFromString((NSString*)destClassName) selector:origSel with:newSel];
}

+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel
{
    [self xvim_swizzleInstanceMethodOfClass:self selector:origSel with:newSel];
}

+ (void)xvim_addInstanceMethod:(SEL)sel toClass:(Class)destClass
{
    xvim_methodAdd(destClass, self, sel, NO);
}

+ (void)xvim_addInstanceMethod:(SEL)sel toClassName:(NSString*)destClassName
{
    xvim_methodAdd(NSClassFromString(destClassName), self, sel, NO);
}

@end
