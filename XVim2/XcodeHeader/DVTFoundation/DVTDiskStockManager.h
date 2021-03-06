//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Sep 30 2020 21:18:12).
//
//  Copyright (C) 1997-2019 Steve Nygard.
//

#import <objc/NSObject.h>

@class DVTDispatchLock, NSMutableSet;

@interface DVTDiskStockManager : NSObject
{
    CDUnknownBlockType _cullingStrategyBlock;
    DVTDispatchLock *_diskStocksLock;
    NSMutableSet *_diskStocks;
}

+ (unsigned long long)_folderSize:(id)arg1;
+ (id)logAspect;
+ (id)defaultDiskStockManager;
- (void).cxx_destruct;
- (unsigned long long)_calculateSizeOfDiskStock:(id)arg1 members:(id)arg2;
- (void)cullAllDiskStocksOnQueue:(id)arg1 afterDelay:(double)arg2 withCompletionBlock:(CDUnknownBlockType)arg3;
- (void)cullAllDiskStocksOnQueue:(id)arg1 withCompletionBlock:(CDUnknownBlockType)arg2;
- (void)cullDiskStockSynchronously:(id)arg1;
- (id)diskStockForIdentifier:(id)arg1;
- (id)registeredDiskStocks;
- (void)registerDiskStock:(id)arg1;
- (id)initWithCullingStrategyBlock:(CDUnknownBlockType)arg1;
- (id)init;

@end

