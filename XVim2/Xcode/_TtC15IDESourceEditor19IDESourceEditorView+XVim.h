//
//  _TtC15IDESourceEditor19IDESourceEditorView+XVim.h
//  XVim2
//
//  Created by pebble8888 on 2018/03/31.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#ifndef _TtC15IDESourceEditor19IDESourceEditorView_XVim_h
#define _TtC15IDESourceEditor19IDESourceEditorView_XVim_h

@class XVimWindow;

#import "_TtC15IDESourceEditor19IDESourceEditorView.h"

@interface _TtC15IDESourceEditor19IDESourceEditorView (XVim)
+ (void)xvim_hook;
@property (strong, readonly) XVimWindow* xvim_window;
@end

#endif /* _TtC15IDESourceEditor19IDESourceEditorView_XVim_h */
