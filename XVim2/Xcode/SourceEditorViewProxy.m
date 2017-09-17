//
//  SourceEditorProxy.m
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import "SourceEditorViewProxy.h"
#import "rd_route.h"

static void(*fpSetCursorStyle)(int style, id obj);

@implementation SourceEditorViewProxy

+ (void)initialize
{
    if (self == [SourceEditorViewProxy class]) {
        // SourceEditorView.cursorStyle.setter
        fpSetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofs", NULL);
    }
}

-(instancetype)initWithSourceEditorView:(SourceEditorView*)sourceEditorView
{
    self = [super init];
    if (self) {
        self.sourceEditorView = sourceEditorView;
    }
    return self;
 }


-(void)setCursorStyle:(CursorStyle)cursorStyle
{
    void * sev = (__bridge_retained void *)self.sourceEditorView;
    
    __asm__ (
             "movq %0, %%rdi\n\t" /* Argument 1 */
             "movq %1, %%r13\n\t" /* Calling context 'self' */
             "call *%2\n"
                     : /* no output */
                     : "r" (cursorStyle)
                     , "r" (sev)
                     , "m" (fpSetCursorStyle)
                     : "memory", "cc");

}

-(CursorStyle)cursorStyle {
    return 0;
}
@end
