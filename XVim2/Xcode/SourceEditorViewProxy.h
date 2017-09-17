//
//  SourceEditorProxy.h
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "_TtC12SourceEditor16SourceEditorView.h"

typedef NS_ENUM(NSInteger, CursorStyle) {
        CursorStyleVerticalBar
        , CursorStyleBlock
        , CursorStyleUnderline
};

typedef _TtC12SourceEditor16SourceEditorView SourceEditorView;

@interface SourceEditorViewProxy : NSObject
@property CursorStyle cursorStyle;
@property (unsafe_unretained) SourceEditorView *sourceEditorView;

-(instancetype)initWithSourceEditorView:(SourceEditorView*)sourceEditorView;
@end
