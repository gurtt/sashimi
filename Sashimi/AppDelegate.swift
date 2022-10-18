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
        
        let client_id = "4228676926246.4237754035636"
        let scope = "users.profile:write"
        
        let url = URL(string: "https://slack.com/oauth/authorize?client_id=\(client_id)&scope=\(scope)")!
        NSWorkspace.shared.open(url)
    }
    
    @objc func didClickPreferences() {
        window.title = "Preferences"
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {

        guard let components = NSURLComponents(url: urls[0], resolvingAgainstBaseURL: true),
            let path = components.path,
            let params = components.queryItems else {
                print("Missing query params")
                return
        }
        
        if path != "auth" {
            print(#"Invalid path "\#(path)"; expected "auth""#)
        }

        if let token = params.first(where: { $0.name == "token" })?.value {
            print("token = \(token)")
        } else {
            print("Token param missing")
        }
    }

    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }


}

