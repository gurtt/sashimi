//
//  AppDelegate.swift
//  Sashimi
//
//  Created by Riley Sommerville on 17/10/2022.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private let kTokenKey = "slack-access-token"
    private let client_id = "4228676926246.4237754035636"
    private let scope = "users.profile:write"

    private var window: NSWindow!
    private var statusItem: NSStatusItem!
    private var signInMenuItem: NSMenuItem!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "1.circle", accessibilityDescription: "1")
        }
        
        setupMenus()
        
    }

    func setupMenus() {
        let menu = NSMenu()
        menu.autoenablesItems = false;

        let teams = NSMenuItem(title: "Teams isn't in a call", action: #selector(didClickTeams) , keyEquivalent: "")
        teams.isEnabled = false;
        menu.addItem(teams)
        
        menu.addItem(NSMenuItem.separator())
        
        let hasToken: Bool
        do {
            hasToken = try KeychainHelper().get(kTokenKey) == nil
        } catch let error as NSError {
            print("Error: \(error.domain)")
            hasToken = false
        }
        
        signInMenuItem = NSMenuItem(title: "Sign \(hasToken ? "in to" : "out of") Slack", action: #selector(didClickSlack) , keyEquivalent: "")
        menu.addItem(signInMenuItem)

        menu.addItem(NSMenuItem(title: "Set custom message…", action: #selector(didClickPreferences), keyEquivalent: ""))
        
        menu.addItem(NSMenuItem.separator())
        
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
        
        let hasToken: Bool
        do {
            hasToken = try KeychainHelper().get(kTokenKey) == nil
        } catch let error as NSError {
            print("Error: \(error.domain)")
            hasToken = false
        }
        
        if hasToken { //Sign out
            do {
                try KeychainHelper().delete(kTokenKey)
            } catch {
                print("Couldn't delete key")
                return
            }
            signInMenuItem.title = "Sign in to Slack"
        } else { // Sign in
            let url = URL(string: "https://slack.com/oauth/authorize?client_id=\(client_id)&scope=\(scope)")!
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func didClickPreferences() {
        let defaults = UserDefaults.standard
        
        let textField = NSTextField(string:
                                        (defaults.string(forKey: "statusEmoji") ?? "")
                                     + ((defaults.string(forKey: "statusText") != nil)
                                            ? " " + defaults.string(forKey: "statusText")!
                                            : ""))
        textField.placeholderString = ":sushi: In a call"
        textField.setFrameSize(NSSize(width: 200, height: textField.frame.height))
        
        let alert = NSAlert()
        alert.messageText = "Set a Status Message"
        alert.informativeText = "Add a custom emoji by typing its name between colons."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        alert.accessoryView = textField
                
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            
            let stringParts = textField.stringValue.split(separator: " ", maxSplits: 1)
            
            func isEmojiString (_ testString: String) -> Bool{
                return testString.hasPrefix(":") && testString.hasSuffix(":") && testString.count > 2
            }
            
            switch stringParts.count {
            case 0: // Empty
                defaults.removeObject(forKey: "statusEmoji")
                defaults.removeObject(forKey: "statusText")
                
            case 1:
                if isEmojiString(String(stringParts[0])) { // Just emoji
                    defaults.set(String(stringParts[0]), forKey: "statusEmoji")
                    defaults.removeObject(forKey: "statusText")
                } else { // Just (single-word) text
                    defaults.removeObject(forKey: "statusEmoji")
                    defaults.set(String(stringParts[0]), forKey: "statusText")
                }
                
            case 2:
                if isEmojiString(String(stringParts[0])) { // Emoji and text
                    defaults.set(String(stringParts[0]), forKey: "statusEmoji")
                    defaults.set(String(stringParts[1]), forKey: "statusText")
                } else { // Just (multi-word) text
                    defaults.removeObject(forKey: "statusEmoji")
                    defaults.set(textField.stringValue, forKey: "statusText")
                }
                
            default:
                print("More items than expected in string parts")
            }
        }
    
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
            do {
                
                try KeychainHelper().set(token, forKey: kTokenKey)
            } catch let error as NSError {
                print("Couldn't add token to keychain \(error.domain)")
                return
            }
            signInMenuItem.title = "Sign out of Slack"
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

