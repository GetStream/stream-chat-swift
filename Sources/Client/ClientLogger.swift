//
//  ClientLogger.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct ClientLogger {
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
        
        if let body = request.httpBody, !body.isEmpty {
            do {
                log("Request Body", try body.prettyPrintedJSONString())
            } catch {
                log("Request Body", error.localizedDescription)
            }
        }
    }
    
    func log(_ response: URLResponse?, data: Data?) {
        if let response = response {
            log("Response", response.description)
        }
        
        if let data = data{
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
            log("\(error)")
        }
    }
    
    func log(_ identifier: String, _ message: String) {
        log("\(identifier): \(message)")
    }
    
    func log(_ message: String) {
        print(icon, "[\(logDateFormatter.string(from: Date()))] \(message)")
    }
}
