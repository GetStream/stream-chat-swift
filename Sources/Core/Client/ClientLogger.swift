//
//  ClientLogger.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A Client logger.
public final class ClientLogger {
    /// A client logger options.
    public enum Options {
        /// No logs.
        case none
        /// Logs for requests.
        case requests
        /// Logs only requests headers.
        case requestsHeaders
        /// Logs for a web socket.
        case webSocket
        /// All logs.
        case all
        
        var isEnabled: Bool {
            if case .none = self {
                return false
            }
            
            return true
        }
    }
    
    /// A customizable logger block.
    /// By default error messages will print to the console, but you can customize it to use own logger.
    ///
    /// - Parameters:
    ///     - icon: a small icon string like a tag for messages, e.g. 🦄
    ///     - dateAndTime: a formatted string of date and time, could be empty.
    ///     - message: a message.
    public static var logger: (_ icon: String, _ dateTime: String, _ message: String) -> Void = {
        if Client.shared.logOptions.isEnabled {
            print($0, $1.isEmpty ? "" : "[\($1)]", $2)
        }
    }
    
    private let icon: String
    private var lastTime: CFTimeInterval
    private var startTime: CFTimeInterval
    private let options: Options
    
    /// Init a client logger.
    ///
    /// - Parameters:
    ///   - icon: a string icon.
    ///   - options: options (see `ClientLogger.Options`).
    public init(icon: String, options: Options = .none) {
        self.icon = icon
        self.options = options
        startTime = CACurrentMediaTime()
        lastTime = startTime
    }
    
    /// Log URLSessionConfiguration.
    ///
    /// - Parameter sessionConfiguration: an URL session configuration.
    public func log(_ sessionConfiguration: URLSessionConfiguration) {
        if let httpAdditionalHeaders = sessionConfiguration.httpAdditionalHeaders as? [String: String] {
            log("URL Session Headers", httpAdditionalHeaders.description)
        }
    }
    
    /// Log a request.
    ///
    /// - Parameter request: an URL request.
    public func log(_ request: URLRequest) {
        log("➡️ \(request.httpMethod ?? "Request")", request.description)
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            var message = "Request headers:\n"
            headers.forEach { message += "◾️ \($0) = \($1)\n" }
            log(message)
        }
        
        if let bodyStream = request.httpBodyStream {
            log("Request Body Stream", bodyStream.description)
        }
        
        if let body = request.httpBody {
            log("Request Body", body)
        }
    }
    
    /// Log URL query items.
    ///
    /// - Parameter queryItems: URL query items
    public func log(_ queryItems: [URLQueryItem]) {
        guard !queryItems.isEmpty else {
            return
        }
        
        var message = "URL query items:\n"
        
        queryItems.forEach { item in
            if let value = item.value,
                value.hasPrefix("{"),
                let data = value.data(using: .utf8),
                let json = try? data.prettyPrintedJSONString() {
                message += "▫️ \(item.name)=\(json)"
            } else {
                message += "▫️ \(item.description)\n"
            }
        }
        
        log(message)
    }
    
    /// Log URL response.
    ///
    /// - Parameters:
    ///   - response: an URL response.
    ///   - data: a response data.
    ///   - forceToShowData: force to always log a data.
    public func log(_ response: URLResponse?, data: Data?, forceToShowData: Bool = false) {
        if let response = response {
            log("Response", response.description)
        }
        
        guard let data = data else {
            return
        }
        
        if !forceToShowData, options == .requestsHeaders, data.count > 500 {
            return
        }
        
        let tag = "ⒿⓈⓄⓃ \(data.description)"
        
        if let jsonString = try? data.prettyPrintedJSONString() {
            log(tag, jsonString)
        } else if let dataString = String(data: data, encoding: .utf8) {
            log(tag, "\"\(dataString)\"")
        }
    }
    
    /// Log an error.
    ///
    /// - Parameters:
    ///   - icon: a string icon, e.g. emoji.
    ///   - error: an error.
    ///   - message: an additional message (optional).
    ///   - function: a callee function (auto).
    ///   - line: a callee line of a code in a function (auto).
    public static func log(_ icon: String = "",
                           _ error: Error?,
                           message: String? = nil,
                           function: String = #function,
                           line: Int = #line) {
        if let error = error {
            ClientLogger.logger("\(icon)❌", "", "\(message ?? "") \(error) in \(function)[\(line)]")
        }
    }
    
    /// Calculate and log a timing from the previous call.
    ///
    /// - Parameters:
    ///   - tag: a tag.
    ///   - reset: reset the last timing.
    public func timing(_ tag: String = "", reset: Bool = false) {
        let overall: CFTimeInterval = round((CACurrentMediaTime() - startTime) * 1000) / 1000
        let time: CFTimeInterval = round((CACurrentMediaTime() - lastTime) * 1000) / 1000
        log("⏱ \(tag) \(overall) +\(time < 0.001 ? 0 : time)")
        lastTime = CACurrentMediaTime()
        
        if reset {
            startTime = lastTime
        }
    }
    
    /// Log a data as a pretty printed JSON string.
    ///
    /// - Parameters:
    ///   - identifier: an identifier.
    ///   - data: a data.
    public func log(_ identifier: String, _ data: Data?) {
        guard let data = data, !data.isEmpty else {
            log(identifier, "Data is empty")
            return
        }
        
        do {
            log(identifier, try data.prettyPrintedJSONString())
        } catch {
            log(identifier, "\(error)")
        }
    }
    
    /// Log a message with an identifier.
    ///
    /// - Parameters:
    ///   - identifier: an identifier.
    ///   - message: a message.
    public func log(_ identifier: String, _ message: String) {
        ClientLogger.log(icon, dateTime: Date().log, "\(identifier) \(message)")
    }
    
    /// Log a message.
    ///
    /// - Parameter message: a message.
    public func log(_ message: String) {
        ClientLogger.log(icon, dateTime: Date().log, message)
    }
    
    /// Log a message.
    ///
    /// - Parameters:
    ///   - icon: a string icon, e.g. emoji.
    ///   - dateTime: a date time as a string.
    ///   - message: a message.
    public static func log(_ icon: String, dateTime: String = "", _ message: String) {
        ClientLogger.logger(icon, dateTime, message)
    }
    
    static func showConnectionAlert(_ error: Error, jsonError: ClientErrorResponse?) {
        #if DEBUG
        let jsonError = jsonError ?? ClientErrorResponse(code: 0, message: "<unknown>", statusCode: 0)
        let message = "\(jsonError.message)\n\nCode: \(jsonError.code)\nStatus Code: \(jsonError.statusCode)\n\n\(error)"
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "Ok, I'll check", style: .cancel, handler: nil))
            UIApplication.shared.delegate?.window??.rootViewController?.present(alert, animated: true)
        }
        #endif
    }
}

extension Date {
    
    private static let logDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    /// A string of the date for the `ClientLogger`.
    public var log: String {
        return Date.logDateFormatter.string(from: self)
    }
}
