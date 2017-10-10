//
//  NSObject+ExtraData.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (ExtraData)
- (id)extraDataForName:(NSString*)name;
- (void)setExtraData:(id)data forName:(NSString*)name;

// Utilities
- (void)setBool:(BOOL)value forName:(NSString*)name;
- (BOOL)boolForName:(NSString*)name;
- (void)setUnsignedInteger:(NSUInteger)value forName:(NSString*)name;
- (NSUInteger)unsignedIntegerForName:(NSString*)name;
- (void)setInteger:(NSInteger)value forName:(NSString*)name;
- (NSInteger)integerForName:(NSString*)name;
@end
