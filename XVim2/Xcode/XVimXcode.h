//
//  XVimXcode.h
//  XVim2
//
//  Created by pebble8888 on 2018/03/31.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

#ifndef XVimXcode_h
#define XVimXcode_h

@class _TtC22IDEPegasusSourceEditor16SourceCodeEditor;
@class _TtC22IDEPegasusSourceEditor20SourceCodeEditorView;
@class _TtC12SourceEditor16SourceEditorView;
@class _TtC12SourceEditor23SourceEditorContentView;
@class _TtC12SourceEditor23SourceEditorUndoManager;

typedef _TtC22IDEPegasusSourceEditor16SourceCodeEditor SourceCodeEditor;
typedef _TtC22IDEPegasusSourceEditor20SourceCodeEditorView SourceCodeEditorView;
typedef _TtC12SourceEditor16SourceEditorView SourceEditorView;
typedef _TtC12SourceEditor23SourceEditorContentView SourceEditorContentView;
typedef _TtC12SourceEditor23SourceEditorUndoManager SourceEditorUndoManager;

static NSString * const IDEPegasusSourceCodeEditorViewClassName
    = @"IDEPegasusSourceEditor.SourceCodeEditorView";

static NSString * const SourceEditorViewClassName
    = @"SourceEditor.SourceEditorView";

#endif /* XVimXcode_h */
