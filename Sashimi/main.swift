//
//  main.swift
//  Sashimi
//
//  Created by Riley Sommerville on 17/10/2022.
//

import AppKit
import Foundation

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
