//
//  NSString+Util.swift
//  XVim2
//
//  Created by pebble8888 on 2021/04/16.
//  Copyright © 2021 Shuichiro Suzuki. All rights reserved.
//

import Foundation

extension NSString {
    @objc class func line(path: String, pos: UInt) -> UInt {
        guard let s = try? NSString(contentsOfFile: path, encoding: String.Encoding.utf8.rawValue) else {
            return 0
        }

        let end = s.length
        var line: UInt = 1
        for i in 0..<min(Int(pos), end) {
            let uc = s.character(at: i)
            if uc == 0x0A {
                line += 1
            }
        }

        return line
    }
}
