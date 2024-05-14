//
//  NSMenu+SY.swift
//  Subtitler
//
//  Created by syan on 14/05/2024.
//

import Cocoa

extension NSMenu {
    func find(id: String) -> NSMenuItem? {
        for item in items {
            if item.identifier?.rawValue == id {
                return item
            }
            if let subitem = item.submenu?.find(id: id) {
                return subitem
            }
        }
        return nil
    }
}
