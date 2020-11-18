//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  6 2019 20:12:56).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <objc/NSObject.h>

#import <IDEKit/IDEPlaygroundDataHandler-Protocol.h>
#import <IDEKit/IDEPlaygroundDataHandlerDelegate-Protocol.h>

@class NSMapTable, NSString;
@protocol IDEPlaygroundDataHandlerDelegate;

@interface IDEPlaygroundDataHandler : NSObject <IDEPlaygroundDataHandlerDelegate, IDEPlaygroundDataHandler>
{
    NSMapTable *_dataHandlerToIdentifierMapTable;
    id <IDEPlaygroundDataHandlerDelegate> _delegate;
}

@property __weak id <IDEPlaygroundDataHandlerDelegate> delegate; // @synthesize delegate=_delegate;
- (void).cxx_destruct;
- (void)playgroundDataHandlerDidDecodeFinishExpressionResult:(id)arg1;
- (void)playgroundDataHandler:(id)arg1 didDecodeResult:(id)arg2;
- (BOOL)handlePlaygroundData:(id)arg1 dataIdentifier:(id)arg2 resultDate:(id)arg3 dataVersion:(unsigned long long)arg4 executionParameters:(id)arg5 error:(id *)arg6;
- (id)init;

// Remaining properties
@property(readonly, copy) NSString *debugDescription;
@property(readonly, copy) NSString *description;
@property(readonly) unsigned long long hash;
@property(readonly) Class superclass;

@end
