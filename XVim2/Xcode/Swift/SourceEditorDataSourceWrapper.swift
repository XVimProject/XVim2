//
//  SourceEditorDataSourceWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("seds_wrapper_call") func _positionFromInternalCharOffset(_:UnsafeRawPointer, _:UInt, lineHint:UInt) -> (XVimSourceEditorPosition)
@_silgen_name("seds_wrapper_call2") func _internalCharOffsetFromPosition(_:UnsafeRawPointer, _:XVimSourceEditorPosition) -> (UInt)
@_silgen_name("seds_wrapper_call3") func _beginEditTransaction(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call4") func _endEditTransaction(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call4") func _getUndoManager(_:UnsafeRawPointer) -> (UnsafeMutableRawPointer)
@_silgen_name("seds_wrapper_call5") func _leadingWhitespaceWithForLine(_:UnsafeRawPointer, _:Int, expandTabs:Bool) -> (Int)

typealias InternalCharOffset = Int64



class SourceEditorDataSourceWrapper: NSObject {

    let context : UnsafeMutableRawPointer = malloc(2 * 8)!
    let contextPtr : UnsafeMutableBufferPointer<UnsafeMutableRawPointer>!

    private let fpBeginEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C20beginEditTransactionyyF", nil);
    private let fpEndEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C18endEditTransactionyyF", nil);
    private let fpPositionFromIndexLineHint = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30positionFromInternalCharOffsetAA0aB8PositionVSi_Si8lineHinttF", nil);
    private let fpIndexFromPosition = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30internalCharOffsetFromPositionSiAA0abH0VF", nil);
    private let fpGetUndoManager = function_ptr_from_name("_T012SourceEditor0ab4DataA0C11undoManagerAA0ab4UndoE0Cfg", nil);
    private let fpLeadingWhitespaceWidthForLine = function_ptr_from_name("__T012SourceEditor0ab4DataA0C29leadingWhitespaceWidthForLineS2i_Sb10expandTabstF", nil);
    
    private weak var sourceCodeEditorViewWrapper : SourceCodeEditorViewWrapper?
    
    deinit {
        free(context)
    }
    
    @objc
    public init(withSourceCodeEditorViewWrapper wrapper:SourceCodeEditorViewWrapper) {
        sourceCodeEditorViewWrapper = wrapper
        contextPtr = UnsafeMutableBufferPointer<UnsafeMutableRawPointer>(start: context.assumingMemoryBound(to: UnsafeMutableRawPointer.self), count: 3)
    }
    
    // MARK:- PUBLIC

    @objc
    public var undoManager : AnyObject? {
        return doCall(fpGetUndoManager) ? Unmanaged.fromOpaque(_getUndoManager(context).assumingMemoryBound(to: AnyObject?.self)).takeRetainedValue() : nil
    }
    
    @objc
    public func beginEditTransaction() -> () {
        if doCall(fpBeginEditingTransaction) {
            _beginEditTransaction(context)
        }
    }
    
    @objc
    public func endEditTransaction() -> () {
        if doCall(fpEndEditingTransaction) {
            _endEditTransaction(context)
        }
    }
    
    @objc
    public func positionFromInternalCharOffset(_ pos : UInt, lineHint: UInt = 0) -> XVimSourceEditorPosition {
        return doCall(fpPositionFromIndexLineHint)
            ? _positionFromInternalCharOffset(context, pos, lineHint: lineHint)
            : XVimSourceEditorPosition()
    }
    
    @objc
    public func internalCharOffsetFromPosition(_ pos : XVimSourceEditorPosition) -> UInt {
        return doCall(fpIndexFromPosition)
            ? _internalCharOffsetFromPosition(context, pos)
            : 0
    }
    
    @objc
    public func leadingWhitespaceWidthForLine(_ line:Int, expandTabs:Bool) -> Int {
        return doCall(fpLeadingWhitespaceWidthForLine)
            ? _leadingWhitespaceWithForLine(context, line, expandTabs: expandTabs)
            : 0
    }
    
    
    // MARK:- PRIVATE
    
    @discardableResult
    private func doCall(_ funcPtr: UnsafeMutableRawPointer?) -> Bool
    {
        guard let vw = self.sourceCodeEditorViewWrapper
            , let ds = vw.dataSource
            , let fp = funcPtr
            else {return false}
        let sourceEditorDataSourcePtr = Unmanaged.passUnretained(ds).toOpaque()
        contextPtr[0] = sourceEditorDataSourcePtr
        contextPtr[1] = fp
        
        return true;
    }

}
