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

typedef enum {
    CURSOR_MODE_INSERT,
    CURSOR_MODE_COMMAND
}CURSOR_MODE;


@interface SourceCodeEditorViewProxy : NSObject <SourceViewProtocol>
@property CursorStyle cursorStyle;
@property (unsafe_unretained) SourceCodeEditorView *sourceCodeEditorView;
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
@property(readonly) CURSOR_MODE cursorMode;
@property(readonly) NSURL* documentURL;
@property BOOL needsUpdateFoundRanges;
@property(readonly) NSArray* foundRanges;
@property(readonly) long long currentLineNumber;

-(instancetype)initWithSourceCodeEditorView:(SourceCodeEditorView*)sourceEditorView;
@end
