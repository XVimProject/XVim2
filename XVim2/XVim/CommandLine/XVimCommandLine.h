//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandField.h"
#import <AppKit/AppKit.h>

@interface XVimCommandLine : NSVisualEffectView

- (id)init;
- (void)setModeString:(NSString*)string;
- (void)setArgumentString:(NSString*)string;
- (void)errorMessage:(NSString*)string Timer:(BOOL)aTimer RedColorSetting:(BOOL)aRedColorSetting;
#ifdef TODO
- (void)quickFixWithString:(NSString*)string completionHandler:(void (^)(void))completionHandler;
- (NSUInteger)quickFixColWidth;
#endif
- (XVimCommandField*)commandField;
@property (nonatomic, getter=isModeHidden) BOOL modeHidden;
@end
