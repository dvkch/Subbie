//
//  NSView+SY.swift
//  Subtitler
//
//  Created by Stanislas Chevallier on 09/10/2021.
//

import Cocoa

// https://stackoverflow.com/a/54310657/1439489
extension NSView {
    func bringSubviewToFront(_ view: NSView) {
        var theView = view
        self.sortSubviews({(viewA,viewB,rawPointer) in
            let view = rawPointer?.load(as: NSView.self)

            switch view {
            case viewA:
                return ComparisonResult.orderedDescending
            case viewB:
                return ComparisonResult.orderedAscending
            default:
                return ComparisonResult.orderedSame
            }
        }, context: &theView)
    }
}
