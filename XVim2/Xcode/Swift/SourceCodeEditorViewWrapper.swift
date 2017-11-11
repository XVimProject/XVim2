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
@_silgen_name("scev_wrapper_call6") func _get_text_storage(_:UnsafeRawPointer) -> (UnsafeMutableRawPointer)


class SourceCodeEditorViewWrapper: NSObject {

    let context : UnsafeMutableRawPointer = malloc(2 * 8)!
    let contextPtr : UnsafeMutableBufferPointer<UnsafeMutableRawPointer>!


    private let fpSetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofs", nil);
    private let fpGetCursorStyle = function_ptr_from_name("_T012SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ofg", nil);
    private let fpGetDataSource = function_ptr_from_name("_T012SourceEditor0aB4ViewC04dataA0AA0ab4DataA0Cfg", nil);
    private let fpSetSelectedRangeWithModifiers = function_ptr_from_name("_T012SourceEditor0aB4ViewC16setSelectedRangeyAA0abF0V_AA0aB18SelectionModifiersV9modifierstF", nil);
    private let fpAddSelectedRangeWithModifiers = function_ptr_from_name("_T012SourceEditor0aB4ViewC16addSelectedRangeyAA0abF0V_AA0aB18SelectionModifiersV9modifierstF", nil);
    private let fpGetTextStorage = function_ptr_from_name("_T022IDEPegasusSourceEditor0B12CodeDocumentC16sdefSupport_textSo13NSTextStorageCyF", nil);

    private weak var editorViewProxy : SourceCodeEditorViewProxy?
    
    @objc
    lazy public var dataSourceWrapper = {
        return SourceEditorDataSourceWrapper(withSourceCodeEditorViewWrapper: self)
    }()
    
    @objc
    public init(withProxy proxy:SourceCodeEditorViewProxy) {
        editorViewProxy = proxy
        contextPtr = UnsafeMutableBufferPointer<UnsafeMutableRawPointer>(start: context.assumingMemoryBound(to: UnsafeMutableRawPointer.self), count: 2)
    }
    
    deinit {
        free(context)
    }
    
    @objc
    var cursorStyle : CursorStyle {
        get {
            return doCall(fpGetCursorStyle) ? _get_cursor_style(context) : CursorStyle.block
        }
        set {
            if doCall(fpSetCursorStyle) {
                _set_cursor_style(context, newValue)
            }
        }
    }
    
    @objc
    var dataSource : AnyObject? {
        return doCall(fpGetDataSource) ? Unmanaged.fromOpaque(_get_data_source(context).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue() : nil
    }
    
    @objc
    var textStorage : NSTextStorage? {
        return doCall(fpGetTextStorage) ? Unmanaged.fromOpaque(_get_text_storage(context).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue() : nil
    }
    
    @objc
    public func addSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        if doCall(fpAddSelectedRangeWithModifiers) {
            _add_selected_range(context, range, modifiers: modifiers.rawValue)
        }
    }
    
    @objc
    public func setSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        if doCall(fpSetSelectedRangeWithModifiers) {
            _set_selected_range(context, range, modifiers: modifiers.rawValue)
        }
    }
    
    // PRIVATE
    // =======
    

    @discardableResult
    private func doCall(_ funcPtr: UnsafeMutableRawPointer?) -> Bool
    {
        guard let evp = editorViewProxy,
            let scev = evp.view,
            let fp = funcPtr else {return false}

        let sourceCodeEditorViewPtr = Unmanaged.passRetained(scev).toOpaque()
        contextPtr[0] = sourceCodeEditorViewPtr
        contextPtr[1] = fp
        
        return true;
    }

}
