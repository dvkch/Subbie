//
//  NSView+SY.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 09/10/2021.
//

import Cocoa

// https://stackoverflow.com/a/54310657/1439489
extension NSView {
    func bringSubviewToFront(_ subview: NSView) {
        self.sortSubviews({ (viewA, viewB, subviewID) in
            if viewA.uniqueID == subviewID {
                return ComparisonResult.orderedDescending
            }
            if viewB.uniqueID == subviewID {
                return ComparisonResult.orderedAscending
            }
            return ComparisonResult.orderedSame
        }, context: subview.uniqueID)
    }
    
    private var uniqueID: UnsafeMutableRawPointer {
        return Unmanaged.passUnretained(self).toOpaque()
    }
    
    func hasAncestor<T: NSView>(of kind: T.Type) -> Bool {
        var view: NSView? = self
        while view != nil {
            if view is T {
                return true
            }
            view = view?.superview
        }
        return false
    }
}
