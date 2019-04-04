//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Mar 30 2018 09:30:25).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <DVTKit/DVTDeviceApplicationProvider-Protocol.h>

@class NSError, NSString;

@protocol DVTDeviceApplicationInstaller <DVTDeviceApplicationProvider>
- (BOOL)uploadApplicationDataWithPath:(NSString *)arg1 forInstalledApplicationWithBundleIdentifier:(NSString *)arg2 error:(id *)arg3;
- (BOOL)downloadApplicationDataToPath:(NSString *)arg1 forInstalledApplicationWithBundleIdentifier:(NSString *)arg2 error:(id *)arg3;
- (NSError *)uninstallApplicationWithBundleIdentifierSync:(NSString *)arg1;
@end
