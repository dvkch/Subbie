//
//  SubtitleView.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 29/09/2021.
//

import Cocoa
import SnapKit

class SubtitleView: NSView {
    
    // MARK: Init
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.backgroundColor = NSColor.init(white: 0.1, alpha: 0.6).cgColor

        textfield.drawsBackground = false
        textfield.isBezeled = false
        textfield.isEnabled = false
        textfield.isEditable = false
        textfield.textColor = .init(calibratedWhite: 1, alpha: 1)
        textfield.font = .boldSystemFont(ofSize: 24)
        textfield.lineBreakMode = .byWordWrapping
        textfield.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        textfield.alignment = .center
        addSubview(textfield)
        textfield.snp.makeConstraints { make in
            make.top.left.equalToSuperview().offset(8)
            make.right.bottom.equalToSuperview().offset(-8)
        }
    }
    
    // MARK: Properties
    var text: String? {
        didSet {
            textfield.stringValue = text ?? ""
            isHidden = text?.isEmpty != false
        }
    }
    
    // MARK: Views
    private let textfield = NSTextField()
}
