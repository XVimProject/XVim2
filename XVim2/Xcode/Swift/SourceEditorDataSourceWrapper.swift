//
//  SourceEditorDataSourceWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("seds_wrapper_call") func _positionFromInternalCharOffset(_:UInt, lineHint:UInt) -> ()
@_silgen_name("seds_wrapper_call2") func _internalCharOffsetFromPosition(_:XVimSourceEditorPosition) -> ()
@_silgen_name("seds_wrapper_call3") func _beginEditTransaction() -> ()
@_silgen_name("seds_wrapper_call4") func _endEditTransaction() -> ()
@_silgen_name("seds_wrapper_call4") func _getUndoManager() -> ()

typealias InternalCharOffset = Int64


class SourceEditorDataSourceWrapper: NSObject {

    let a: UInt64 = 0xaaaaaaaaaaaaaaaa
    private var sourceEditorDataSourcePtr : UnsafeMutableRawPointer // 16
    private var functionToCallPtr : UnsafeMutableRawPointer // 24
    private var rax : UnsafeMutableRawPointer // 32
    private var rdx : UnsafeMutableRawPointer // 40

    private let fpBeginEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C20beginEditTransactionyyF", nil);
    private let fpEndEditingTransaction = function_ptr_from_name("_T012SourceEditor0ab4DataA0C18endEditTransactionyyF", nil);
    private let fpPositionFromIndexLineHint = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30positionFromInternalCharOffsetAA0aB8PositionVSi_Si8lineHinttF", nil);
    private let fpIndexFromPosition = function_ptr_from_name("_T012SourceEditor0ab4DataA0C30internalCharOffsetFromPositionSiAA0abH0VF", nil);
    private let fpGetUndoManager = function_ptr_from_name("_T012SourceEditor0ab4DataA0C11undoManagerAA0ab4UndoE0Cfg", nil);

    private weak var sourceCodeEditorViewWrapper : SourceCodeEditorViewWrapper?
    
    @objc
    public init(withSourceCodeEditorViewWrapper wrapper:SourceCodeEditorViewWrapper) {
        sourceCodeEditorViewWrapper = wrapper
        sourceEditorDataSourcePtr = unsafeBitCast(fpIndexFromPosition, to: UnsafeMutableRawPointer.self)
        functionToCallPtr = unsafeBitCast(fpIndexFromPosition, to: UnsafeMutableRawPointer.self)
        rax = unsafeBitCast(fpIndexFromPosition, to: UnsafeMutableRawPointer.self)
        rdx = unsafeBitCast(fpIndexFromPosition, to: UnsafeMutableRawPointer.self)
    }
    
    // MARK:- PUBLIC

    @objc
    public var undoManager : AnyObject? {
        guard prepareCall(fpGetUndoManager) else {return nil}
        _getUndoManager()
        return Unmanaged.fromOpaque(rax).takeRetainedValue()
    }
    
    @objc
    public func beginEditTransaction() -> () {
        guard prepareCall(fpBeginEditingTransaction) else {return}
        _beginEditTransaction()
    }
    
    @objc
    public func endEditTransaction() -> () {
        guard prepareCall(fpEndEditingTransaction) else {return}
        _endEditTransaction()
    }
    
    @objc
    public func positionFromInternalCharOffset(_ pos : UInt, lineHint: UInt = 0) -> XVimSourceEditorPosition {
        guard prepareCall(fpPositionFromIndexLineHint) else {return XVimSourceEditorPosition(row:0, col:0)}
        _positionFromInternalCharOffset(pos, lineHint: lineHint)
        return XVimSourceEditorPosition(
            row: UInt(bitPattern: rax)
            , col: UInt(bitPattern:rdx)
        )
    }
    
    @objc
    public func internalCharOffsetFromPosition(_ pos : XVimSourceEditorPosition) -> UInt {
        guard prepareCall(fpIndexFromPosition) else {return 0}
        _internalCharOffsetFromPosition(pos)
        return UInt(bitPattern: rax)
    }
    
    // MARK:- PRIVATE
    
    private func prepareCall(_ funcPtr: UnsafeMutableRawPointer?) -> Bool
    {
        guard let vw = self.sourceCodeEditorViewWrapper
            , let ds = vw.dataSource
            , let fp = funcPtr
            else {return false}
       
        let byteCount = 8 * 4
        let rawSelf = Unmanaged.toOpaque(Unmanaged.passUnretained(self))()
        let ptr = UnsafeMutablePointer<UInt8>(rawSelf.assumingMemoryBound(to: UInt8.self))
        memset_s(ptr+16, byteCount, 0x00, byteCount)
        
        sourceEditorDataSourcePtr = unsafeBitCast(ds as AnyObject, to:UnsafeMutableRawPointer.self)
        functionToCallPtr = fp
        return true
    }

}
