//
//  SourceCodeEditorViewWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

// cd XcodeHeader/DVTSourceEditor
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/DVTSourceEditor.framework/DVTSourceEditor
// cd XcodeHeader/IDESourceEditor 
// class-dump -H /Applications/Xcode.app/Contents/Plugins/IDESourceEditor.framework/IDESourceEditor
// cd XcodeHeader/SourceEditor
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/SourceEditor.framework/SourceEditor
// cd XcodeHeader/DVTFoundation
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/DVTFoundation.framework/DVTFoundation
// cd XcodeHeader/DVTKit
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/DVTKit.framework/DVTKit
// cd XcodeHeader/IDEKit
// class-dump -H /Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/IDEKit
// cd XcodeHeader/DVTViewControllerKit
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/DVTViewControllerKit.framework/DVTViewControllerKit
// cd XcodeHeader/DVTCocoaAdditionsKit
// class-dump -H /Applications/Xcode.app/Contents/SharedFrameworks/DVTCocoaAdditionsKit.framework/DVTCocoaAdditionsKit
//
//
// demangle prefix
// Swift 4 "_T0"
// Swift 4.x "$S", "_$S"
// Swift 5+ "$s", "_$s"

import Cocoa

// nm /Applications/Xcode.app/Contents/SharedFrameworks/SourceEditor.framework/SourceEditor > SourceEditor.txt
// nm /Applications/Xcode.app/Contents/PlugIns/IDESourceEditor.framework/IDESourceEditor > IDESourceEditor.txt

// swift demangle '_$s12SourceEditor0aB4ViewC16setSelectedRange_9modifiersyAA0abF0V_AA0aB18SelectionModifiersVtF'
//   _$s12SourceEditor0aB4ViewC16setSelectedRange_9modifiersyAA0abF0V_AA0aB18SelectionModifiersVtF --->
//   SourceEditor.SourceEditorView.setSelectedRange(_: SourceEditor.SourceEditorRange, modifiers: SourceEditor.SourceEditorSelectionModifiers) -> ()
//
// swift demangle '_$s12SourceEditor0aB4ViewC16addSelectedRange_9modifiers15scrollPlacement12alwaysScrollyAA0abF0V_AA0aB18SelectionModifiersVAA0kI0OSgSbtF'
//   _$s12SourceEditor0aB4ViewC16addSelectedRange_9modifiers15scrollPlacement12alwaysScrollyAA0abF0V_AA0aB18SelectionModifiersVAA0kI0OSgSbtF --->
//   SourceEditor.SourceEditorView.addSelectedRange(_: SourceEditor.SourceEditorRange, modifiers: SourceEditor.SourceEditorSelectionModifiers, scrollPlacement: SourceEditor.ScrollPlacement?, alwaysScroll: Swift.Bool) -> ()

@_silgen_name("scev_wrapper_call") func _get_cursor_style(_: UnsafeRawPointer) -> (CursorStyle)
@_silgen_name("scev_wrapper_call2") func _set_cursor_style(_: UnsafeRawPointer, _: CursorStyle) -> Void
@_silgen_name("scev_wrapper_call3") func _get_data_source(_: UnsafeRawPointer) -> (UnsafeMutableRawPointer)
@_silgen_name("scev_wrapper_call4") func _set_selected_range(_: UnsafeRawPointer, _: XVimSourceEditorRange, modifiers: Int) -> Void
@_silgen_name("scev_wrapper_call5") func _add_selected_range(_: UnsafeRawPointer, _: XVimSourceEditorRange, modifiers: Int) -> Void
@_silgen_name("scev_wrapper_call6") func _scev_voidToInt(_: UnsafeRawPointer) -> (Int)

fileprivate struct SourceCodeEditorViewInvoker {
    let contextPtr = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(capacity: 8)
    init?(_ view: AnyObject?, _ functionPtr: UnsafeMutableRawPointer?) {
        
        guard let sourceCodeEditorView = view,
            let functionPtr = functionPtr else { return nil }
        
        contextPtr[0] = Unmanaged.passRetained(sourceCodeEditorView).toOpaque()
        contextPtr[1] = functionPtr
    }
    
    func voidToInt() -> Int {
        return _scev_voidToInt(contextPtr)
    }
    
    func getCursorStyle() -> CursorStyle {
        return _get_cursor_style(contextPtr)
    }
    
    func setCursorStyle(_ style: CursorStyle) {
        _set_cursor_style(contextPtr, style)
    }
    
    func getDataSource() -> AnyObject? {
        return Unmanaged.fromOpaque(_get_data_source(contextPtr).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue()
    }
    
    func setSelectedRange(_ range: XVimSourceEditorRange, modifiers: XVimSelectionModifiers) {
        _set_selected_range(contextPtr, range, modifiers: modifiers.rawValue)
    }
    
    func addSelectedRange(_ range: XVimSourceEditorRange, modifiers: XVimSelectionModifiers) {
        _add_selected_range(contextPtr, range, modifiers: modifiers.rawValue)
    }
}

class SourceCodeEditorViewWrapper: NSObject {
    private let fpSetCursorStyle                = function_ptr_from_name("_$s12SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ovs", nil)
    private let fpGetCursorStyle                = function_ptr_from_name("_$s12SourceEditor0aB4ViewC11cursorStyleAA0ab6CursorE0Ovg", nil)
    private let fpGetDataSource                 = function_ptr_from_name("_$s12SourceEditor0aB4ViewC04dataA0AA0ab4DataA0Cvg", nil)
    private let fpSetSelectedRangeWithModifiers = function_ptr_from_name("_$s12SourceEditor0aB4ViewC16setSelectedRange_9modifiersyAA0abF0V_AA0aB18SelectionModifiersVtF", nil)
    private let fpAddSelectedRangeWithModifiers = function_ptr_from_name("_$s12SourceEditor0aB4ViewC16addSelectedRange_9modifiers15scrollPlacement12alwaysScrollyAA0abF0V_AA0aB18SelectionModifiersVAA0kI0OSgSbtF", nil)
    private weak var editorViewProxy: SourceCodeEditorViewProxy?
    
    @objc
    lazy public var dataSourceWrapper = {
        return SourceEditorDataSourceWrapper(withSourceCodeEditorViewWrapper: self)
    }()
    
    @objc
    public init(withProxy proxy: SourceCodeEditorViewProxy) {
        editorViewProxy = proxy
    }
    
    private var editorView: AnyObject? {
        return editorViewProxy?.view
    }
    
    @objc
    var cursorStyle: CursorStyle {
        get {
            if let invoker = SourceCodeEditorViewInvoker(editorView, fpGetCursorStyle) {
                return invoker.getCursorStyle()
            }
            return CursorStyle.block
        }
        set {
            SourceCodeEditorViewInvoker(editorView, fpSetCursorStyle)?.setCursorStyle(newValue)
        }
    }
    
    @objc
    var dataSource: AnyObject? {
        return SourceCodeEditorViewInvoker(editorView, fpGetDataSource)?.getDataSource()
    }
    
    @objc
    public func addSelectedRange(_ range: XVimSourceEditorRange, modifiers: XVimSelectionModifiers) -> Void {
        SourceCodeEditorViewInvoker(editorView, fpAddSelectedRangeWithModifiers)?
            .addSelectedRange(range, modifiers: modifiers)
    }
    
    @objc
    public func setSelectedRange(_ range: XVimSourceEditorRange, modifiers: XVimSelectionModifiers) -> Void {
        SourceCodeEditorViewInvoker(editorView, fpSetSelectedRangeWithModifiers)?
            .setSelectedRange(range, modifiers: modifiers)
    }
}
