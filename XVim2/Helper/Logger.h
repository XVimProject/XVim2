//
//  Logger.h
//  XVim
//
//  Created by Shuichiro Suzuki on 12/25/11.
//  Copyright 2011 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>


#if defined DEBUG && !defined LOGGER_DISABLE_DEBUG && !defined LOGGER_DISABLE_ALL
#define DEBUG_LOG(fmt, ...)                                                                                            \
[Logger logWithLevel:LogDebug format:@"%s:%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__];
#else
#define DEBUG_LOG(fmt, ...)
#endif

#if defined DEBUG && !defined LOGGER_DISABLE_ALL
#define ERROR_LOG(fmt, ...)                                                                                            \
[Logger logWithLevel:LogError format:@"%s:%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]
#else
#define ERROR_LOG(fmt, ...)
#endif

#if defined UNIT_TEST
#define UNIT_TEST_LOG(fmt, ...)                                                                                            \
[Logger logWithLevel:LogDebug format:@"%s:%d " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]
#else
#define UNIT_TEST_LOG(fmt, ...)
#endif

typedef NS_ENUM(NSInteger, LogLevel) {
    LogDebug,
    LogError,
};

@class NSView;
@class NSMenu;

@interface Logger : NSObject

@property LogLevel level;
@property NSString* name;

+ (void)logWithLevel:(LogLevel)level format:(NSString*)format, ...;
+ (void)registerTracing:(NSString*)name;
+ (Logger*)defaultLogger;

- (id)initWithName:(NSString*)name; // "Root.MyPackage.MyComponent"
- (id)initWithName:(NSString*)n level:(LogLevel)l;

- (void)logWithLevel:(LogLevel)level format:(NSString*)format, ...;
- (void)logWithString:(NSString*)s;
- (void)setLogFile:(NSString*)path;

// Support Functions
+ (void)logStackTrace:(NSException*)ex;
+ (void)traceMethodList:(NSString*)class;
+ (void)logAvailableClasses:(LogLevel)level;
+ (void)traceViewInfo:(NSView*)obj subView:(BOOL)sub;
+ (void)traceView:(NSView*)view depth:(NSUInteger)depth;
+ (void)traceMenu:(NSMenu*)menu;
@end
