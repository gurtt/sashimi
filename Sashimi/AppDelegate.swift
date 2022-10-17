//
//  AppDelegate.swift
//  Sashimi
//
//  Created by Riley Sommerville on 17/10/2022.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {

    private var window: NSWindow!
    private var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSApp.setActivationPolicy(.accessory)
        
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 270),
            styleMask: [.miniaturizable, .closable, .resizable, .titled],
            backing: .buffered, defer: false)
        window.center()
        window.title = "Empty Window"
        window.makeKeyAndOrderFront(nil)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "1.circle", accessibilityDescription: "1")
        }
        
        setupMenus()
        
    }

    func setupMenus() {
        let menu = NSMenu()
        menu.autoenablesItems = false;

        let teams = NSMenuItem(title: "Teams isn't connected", action: #selector(didClickTeams) , keyEquivalent: "")
        teams.isEnabled = false;
        menu.addItem(teams)
        
        let slack = NSMenuItem(title: "Slack isn't connected", action: #selector(didClickSlack) , keyEquivalent: "")
        slack.isEnabled = false;
        menu.addItem(slack)

        menu.addItem(NSMenuItem.separator())

        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(didClickPreferences), keyEquivalent: ","))
        
        menu.addItem(NSMenuItem(title: "Quit Sashimi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }
    
    private func changeStatusBarButton(number: Int) {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "\(number).circle", accessibilityDescription: number.description)
        }
    }

    @objc func didClickTeams() {
        changeStatusBarButton(number: 1)
    }

    @objc func didClickSlack() {
        changeStatusBarButton(number: 2)
    }
    
    @objc func didClickPreferences() {
        window.title = "Preferences"
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

