//
//  ClientLogger.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

/// A Client logger.
public final class ClientLogger {
    public enum Options {
        case none
        case requests
        case requestsHeaders
        case webSocket
        case all
    }
    
    /// A customizable logger block.
    public static var logger: (_ icon: String, _ dateAndTime: String, _ message: String) -> Void = { print($0, "[\($1)]", $2) }
    
    private let icon: String
    private var lastTime: CFTimeInterval
    private var startTime: CFTimeInterval
    private let options: Options
    
    init(icon: String, options: Options = .all) {
        self.icon = icon
        self.options = options
        startTime = CACurrentMediaTime()
        lastTime = startTime
    }

    private let logDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    func log(_ sessionConfiguration: URLSessionConfiguration) {
        if let httpAdditionalHeaders = sessionConfiguration.httpAdditionalHeaders as? [String: String] {
            log("URL Session Headers", httpAdditionalHeaders.description)
        }
    }
    
    func log(_ request: URLRequest) {
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
    
    func log(_ queryItems: [URLQueryItem]) {
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
    
    func log(_ response: URLResponse?, data: Data?, forceToShowData: Bool = false) {
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
    
    func log(_ error: Error?, message: String? = nil, function: String = #function, line: Int = #line) {
        if let error = error {
            if let message = message {
                log(message)
            }
            
            log("\(error) in \(function)[\(line)]")
        }
    }
    
    func timing(_ tag: String = "", reset: Bool = false) {
        let overall: CFTimeInterval = round((CACurrentMediaTime() - startTime) * 1000) / 1000
        let time: CFTimeInterval = round((CACurrentMediaTime() - lastTime) * 1000) / 1000
        log("⏱ \(tag) \(overall) +\(time < 0.001 ? 0 : time)")
        lastTime = CACurrentMediaTime()
        
        if reset {
            startTime = lastTime
        }
    }
    
    func log(_ identifier: String, _ data: Data?) {
        guard let data = data, !data.isEmpty else {
            log(identifier, "Data is empty")
            return
        }
        
        do {
            log(identifier, try data.prettyPrintedJSONString())
        } catch {
            log(identifier, error.localizedDescription)
        }
    }
    
    func log(_ identifier: String, _ message: String) {
        log("\(identifier) \(message)")
    }
    
    func log(_ message: String) {
        ClientLogger.logger(icon, logDateFormatter.string(from: Date()), message)
    }
    
    static func showConnectionAlert(_ error: Error, jsonError: WebSocket.Error?) {
        #if DEBUG
        let jsonError = jsonError ?? WebSocket.Error(code: 0, message: "<unknown>", statusCode: 0)
        let message = "\(jsonError.message)\n\nCode: \(jsonError.code)\nStatus Code: \(jsonError.statusCode)\n\n\(error)"
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Connection Error", message: message, preferredStyle: .alert)
            alert.addAction(.init(title: "Ok, I'll check", style: .cancel, handler: nil))
            UIApplication.shared.delegate?.window??.rootViewController?.present(alert, animated: true)
        }
        #endif
    }
}
