//
//  NSTextStorage+VimOperation.swift
//  XVim2
//
//  Created by pebble8888 on 2021/04/17.
//  Copyright © 2021 Shuichiro Suzuki. All rights reserved.
//

import Foundation

extension NSTextStorage {
    @objc func validIndex(_ index: UInt) -> UInt {
        if index > self.length {
            return UInt(self.length)
        }
        return index
    }

    @objc func isEOF(_ index: UInt) -> Bool {
        let index = validIndex(index)
        return self.length == index
    }

    @objc func isLOL(_ index: UInt) -> Bool {
        let index = self.validIndex(index)
        return self.isEOF(index) == false && self.isNewline(index) == false && self.isNewline(index + 1)
    }

    @objc func isEOL(_ index: UInt) -> Bool {
        let index = self.validIndex(index)
        return self.isNewline(index) || self.isEOF(index)
    }

    @objc func isBOL(_ index: UInt) -> Bool {
        let index = self.validIndex(index)
        if 0 == index {
            return true
        }

        if self.isNewline(index - 1) {
            return true
        }

        return false
    }

    @objc func isNewline(_ index: UInt) -> Bool {
        let index = self.validIndex(index)
        if  index == self.length {
            return false // EOF is not a newline
        }

        return self.string.isNewline(index)
    }
}
