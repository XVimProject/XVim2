//
//  SourceEditorContentView.m
//  XVim2
//
//  Created by Ant on 10/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_TtC12SourceEditor23SourceEditorContentView.h"
#import "NSObject+Swizzle.h"

@interface SourceEditorContentView_xvim : NSObject
-(NSEdgeInsets) xvim_contentMargins;
@end

@implementation SourceEditorContentView_xvim

-(NSEdgeInsets)xvim_contentMargins {
        NSEdgeInsets insets = [self xvim_contentMargins];
        insets.bottom -= 30;
        return insets;
}
-(void)xvim_layoutIfNeeded {
        [self xvim_layoutIfNeeded];
}
@end



run_before_main(SourceEditorContentView) {
        [SourceEditorContentView_xvim xvim_swizzleInstanceMethodOfClass:NSClassFromString(@"_TtC12SourceEditor23SourceEditorContentView")
                                                               selector:@selector(contentMargins)
                                                                   with:@selector(xvim_contentMargins)];
        [SourceEditorContentView_xvim xvim_swizzleInstanceMethodOfClass:NSClassFromString(@"_TtC12SourceEditor23SourceEditorContentView")
                                                               selector:@selector(layoutIfNeeded)
                                                                   with:@selector(xvim_layoutIfNeeded)];
}
