//
//  XVimTestResultTableView.h
//  XVim2
//
//  Created by pebble8888 on 2019/10/31.
//  Copyright © 2019 Shuichiro Suzuki. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XVimTestCase.h"

NS_ASSUME_NONNULL_BEGIN
@protocol XVimTestResultTableViewDelegate
- (XVimTestCase *)objectAtIndex:(NSUInteger)index;
@end

@interface XVimTestResultTableView : NSTableView
@property (weak) id<XVimTestResultTableViewDelegate> testResultDelegate;
@end

NS_ASSUME_NONNULL_END
