//
//  XVimOptions.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface XVimOptions : NSObject
@property BOOL ignorecase;
@property BOOL wrapscan;
@property BOOL errorbells;
@property BOOL incsearch;
@property BOOL gdefault;
@property BOOL smartcase;
@property BOOL debug;
@property BOOL hlsearch;
@property (nonatomic) BOOL number;
@property (copy) NSString* clipboard;
@property (copy) NSString* guioptions;
@property (copy) NSString* timeoutlen;
@property NSString* laststatus;
@property BOOL vimregex; // XVim Original
@property BOOL relativenumber;
@property BOOL alwaysuseinputsource; // XVim original
@property BOOL blinkcursor;
@property BOOL startofline;
@property BOOL expandtab;
@property (nonatomic) NSDictionary* highlight;
@property (nonatomic, readonly) long long indentWidth;
@property (nonatomic, readonly) long long tabWidth;
@property (nonatomic, readonly) BOOL useTabsToIndent;
- (id)getOption:(NSString*)name;
- (void)setOption:(NSString*)name value:(id)value;
- (void)setOptionBool:(NSString*)name value:(BOOL)value;
- (BOOL)clipboardHasUnnamed;
@end

NS_ASSUME_NONNULL_END
