//
//  XVimEvalArg.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/26.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

// @ref eval.c in original vim
@objc class XVimEvalArg: NSObject {
    @objc var invar: String // [in] in variable
    @objc var rvar: String? // [out] return variable

    @objc public override init() {
        invar = ""
        super.init()
    }
}
