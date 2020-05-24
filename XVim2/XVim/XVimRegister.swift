//
//  XVimRegister.swift
//  XVim2
//
//  Created by pebble8888 on 2020/05/24.
//  Copyright © 2020 Shuichiro Suzuki. All rights reserved.
//

import Foundation

@objc class XVimRegister: NSObject {
    @objc public var type: XVimTextType = .characters
    @objc private(set) public var string: String = ""

    @objc public func appendXVimString(_ str: String) {
        string += str
    }

    @objc public func setXVimString(_ str: String?) {
        if let str = str {
            string = str
        } else {
            string = ""
        }
    }

    @objc public func clear() {
        string = ""
        type = .characters
    }
}

@objc class XVimReadonlyRegister: XVimRegister {
}

@objc class XVimCurrentFileRegister: XVimReadonlyRegister {
    @objc override init() {
        super.init()
    }

    @objc override func appendXVimString(_ str: String) {
    }

    @objc override func setXVimString(_ str: String?) {
    }

    @objc override public var string: String {
        return XVim.instance().document
    }
}

@objc class XVimClipboardRegister: XVimRegister {
    @objc override public func appendXVimString(_ str: String) {
    }

    @objc override public func setXVimString(_ str: String?) {
        NSPasteboard.general.declareTypes([NSPasteboard.PasteboardType.string], owner: nil)
        NSPasteboard.general.setString(string, forType: NSPasteboard.PasteboardType.string)
    }

    @objc override public var string: String {
        guard let str = NSPasteboard.general.string(forType: NSPasteboard.PasteboardType.string) else {
            return ""
        }
        return str
    }
}

@objc class XVimBlackholeRegister: XVimRegister {
    @objc override public func appendXVimString(_ str: String) {
    }

    @objc override public func setXVimString(_ str: String?) {
    }

    @objc override public var string: String {
        return ""
    }
}
