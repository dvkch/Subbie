//
//  NSTableView+SY.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa

extension NSTableColumn {
    convenience init(identifier: String, title: String) {
        self.init(identifier: NSUserInterfaceItemIdentifier(rawValue: identifier))
        self.title = title
    }
}
