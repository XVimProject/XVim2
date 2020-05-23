//
//  XVimMark.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/23.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

@objc class XVimMark: NSObject {
    @objc public var line: Int = NSNotFound
    @objc public var column: Int = NSNotFound
    @objc public var document: String?
    
    public override init() {
        super.init()
    }
    
    @objc public init(line: Int, column: Int, document: String? = nil) {
        super.init()
        self.line = line
        self.column = column
        self.document = document
    }

    @objc public convenience init(mark: XVimMark?) {
        if let mark = mark {
            self.init(line: mark.line, column: mark.column, document: mark.document)
        } else {
            self.init(line: NSNotFound, column: NSNotFound)
        }
    }
    
    @objc public func setMark(_ mark: XVimMark?) {
        if let mark = mark {
            self.line = mark.line
            self.column = mark.column
            self.document = mark.document
        } else {
            line = NSNotFound
            column = NSNotFound
            document = nil
        }
    }
    
}
