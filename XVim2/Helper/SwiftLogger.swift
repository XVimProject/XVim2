//
//  SwiftLogger.swift
//  XVim2
//
//  Created by pebble8888 on 2018/06/15.
//  Copyright © 2018年 Shuichiro Suzuki. All rights reserved.
//

import Foundation

// global function
func log(_ s: String)
{
    Logger.default().log(with: s)
}
