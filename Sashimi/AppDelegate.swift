//
//  AppDelegate.swift
//  Sashimi
//
//  Created by Riley Sommerville on 17/10/2022.
//

import Cocoa
import FileWatcher
import OSLog

class AppDelegate: NSObject, NSApplicationDelegate {
  private let kTokenKey = "slack-access-token"
  private let client_id = "4228676926246.4237754035636"
  private let scope = "users.profile:write"
  private let teamsMonitoringPath = "~/Library/Application Support/Microsoft/Teams/storage.json"

  private let log = Logger()
  
  private var fileWatcher: FileWatcher!
  private var slack: SlackClient!
  private var window: NSWindow!
  private var statusItem: NSStatusItem!
  private var signInMenuItem: NSMenuItem!

  func applicationDidFinishLaunching(_ aNotification: Notification) {

    NSApp.setActivationPolicy(.accessory)

    do {
      try slack = SlackClient(client_id, withAccessToken: KeychainHelper().get(kTokenKey))
    } catch let error {
      log.error(
        "Error getting key \"\(self.kTokenKey, privacy: .public)\": \(error.localizedDescription, privacy: .public)"
      )
      slack = SlackClient(client_id)
    }
      
    fileWatcher = FileWatcher([NSString(string: teamsMonitoringPath).expandingTildeInPath])

    fileWatcher.callback = { event in
      if event.path != NSString(string: self.teamsMonitoringPath).expandingTildeInPath { return }
      
      self.log.info("Processing FileWatcher event \(event.id, privacy: .public)")
      
      let data = String(data: FileManager.default.contents(atPath: event.path)!, encoding: .utf8) ?? ""
      
      let match = try? NSRegularExpression(pattern: "(\\{\"appStates\":\\{\"states\":\")[^\"]+").firstMatch(in: data, range: NSMakeRange(0, data.count))
      
      guard match != nil else {
        self.log.notice("Didn't find a match in monitoring file")
        return
      }
      
      let lastEvent = String(String(data[Range(match!.range, in: data)!]).dropFirst(24).split(separator: ",").last ?? "")
      
      switch lastEvent {
      case "InCall":
        let defaults = UserDefaults.standard
        
        self.log.notice("Setting custom status")
        
        self.slack.setStatus(
          (defaults.string(forKey: "statusEmoji") == nil && defaults.string(forKey: "statusText") == nil)
          ? SlackClient.SlackStatus(
              status_emoji: ":sushi:",
              status_text: "In a call"
          )
          : SlackClient.SlackStatus(
              status_emoji: defaults.string(forKey: "statusEmoji") ?? "",
              status_text: defaults.string(forKey: "statusText") ?? ""
          )
        )
      case "CallEnded":
        self.log.notice("Clearing status")
        self.slack.clearStatus()
        
      default:
        self.log.notice("Ignoring irrelevant event \"\(lastEvent, privacy: .public)\"")
      }

    }
    fileWatcher.start()
    log.info("Started watching \"\(self.teamsMonitoringPath, privacy: .public)\"")

    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    if let button = statusItem.button {
      button.image = NSImage(systemSymbolName: "1.circle", accessibilityDescription: "1")
    }

    setupMenus()

    if !slack.hasToken() {
      log.info("No token; triggering sign in prompt")
      let alert = NSAlert()
      alert.messageText = "Sign In to Slack"
      alert.informativeText = "Sign in to Slack to use Sashimi."
      alert.addButton(withTitle: "Sign in")
      alert.addButton(withTitle: "Later")

      if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
        didClickSlack()
      }
    }

  }

  func setupMenus() {
    let menu = NSMenu()
    menu.autoenablesItems = false

    let teams = NSMenuItem(
      title: "Teams isn't in a call", action: #selector(didClickTeams), keyEquivalent: "")
    teams.isEnabled = false
    menu.addItem(teams)

    menu.addItem(NSMenuItem.separator())

    signInMenuItem = NSMenuItem(
      title: "Sign \(slack.hasToken() ? "Out of" : "In to") Slack",
      action: #selector(didClickSlack), keyEquivalent: "")
    menu.addItem(signInMenuItem)

    menu.addItem(
      NSMenuItem(
        title: "Set Custom Message…", action: #selector(didClickPreferences), keyEquivalent: ""))

    menu.addItem(NSMenuItem.separator())

    menu.addItem(
      NSMenuItem(
        title: "Quit Sashimi", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

    statusItem.menu = menu
  }

  private func changeStatusBarButton(number: Int) {
    if let button = statusItem.button {
      button.image = NSImage(
        systemSymbolName: "\(number).circle", accessibilityDescription: number.description)
    }
  }

  @objc func didClickTeams() {
    changeStatusBarButton(number: 1)
  }

  @objc func didClickSlack() {
    changeStatusBarButton(number: 2)

    if slack.hasToken() {  //Sign out
      log.info("Token found; signing out")
      do {
        log.notice("Removing keychain key \"\(self.kTokenKey, privacy: .public)\"")
        try KeychainHelper().delete(kTokenKey)
        slack.setToken(nil)
        signInMenuItem.title = "Sign in to Slack"

        let alert = NSAlert()
        alert.messageText = "Signed Out of Slack"
        alert.informativeText = "Sign in again to use Sashimi."
        alert.runModal()

      } catch let error {
        log.error(
          "Error removing key \"\(self.kTokenKey, privacy: .public)\": \(error.localizedDescription, privacy: .public)"
        )
      }

    } else {  // Sign in
      log.info("Token not found; signing in")
      slack.authorise(withScope: scope)
    }

  }

  @objc func didClickPreferences() {
    let defaults = UserDefaults.standard

    let defaultString =
      (defaults.string(forKey: "statusEmoji") ?? "")
      + ((defaults.string(forKey: "statusText") != nil)
        ? " " + defaults.string(forKey: "statusText")!
        : "")
    log.info(
      "Presenting pre-filled status message \"\(defaultString, privacy: .private(mask: .hash))\"")
    let textField = NSTextField(string: defaultString)
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

      func isEmojiString(_ testString: String) -> Bool {
        return testString.hasPrefix(":") && testString.hasSuffix(":") && testString.count > 2
      }

      switch stringParts.count {
      case 0:  // Empty
        log.debug(
          "Detected no emoji, no message in \"\(textField.stringValue, privacy: .private(mask: .hash))\""
        )
        defaults.removeObject(forKey: "statusEmoji")
        defaults.removeObject(forKey: "statusText")

      case 1:
        if isEmojiString(String(stringParts[0])) {  // Just emoji
          log.debug(
            "Detected emoji, no message in \"\(textField.stringValue, privacy: .private(mask: .hash))\""
          )
          defaults.set(String(stringParts[0]), forKey: "statusEmoji")
          defaults.removeObject(forKey: "statusText")
        } else {  // Just (single-word) text
          log.debug(
            "Detected no emoji, message in \"\(textField.stringValue, privacy: .private(mask: .hash))\""
          )
          defaults.removeObject(forKey: "statusEmoji")
          defaults.set(String(stringParts[0]), forKey: "statusText")
        }

      case 2:
        if isEmojiString(String(stringParts[0])) {  // Emoji and text
          log.debug(
            "Detected emoji, message in \"\(textField.stringValue, privacy: .private(mask: .hash))\""
          )
          defaults.set(String(stringParts[0]), forKey: "statusEmoji")
          defaults.set(String(stringParts[1]), forKey: "statusText")
        } else {  // Just (multi-word) text
          log.debug(
            "Detected no emoji, message in \"\(textField.stringValue, privacy: .private(mask: .hash))\""
          )
          defaults.removeObject(forKey: "statusEmoji")
          defaults.set(textField.stringValue, forKey: "statusText")
        }

      default:
        log.fault(
          "Got \(stringParts.count) parts from \"\(textField.stringValue, privacy: .private(mask: .hash))\", expecting at most 2"
        )

        let alert = NSAlert()
        alert.messageText = "Couldn't Set Status Message"
        alert.runModal()
      }
    }

  }

  func application(_ application: NSApplication, open urls: [URL]) {

    enum tokenResolutionError: Error {
      case missingQueryParameters
      case invalidPath(path: String)
      case missingTokenParameter
      case unhandledError(status: OSStatus)
    }

    do {
      guard let components = NSURLComponents(url: urls[0], resolvingAgainstBaseURL: true),
        let path = components.path,
        let params = components.queryItems
      else {
        throw tokenResolutionError.missingQueryParameters
      }

      guard path == "auth" else {
        throw tokenResolutionError.invalidPath(path: path)
      }

      if let token = params.first(where: { $0.name == "token" })?.value {
        log.info("Resolved token \"\(token, privacy: .private(mask: .hash))\" from URL")
        do {
          log.notice(
            "Setting keychain key \"\(self.kTokenKey, privacy: .public)\" to \"\(token, privacy: .private)\""
          )
          try KeychainHelper().set(token, forKey: kTokenKey)
        } catch let error as NSError {
          print("Couldn't add token to keychain \(error.domain)")

          let alert = NSAlert()
          alert.messageText = "Couldn't Save Credentials"
          alert.informativeText =
            "Sashimi is signed in, but won't stay signed in once you quit the app."
          alert.runModal()
        }
        slack.setToken(token)
        signInMenuItem.title = "Sign out of Slack"
        didClickPreferences()
      } else {
        throw tokenResolutionError.missingTokenParameter
      }

    } catch let error {
      log.error(
        "Couldn't resolve token from URL \"\(urls[0], privacy: .private)\": \(error.localizedDescription, privacy: .public)"
      )

      let alert = NSAlert()
      alert.messageText = "Couldn't Sign In"
      alert.informativeText = "The link is invaid."
      alert.runModal()
    }
  }

  func applicationWillTerminate(_ aNotification: Notification) {
    fileWatcher.stop()
  }

  func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

}
