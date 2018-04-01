//
//  SourceEditorDataSourceWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

typealias InternalCharOffset = Int

@_silgen_name("seds_wrapper_call") func _positionFromInternalCharOffset(_:UnsafeRawPointer, _:InternalCharOffset, lineHint:Int) -> (XVimSourceEditorPosition)
@_silgen_name("seds_wrapper_call2") func _internalCharOffsetFromPosition(_:UnsafeRawPointer, _:XVimSourceEditorPosition) -> (Int)
@_silgen_name("seds_wrapper_call3") func _voidToVoid(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call4") func _voidToInt(_:UnsafeRawPointer) -> (Int)
@_silgen_name("seds_wrapper_call5") func _getUndoManager(_:UnsafeRawPointer) -> (UnsafeMutableRawPointer)
@_silgen_name("seds_wrapper_call6") func _leadingWhitespaceWithForLine(_:UnsafeRawPointer, _:Int, expandTabs:Bool) -> (Int)
@_silgen_name("seds_wrapper_call7") func _intToInt(_:UnsafeRawPointer, _:Int) -> (Int)

public struct XVimLineData {
    var reserved1: Int64;
    var reserved2: Int64;
    var lineContentRange: NSRange;
    var lineTerminatorLength: Int;
    var placeholderHiddenRanges: [NSRange];
    var isHidden: Bool;
}


fileprivate struct _SourceEditorDataSourceWrapper {
    
    let contextPtr = UnsafeMutablePointer<UnsafeMutableRawPointer>.allocate(capacity: 8)
    
    public init?(_ dataSrc : AnyObject?, _ functionPtr : UnsafeMutableRawPointer?) {

        guard let dataSource = dataSrc
            , let fp = functionPtr
            else {return nil}

        contextPtr[0] = Unmanaged.passRetained(dataSource).toOpaque()
        contextPtr[1] = fp
    }
    
    
    
    var undoManager : AnyObject? {
        return Unmanaged.fromOpaque(_getUndoManager(contextPtr).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue()
    }
    
    func voidToVoid() -> () {
        _voidToVoid(contextPtr)
    }
    
    func voidToInt() -> Int {
        return _voidToInt(contextPtr);
    }
    
    func intToInt(_ arg: Int) -> Int {
        return _intToInt(contextPtr, arg);
    }
    
    func positionFromInternalCharOffset(_ pos : Int, lineHint: Int = 0) -> XVimSourceEditorPosition {
        return _positionFromInternalCharOffset(contextPtr, pos, lineHint: lineHint)
    }
    
    func internalCharOffsetFromPosition(_ pos : XVimSourceEditorPosition) -> Int {
        return _internalCharOffsetFromPosition(contextPtr, pos)
    }
    
    func leadingWhitespaceWidthForLine(_ line:Int, expandTabs:Bool) -> Int {
        return _leadingWhitespaceWithForLine(contextPtr, line, expandTabs: expandTabs)
    }
}




class SourceEditorDataSourceWrapper: NSObject {
    private let fpBeginEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C20beginEditTransactionyyF", nil);
    private let fpEndEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C18endEditTransactionyyF", nil);
    private let fpPositionFromIndexLineHint = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30positionFromInternalCharOffsetAA0aB8PositionVSi_Si8lineHinttF", nil);
    private let fpIndexFromPosition = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30internalCharOffsetFromPositionSiAA0abH0VF", nil);
    private let fpGetUndoManager = function_ptr_from_name("_T012SourceEditor0ab4DataA0C11undoManagerAA0ab4UndoE0Cvg", nil);
    private let fpLeadingWhitespaceWidthForLine = function_ptr_from_name("__T012SourceEditor0ab4DataA0C29leadingWhitespaceWidthForLineS2i_Sb10expandTabstF", nil);
    private let fpLineCount = function_ptr_from_name("_T012SourceEditor0ab4DataA0C9lineCountSivg", nil);
    private let fpLineContentLength = function_ptr_from_name("_T012SourceEditor0ab4DataA0C24lineContentLengthForLineS2iF", nil);
    private let fpLineTerminatorLength = function_ptr_from_name("_T012SourceEditor0ab4DataA0C27lineTerminatorLengthForLineS2iF", nil);
    
    private weak var sourceCodeEditorViewWrapper : SourceCodeEditorViewWrapper?
    // MARK - Utility
    
    
    
    
    // MARK - Wrappers
    
    private var dataSource : AnyObject? {
        return sourceCodeEditorViewWrapper?.dataSource
    }
    
    @objc
    public init(withSourceCodeEditorViewWrapper wrapper:SourceCodeEditorViewWrapper) {
        sourceCodeEditorViewWrapper = wrapper
    }
    
    @objc
    public var undoManager : AnyObject? {
        return _SourceEditorDataSourceWrapper(dataSource, fpGetUndoManager)?.undoManager ?? nil
    }
    
    @objc
    public func beginEditTransaction() -> () {
        _SourceEditorDataSourceWrapper(dataSource, fpBeginEditingTransaction)?.voidToVoid()
    }
    
    @objc
    public func endEditTransaction() -> () {
        _SourceEditorDataSourceWrapper(dataSource, fpEndEditingTransaction)?.voidToVoid()
    }
    
    @objc
    public func positionFromInternalCharOffset(_ pos : Int, lineHint: Int = 0) -> XVimSourceEditorPosition {
        return _SourceEditorDataSourceWrapper(dataSource, fpPositionFromIndexLineHint)?
            .positionFromInternalCharOffset(pos, lineHint: lineHint)
            ?? XVimSourceEditorPosition()
    }
    
    @objc
    public func internalCharOffsetFromPosition(_ pos : XVimSourceEditorPosition) -> Int {
        return _SourceEditorDataSourceWrapper(dataSource, fpIndexFromPosition)?
            .internalCharOffsetFromPosition(pos)
            ?? 0
    }
    
    @objc
    public var lineCount : Int {
        return _SourceEditorDataSourceWrapper(dataSource, fpLineCount)?.voidToInt() ?? 0
    }
    
    @objc
    public func lineContentLength(forLine:Int) -> Int {
        return _SourceEditorDataSourceWrapper(dataSource, fpLineContentLength)?.intToInt(forLine) ?? 0
    }
    
    @objc
    public func lineTerminatorLength(forLine:Int) -> Int {
        return _SourceEditorDataSourceWrapper(dataSource, fpLineTerminatorLength)?.intToInt(forLine) ?? 0
    }
    
    
    @objc
    public func leadingWhitespaceWidthForLine(_ line:Int, expandTabs:Bool) -> Int {
        return _SourceEditorDataSourceWrapper(dataSource, fpLeadingWhitespaceWidthForLine)?
            .leadingWhitespaceWidthForLine(line, expandTabs: expandTabs)
            ?? 0
    }
    
}
