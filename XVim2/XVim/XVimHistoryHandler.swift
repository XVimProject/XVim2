//
//  XVimHistoryHandler.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/24.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

@objc class XVimHistoryHandler: NSObject {
    private var history: [String] = []

    @objc public func addEntry(_ entry: String) {
        history.insert(entry, at: 0)
    }

    @objc public func entry(_ number: Int, prefix: String) -> String? {
        if number == 0 {
            return nil
        }
        var count: Int = 0
        for obj in history {
            if obj.hasPrefix(prefix) {
                count += 1
                if number == count {
                    return obj
                }
            }
        }
        return nil
    }
}
