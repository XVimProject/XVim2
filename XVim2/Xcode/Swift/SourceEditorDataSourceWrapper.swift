//
//  SourceEditorDataSourceWrapper.swift
//  XVim2
//
//  Created by Ant on 22/10/2017.
//  Copyright © 2017 Shuichiro Suzuki. All rights reserved.
//

import Cocoa

@_silgen_name("seds_wrapper_call") func _positionFromInternalCharOffset(_:UnsafeRawPointer, _:UInt, lineHint:UInt) -> ()
@_silgen_name("seds_wrapper_call2") func _internalCharOffsetFromPosition(_:UnsafeRawPointer, _:XVimSourceEditorPosition) -> ()
@_silgen_name("seds_wrapper_call3") func _beginEditTransaction(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call4") func _endEditTransaction(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call4") func _getUndoManager(_:UnsafeRawPointer) -> ()
@_silgen_name("seds_wrapper_call5") func _leadingWhitespaceWithForLine(_:UnsafeRawPointer, _:Int, expandTabs:Bool) -> ()

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
    private let fpLeadingWhitespaceWidthForLine = function_ptr_from_name("__T012SourceEditor0ab4DataA0C29leadingWhitespaceWidthForLineS2i_Sb10expandTabstF", nil);

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
        let result = doCall(fpGetUndoManager) { rawSelf, dataSource in
            _getUndoManager(rawSelf)
        }
        
        return result
            ? Unmanaged.fromOpaque(rax).retain().autorelease().takeUnretainedValue()
            : nil
    }
    
    @objc
    public func beginEditTransaction() -> () {
        doCall(fpBeginEditingTransaction) { rawSelf, dataSource in
            _beginEditTransaction(rawSelf)
        }
    }
    
    @objc
    public func endEditTransaction() -> () {
        doCall(fpEndEditingTransaction) { rawSelf, dataSource in
            _endEditTransaction(rawSelf)
        }
    }
    
    @objc
    public func positionFromInternalCharOffset(_ pos : UInt, lineHint: UInt = 0) -> XVimSourceEditorPosition {
        doCall(fpPositionFromIndexLineHint) { rawSelf, dataSource in
            _positionFromInternalCharOffset(rawSelf, pos, lineHint: lineHint)
        }
        return XVimSourceEditorPosition(
            row: UInt(bitPattern: rax)
            , col: UInt(bitPattern:rdx)
        )
    }
    
    @objc
    public func internalCharOffsetFromPosition(_ pos : XVimSourceEditorPosition) -> UInt {
        doCall(fpIndexFromPosition) { rawSelf, dataSource in
            _internalCharOffsetFromPosition(rawSelf, pos)
        }
        return UInt(bitPattern: rax)
    }
    
    @objc
    public func leadingWhitespaceWidthForLine(_ line:Int, expandTabs:Bool) -> Int {
        doCall(fpLeadingWhitespaceWidthForLine) { rawSelf, dataSource in
            _leadingWhitespaceWithForLine(rawSelf, line, expandTabs: expandTabs)
        }
        return Int(bitPattern: rax)
    }
    
    // MARK:- PRIVATE
    
    @discardableResult
    private func doCall(_ funcPtr: UnsafeMutableRawPointer?, block: (UnsafeRawPointer, AnyObject)->()) -> Bool
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
        block(rawSelf, ds)
        return true;
    }

}
