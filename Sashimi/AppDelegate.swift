//
//  AppDelegate.swift
//  Sashimi
//
//  Created by Riley Sommerville on 17/10/2022.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!

        func applicationDidFinishLaunching(_ aNotification: Notification) {
            
            window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 270),
                styleMask: [.miniaturizable, .closable, .resizable, .titled],
                backing: .buffered, defer: false)
            window.center()
            window.title = "Empty Window"
            window.makeKeyAndOrderFront(nil)
        }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

