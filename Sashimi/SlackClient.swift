//
//  SlackClient.swift
//  Sashimi
//
//  Created by Riley Sommerville on 19/10/2022.
//

import Foundation
import AppKit

open class SlackClient {
    private let clientId: String
    var token: String!
    
    
    init(_ clientIdParam: String, withAccessToken tokenParam: String?) {
        clientId = clientIdParam
        token = tokenParam
    }
    
    /**
     Sets the token to use for API requests.
     
     - parameter _: The token to use.
     */
    open func setToken(_ tokenParam: String?) {
        token = tokenParam
    }
    
    /**
     Opens a browser to request an authorisation code from Slack.
     
     - parameter scope: The Slack scopes to request access to.
     */
    open func authorise(withScope scope: String) {
        let url = URL(string: "https://slack.com/oauth/authorize?client_id=\(clientId)&scope=\(scope)")!
        NSWorkspace.shared.open(url)
    }
    
    /**
     Sets the user status.
     
     - parameter emoji: The emoji string to set the status to. A nil value uses the Slack default status emoji.
     - parameter text: The text to set the status to.
     */
    open func setStatus(emoji: String?, text: String?) {
        // TODO: Send Slack API call
    }
}
