//
//  SourceCodeEditorViewWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("wrapper_call") func _get_cursor_style() -> ()
@_silgen_name("wrapper_call2") func _set_cursor_style(_:CursorStyle) -> ()


class SourceCodeEditorViewWrapper: NSObject {

    private var sourceCodeEditorViewPtr : UnsafeMutableRawPointer
    private var functionToCallPtr : UnsafeMutableRawPointer
    private var savedr12 : UnsafeMutableRawPointer
    private var rax : UnsafeMutableRawPointer
    private var rdx : UnsafeMutableRawPointer

    private let fpSetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofs", nil);
    private let fpGetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofg", nil);

    private weak var editorViewProxy : SourceCodeEditorViewProxy?
    
    public init(withProxy proxy:SourceCodeEditorViewProxy) {
        editorViewProxy = proxy
        sourceCodeEditorViewPtr = unsafeBitCast(proxy.view, to:UnsafeMutableRawPointer.self)
        functionToCallPtr = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        savedr12 = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        rax = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        rdx = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
    }
    
    var cursorStyle : CursorStyle {
        get {
            if !prepareCall(fpGetCursorStyle!) {return .verticalBar}
            _get_cursor_style();
            return CursorStyle(rawValue:NSNumber(value: UInt(bitPattern:rax)).int8Value)!
        }
        set {
            if !prepareCall(fpSetCursorStyle!) {return}
            _set_cursor_style(newValue);
        }
    }
    
    // PRIVATE
    // =======
    
    private func prepareCall(_ funcPtr: UnsafeMutableRawPointer) -> Bool
    {
        guard let evp = editorViewProxy else {return false}
        if evp.view == nil {return false}
        sourceCodeEditorViewPtr = unsafeBitCast(evp.view, to:UnsafeMutableRawPointer.self)
        functionToCallPtr = funcPtr
        return true
    }
    

}
