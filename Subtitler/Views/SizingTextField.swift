//
//  SizingTextField.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 29/09/2021.
//

import Cocoa

class SizingTextField: NSTextField {
    
    override var intrinsicContentSize: NSSize {
        let wasEditable = isEditable
        defer { isEditable = wasEditable }
        isEditable = false

        return super.intrinsicContentSize
    }
}
