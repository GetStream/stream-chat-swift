//
//  ClientLogger.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

/// A Client logger.
public struct ClientLogger {
    
    /// A customizable logger block.
    public static var logger: (_ icon: String, _ dateAndTime: String, _ message: String) -> Void = { print($0, "[\($1)]", $2) }
    
    let icon: String
    
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
        log(request.httpMethod ?? "Request", request.description)
        
        if let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log("Request Headers", headers.description)
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
    
    func log(_ response: URLResponse?, data: Data?) {
        if let response = response {
            log("Response", response.description)
        }
        
        if let data = data {
            if let jsonString = try? data.prettyPrintedJSONString() {
                log("JSON", jsonString)
            } else if let dataString = String(data: data, encoding: .utf8) {
                log("JSON", dataString)
            } else {
                log("JSON", data.description)
            }
        }
    }
    
    func log(_ error: Error?, message: String? = nil) {
        if let error = error {
            if let message = message {
                log(message)
            }
            
            log("\(error)")
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
}
