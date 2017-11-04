//
//  SourceCodeEditorViewWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("scev_wrapper_call") func _get_cursor_style(_:UnsafeRawPointer) -> ()
@_silgen_name("scev_wrapper_call2") func _set_cursor_style(_:UnsafeRawPointer, _:CursorStyle) -> ()
@_silgen_name("scev_wrapper_call3") func _get_data_source(_:UnsafeRawPointer) -> ()
@_silgen_name("scev_wrapper_call4") func _set_selected_range(_:UnsafeRawPointer, _:XVimSourceEditorRange, modifiers:UInt32) -> ()
@_silgen_name("scev_wrapper_call5") func _add_selected_range(_:UnsafeRawPointer, _:XVimSourceEditorRange, modifiers:UInt32) -> ()
@_silgen_name("scev_wrapper_call6") func _get_text_storage(_:UnsafeRawPointer) -> ()


class SourceCodeEditorViewWrapper: NSObject {

    let a: UInt64 = 0xaaaaaaaaaaaaaaaa
    private var sourceCodeEditorViewPtr : UnsafeMutableRawPointer // 16
    private var functionToCallPtr : UnsafeMutableRawPointer // 24
    private var rax : UnsafeMutableRawPointer // 32
    private var rdx : UnsafeMutableRawPointer // 40

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
        sourceCodeEditorViewPtr = unsafeBitCast(proxy.view, to:UnsafeMutableRawPointer.self)
        functionToCallPtr = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        rax = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        rdx = unsafeBitCast(fpSetCursorStyle, to: UnsafeMutableRawPointer.self)
        
    }
    
    @objc
    var cursorStyle : CursorStyle {
        get {
            doCall(fpGetCursorStyle) {rawSelf, sourceCodeEditorView in
                _get_cursor_style(rawSelf);
            }
            return CursorStyle(rawValue:NSNumber(value: UInt(bitPattern:rax)).int8Value)!
        }
        set {
            doCall(fpSetCursorStyle) {rawSelf, sourceCodeEditorView in
                _set_cursor_style(rawSelf, newValue);
            }
        }
    }
    
    @objc
    var dataSource : AnyObject? {
        let result = doCall(fpGetDataSource) { rawSelf, sourceCodeEditorView in
                _get_data_source(rawSelf)
        }
        
        return !result || UnsafeMutableRawPointer(bitPattern: 0)?.distance(to:rax) == 0
            ? nil
            : Unmanaged.fromOpaque(rax).retain().autorelease().takeRetainedValue()
    }
    
    @objc
    var textStorage : NSTextStorage? {
        let result = doCall(fpGetTextStorage) { rawSelf, sourceCodeEditorView in
            _get_text_storage(rawSelf)
        }
        
        return !result || UnsafeMutableRawPointer(bitPattern: 0)?.distance(to:rax) == 0
            ? nil
            : Unmanaged.fromOpaque(rax).retain().autorelease().takeRetainedValue()
    }
    
    @objc
    public func addSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        doCall(fpAddSelectedRangeWithModifiers) { rawSelf, sourceCodeEditorView in
            _add_selected_range(rawSelf, range, modifiers: modifiers.rawValue)
        }
    }
    
    @objc
    public func setSelectedRange(_ range:XVimSourceEditorRange, modifiers:XVimSelectionModifiers)
    {
        doCall(fpSetSelectedRangeWithModifiers) { rawSelf, sourceCodeEditorView in
            _set_selected_range(rawSelf, range, modifiers: modifiers.rawValue)
        }
    }
    
    // PRIVATE
    // =======
    

    @discardableResult
    private func doCall(_ funcPtr: UnsafeMutableRawPointer?, block: (UnsafeRawPointer, AnyObject)->()) -> Bool
    {
        guard let evp = editorViewProxy,
            let scev = evp.view,
            let fp = funcPtr else {return false}

        let byteCount = 8 * 4
        let rawSelf = Unmanaged.toOpaque(Unmanaged.passUnretained(self))()
        let ptr = UnsafeMutablePointer<UInt8>(rawSelf.assumingMemoryBound(to: UInt8.self))
        memset_s(ptr+16, byteCount, 0x00, byteCount)
        
        sourceCodeEditorViewPtr = unsafeBitCast(scev, to:UnsafeMutableRawPointer.self)
        functionToCallPtr = fp
        block(rawSelf, scev)
        return true;
    }

}
