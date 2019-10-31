//
//  SourceEditorSelectionDisplay.m
//  XVim2
//
//  Created by Librecz Gábor on 2019. 04. 27..
//  Copyright © 2019. Shuichiro Suzuki. All rights reserved.
//

#import "XVimSourceEditorSelectionDisplay.h"

#import "NSObject+Swizzle.h"
#import "_TtC12SourceEditor28SourceEditorSelectionDisplay.h"
#import "XVimXcode.h"
#import "XVim.h"
#import "XVimOptions.h"

@implementation XVimSourceEditorSelectionDisplay

+ (void)xvim_hook
{
    [self
   xvim_swizzleInstanceMethodOfClassName:SourceEditorSelectionDisplayClassName
     selector:@selector(cursorBlinkTimerFired:)
     with:@selector(xvim_cursorBlinkTimerFired:)];
}

- (void)xvim_cursorBlinkTimerFired:(id)arg1
{
    if (!XVim.instance.options.blinkcursor) {
      return;
    }

    [self xvim_cursorBlinkTimerFired: arg1];
}

@end
