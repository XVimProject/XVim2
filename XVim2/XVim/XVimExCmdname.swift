//
//  XVimExCmdname.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/24.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

// XVimExCmd corresponds cmdname struct in ex_cmds.h
@objc class XVimExCmdname: NSObject {
    @objc private (set) public var cmdName: String
    @objc private (set) public var methodName: String

    @objc public init(cmd: String, method: String) {
        cmdName = cmd
        methodName = method
        super.init()
    }
}
