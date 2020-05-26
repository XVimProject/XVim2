//
//  XVimEvalFunc.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/26.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

@objc class XVimEvalFunc: NSObject {
    @objc public var funcName: String
    @objc public var methodName: String

    @objc public init(funcName: String, methodName: String) {
        self.funcName = funcName
        self.methodName = methodName
    }
}
