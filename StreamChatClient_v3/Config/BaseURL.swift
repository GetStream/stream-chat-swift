//
// BaseURL.swift
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation

/// A base URL for the `Client`.
public struct BaseURL: CustomStringConvertible {
  public static let usEast = BaseURL(urlString: "https://chat-proxy-us-east.stream-io-api.com/")
  public static let dublin = BaseURL(urlString: "https://chat-proxy-dublin.stream-io-api.com/")

  static let placeholderURL = URL(string: "https://getstream.io")!

  public let baseURL: URL
  public let wsURL: URL

  public var description: String { baseURL.absoluteString }

  /// Create a base URL from an URL string.
  ///
  /// - Parameter urlString: a Stream Chat server location url string.
  init(urlString: String) {
    self.init(url: URL(string: urlString)!)
  }

  /// Init with a custom server URL.
  ///
  /// - Parameter url: an URL
  init(url: URL) {
    var urlString = url.absoluteString

    // Remove a scheme prefix.
    for prefix in ["https:", "http:", "wss:", "ws:"] {
      if urlString.hasPrefix(prefix) {
        urlString = String(urlString.suffix(urlString.count - prefix.count))
        break
      }
    }

    urlString = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    self.baseURL = URL(string: "https://\(urlString)/")!
    self.wsURL = URL(string: "wss://\(urlString)/")!
  }
}
