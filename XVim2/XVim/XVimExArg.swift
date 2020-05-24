//
//  XVimExArg.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/24.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

@objc class XVimExArg: NSObject {
    @objc public var arg: String?
    @objc public var cmd: String?
    //@objc public var forceit: Bool = false
    @objc public var noRangeSpecified: Bool = false
    @objc public var lineBegin: Int = NSNotFound// line1
    @objc public var lineEnd: Int = NSNotFound // line2
    //@objc public var addressCount: Int = NSNotFound
}
