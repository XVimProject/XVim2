//
//  SourceCodeEditorViewWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("scev_wrapper_call") func _get_cursor_style(_:UnsafeRawPointer) -> (CursorStyle)
@_silgen_name("scev_wrapper_call2") func _set_cursor_style(_:UnsafeRawPointer, _:CursorStyle) -> ()
@_silgen_name("scev_wrapper_call3") func _get_data_source(_:UnsafeRawPointer) -> (UnsafeMutableRawPointer)
@_silgen_name("scev_wrapper_call4") func _set_selected_range(_:UnsafeRawPointer, _:XVimSourceEditorRange, modifiers:UInt32) -> ()
@_silgen_name("scev_wrapper_call5") func _add_selected_range(_:UnsafeRawPointer, _:XVimSourceEditorRange, modifiers:UInt32) -> ()
@_silgen_name("scev_wrapper_call6") func _scev_voidToInt(_:UnsafeRawPointer) -> (Int)

fileprivate struct _SourceCodeEditorViewWrapper {

    let contextPtr = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(capacity: 8)

    init?(_ view : AnyObject?, _ functionPtr : UnsafeMutableRawPointer?) {
        
        guard let sourceCodeEditorView = view,
            let fp = functionPtr else {return nil}
        
        contextPtr[0] = Unmanaged.passRetained(sourceCodeEditorView).toOpaque()
        contextPtr[1] = fp
    }
    
    func voidToInt() -> Int {
        return _scev_voidToInt(contextPtr)
    }

    func getCursorStyle() -> CursorStyle {
        // return CursorStyle.block
        return _get_cursor_style(contextPtr)
    }
    func setCursorStyle(_ style: CursorStyle) {
        _set_cursor_style(contextPtr, style)
    }
    
    func getDataSource() -> AnyObject? {
        return Unmanaged.fromOpaque(_get_data_source(contextPtr).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue()
    }
    func addSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        _add_selected_range(contextPtr, range, modifiers: modifiers.rawValue)
    }
    func setSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        _set_selected_range(contextPtr, range, modifiers: modifiers.rawValue)
    }
}




class SourceCodeEditorViewWrapper: NSObject {
    private let fpSetCursorStyle = function_ptr_from_name("__T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ovs", nil)
    private let fpGetCursorStyle = function_ptr_from_name("__T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ovg", nil);
    private let fpGetDataSource = function_ptr_from_name("__T012SourceEditor0aB4ViewC04dataA0AA0ab4DataA0Cvg", nil);
    private let fpSetSelectedRangeWithModifiers = function_ptr_from_name("_T012SourceEditor0aB4ViewC16setSelectedRangeyAA0abF0V_AA0aB18SelectionModifiersV9modifierstF", nil);
    private let fpAddSelectedRangeWithModifiers = function_ptr_from_name("_T012SourceEditor0aB4ViewC16addSelectedRangeyAA0abF0V_AA0aB18SelectionModifiersV9modifierstF", nil);

    private let fpFuncLinesPerPage =
        function_ptr_from_name("_T012SourceEditor0aB4ViewC12linesPerPageSiyF", nil)
    
    private weak var editorViewProxy : SourceCodeEditorViewProxy?
    
    @objc
    lazy public var dataSourceWrapper = {
        return SourceEditorDataSourceWrapper(withSourceCodeEditorViewWrapper: self)
    }()
    
    @objc
    public init(withProxy proxy:SourceCodeEditorViewProxy) {
        editorViewProxy = proxy
    }
    
    private var editorView : AnyObject? {
        return editorViewProxy?.view
    }
    
    @objc
    var cursorStyle : CursorStyle {
        get {
            return _SourceCodeEditorViewWrapper(editorView, fpGetCursorStyle)?.getCursorStyle() ?? CursorStyle.block
        }
        set {
            _SourceCodeEditorViewWrapper(editorView, fpSetCursorStyle)?.setCursorStyle(newValue)
        }
    }
    
    @objc
    var dataSource : AnyObject? {
        return _SourceCodeEditorViewWrapper(editorView, fpGetDataSource)?.getDataSource()
    }
    
    @objc
    public func addSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers) -> Void
    {
        _SourceCodeEditorViewWrapper(editorView, fpAddSelectedRangeWithModifiers)?.addSelectedRange(range, modifiers: modifiers)
    }
    
    @objc
    public func setSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        _SourceCodeEditorViewWrapper(editorView, fpSetSelectedRangeWithModifiers)?.setSelectedRange(range, modifiers: modifiers)
    }
    
    @objc
    public func linesPerPage() -> Int
    {
        return _SourceCodeEditorViewWrapper(editorView, fpFuncLinesPerPage)?.voidToInt() ?? 0
    }
    
}

