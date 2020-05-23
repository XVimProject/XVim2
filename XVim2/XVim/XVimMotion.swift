//
//  XVimMotion.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/23.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//
// swiftlint:disable line_length

import Foundation

@objc class XVimMotionInfo: NSObject {
    @objc var reachedEndOfLine: Bool = false
    @objc var isFirstWordInLine: Bool = false
    @objc var deleteLastLine: Bool = false
    @objc var lastEndOfLine: Int = NSNotFound
    @objc var lastEndOfWord: Int = NSNotFound
}

@objc class XVimMotion: NSObject {
    @objc var style: MOTION_STYLE
    @objc var type: MOTION_TYPE
    @objc var option: MOTION_OPTION
    @objc var count: Int
    @objc var line: Int = NSNotFound
    @objc var column: Int = NSNotFound
    @objc var position: Int = NSNotFound
    @objc var character: UInt16 = 0// unichar
    @objc var regex: String?
    @objc var motionInfo: XVimMotionInfo?
    @objc var jumpToAnotherFile: Bool = false
    @objc var keepJumpMarkIndex: Bool = false

    @objc public func isJumpMotion() -> Bool {
        switch style {
        case .MOTION_SENTENCE_FORWARD, // )
            .MOTION_SENTENCE_BACKWARD, // (
            .MOTION_PARAGRAPH_FORWARD, // }
            .MOTION_PARAGRAPH_BACKWARD, // {
            .MOTION_NEXT_MATCHED_ITEM, // %
            .MOTION_LINENUMBER, // [num]G
            .MOTION_PERCENT, // [num]%
            .MOTION_LASTLINE, // G
            .MOTION_HOME, // H
            .MOTION_MIDDLE, // M
            .MOTION_BOTTOM, // L
            .MOTION_SEARCH_FORWARD, // /
            .MOTION_SEARCH_BACKWARD, // ?
            .MOTION_POSITION_JUMP: // Custom position change for jump
            return true
        default:
            break
        }
        return false
    }

    @objc public init(style: MOTION_STYLE, type: MOTION_TYPE, option: MOTION_OPTION, count: Int = 1) {
        self.style = style
        self.type = type
        self.option = option
        self.count = count
        self.motionInfo = XVimMotionInfo()
        super.init()
    }

    @objc public convenience init(style: MOTION_STYLE, type: MOTION_TYPE, count: Int) {
        self.init(style: style, type: type, option: [], count: count)
    }

    @objc public static func style(_ style: MOTION_STYLE, type: MOTION_TYPE, count: Int) -> XVimMotion {
        return XVimMotion(style: style, type: type, count: count)
    }

    @objc public static func style(_ style: MOTION_STYLE, type: MOTION_TYPE, option: MOTION_OPTION, count: Int) -> XVimMotion {
        return XVimMotion(style: style, type: type, option: option, count: count)
    }

    @objc public func isTextObject() -> Bool {
        return MOTION_STYLE.TEXTOBJECT_WORD.rawValue <= self.style.rawValue &&
            self.style.rawValue <= MOTION_STYLE.TEXTOBJECT_UNDERSCORE.rawValue
    }

    @objc static func uncodablePropertyKeys() -> [String] {
        return ["info"]
    }

    override var debugDescription: String {
        return String(format: "style: \(style) type: \(type) option: \(option) count: \(count) line: \(line) column: \(column) position \(position) info \(String(describing: motionInfo))")
    }
}
