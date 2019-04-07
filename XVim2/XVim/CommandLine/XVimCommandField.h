//
//  XVimCommandField.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>

@class XVimKeyStroke;
@class XVimWindow;

@interface XVimCommandField : NSTextView
- (void)setWindow:(XVimWindow * _Nullable)window;
- (void)handleKeyStroke:(XVimKeyStroke* _Nonnull)keyStroke inWindow:(XVimWindow* _Nullable)window;
@end
