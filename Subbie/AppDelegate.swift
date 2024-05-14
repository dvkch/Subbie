//
//  AppDelegate.swift
//  Subbie
//
//  Created by Stanislas Chevallier on 28/09/2021.
//

import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        _ = DocumentController.init() // force use of our subclass
        translateMenu(id: "menu.match_end_to_next_start", text: L10n.Menu.matchEndToNextStart)
        translateMenu(id: "menu.delay_all_lines",         text: L10n.Menu.delayAllLines)
        translateMenu(id: "menu.open_video",              text: L10n.Menu.openVideo)
        translateMenu(id: "menu.play_pause",              text: L10n.Menu.playPause)
        translateMenu(id: "menu.seek_plus_5",             text: L10n.Menu.seekPlus5)
        translateMenu(id: "menu.seek_minus_5",            text: L10n.Menu.seekMinus5)
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    private func translateMenu(id: String, text: String) {
        guard let item = NSApplication.shared.mainMenu?.find(id: id) else {
            print("WARNING: couldn't find main menu item '\(id)'")
            return
        }
        item.title = text
    }
}

