//
//  SourceEditorProxy.h
//  XVim2
//
//  Created by Anthony Dervish on 16/09/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceViewProtocol.h"
#import "IDEPegasusSourceEditor/_TtC22IDEPegasusSourceEditor20SourceCodeEditorView.h"

typedef NS_ENUM(NSInteger, CursorStyle) {
        CursorStyleVerticalBar
        , CursorStyleBlock
        , CursorStyleUnderline
};

@protocol XVimTextViewDelegateProtocol;

@interface SourceCodeEditorViewProxy : NSObject <SourceViewProtocol>
@property CursorStyle cursorStyle;
@property (weak) SourceCodeEditorView *sourceCodeEditorView;
@property(readonly) XVIM_VISUAL_MODE selectionMode;
@property(readonly) NSUInteger insertionPoint;
@property(readonly) XVimPosition insertionPosition;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger preservedColumn;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) XVimPosition selectionBeginPosition;
@property(readonly) NSUInteger numberOfSelectedLines;
@property(readonly) BOOL selectionToEOL;
@property CURSOR_MODE cursorMode;
@property(readonly) NSURL* documentURL;
@property BOOL needsUpdateFoundRanges;
@property(readonly) NSArray* foundRanges;
@property(readonly) long long currentLineNumber;
@property(strong) id<XVimTextViewDelegateProtocol> xvimDelegate;

-(instancetype)initWithSourceCodeEditorView:(SourceCodeEditorView*)sourceEditorView;
@end

#import "SourceCodeEditorViewProxy+Scrolling.h"
#import "SourceCodeEditorViewProxy+Operations.h"
#import "SourceCodeEditorViewProxy+Yank.h"
