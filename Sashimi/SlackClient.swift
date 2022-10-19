//
//  SlackClient.swift
//  Sashimi
//
//  Created by Riley Sommerville on 19/10/2022.
//

import AppKit
import Foundation

open class SlackClient {

  public struct SlackStatus: Codable {
    var status_emoji: String
    var status_expiration: Int?
    var status_text: String
  }

  private let clientId: String
  private var token: String!

  init(_ clientIdParam: String, withAccessToken tokenParam: String? = nil) {
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
     Checks if the client has an access token.

     - returns Wether or not the client has an access token.
     */
  open func hasToken() -> Bool {
    return token != nil
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
  open func setStatus(_ status: SlackStatus) {
    guard let url = URL(string: "https://slack.com/api/users.profile.set") else {
      return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-type")
    request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization")

    do {
      let jsonData = try JSONEncoder().encode(status)
      request.httpBody = jsonData
    } catch let jsonErr {
      print(jsonErr)
    }

    let task = URLSession.shared.dataTask(with: request) { (data, response, error) in

      if let error = error {
        print("Error \(error)")
        return
      }

      if let data = data, let dataString = String(data: data, encoding: .utf8) {
        print("Response data string:\n \(dataString)")

      }
    }
    task.resume()
  }
  
  /**
     Clears the user status.
     */
  open func clearStatus() {
    setStatus(SlackStatus(status_emoji: "", status_text: ""))
  }
}
