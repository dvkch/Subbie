//
//  NSScrollView+SY.swift
//  Subbie
//
//  Created by syan on 14/05/2024.
//

import Cocoa

// https://stackoverflow.com/a/14572970/1439489
extension NSScrollView {
    var documentSize: NSSize {
        set { documentView?.setFrameSize(newValue) }
        get { documentView?.frame.size ?? NSSize.zero }
    }
    var documentOffset: NSPoint {
        set { documentView?.scroll(newValue) }
        get { documentVisibleRect.origin }
    }
}

