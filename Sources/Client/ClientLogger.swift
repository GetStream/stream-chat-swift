//
//  ClientLogger.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct ClientLogger {
    
    private let logDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy HH:mm:ss.SSS"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        return dateFormatter
    }()
    
    func log(_ request: URLRequest) {
        log(request.httpMethod ?? "Request", message: request.description)
        
        if let headers = request.allHTTPHeaderFields {
            log("Request Headers", message: headers.description)
        }
        
        if let bodyStream = request.httpBodyStream {
            log("Request Body Stream", message: bodyStream.description)
        }
        
        if let body = request.httpBody {
            do {
                log("Request Body", message: try body.prettyPrintedJSONString())
            } catch {
                log("Request Body", message: error.localizedDescription)
            }
        }
    }
    
    func log(_ response: URLResponse?, data: Data?) {
        if let response = response {
            log("Response", message: response.description)
        }
        
        if let data = data{
            if let jsonString = try? data.prettyPrintedJSONString() {
                log("JSON", message: jsonString)
            } else if let dataString = String(data: data, encoding: .utf8) {
                log("JSON", message: dataString)
            } else {
                log("JSON", message: data.description)
            }
        }
    }
    
    func log(_ error: Error?) {
        if let error = error {
            print("[\(logDateFormatter.string(from: Date()))] \(error)")
        }
    }
    
    func log(_ identifier: String, message: String) {
        print("[\(logDateFormatter.string(from: Date()))] \(identifier): \(message)")
    }
}
