//
//  MultipartFormData.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 03/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct MultipartFormData {
    private static let crlf = "\r\n"
    
    let boundary: String
    private let data: Data
    private let fileName: String
    private let mimeType: String?
    
    init(_ data: Data, fileName: String, mimeType: String? = nil) {
        boundary = String(format: "chat-%08x%08x", arc4random(), arc4random())
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    var multipartFormData: Data {
        var data = "--\(boundary)\(MultipartFormData.crlf)".data(using: .utf8, allowLossyConversion: false)!
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(MultipartFormData.crlf)")
        
        if let mimeType = mimeType {
            data.append("Content-Type: \(mimeType)\(MultipartFormData.crlf)")
        }
        
        data.append(MultipartFormData.crlf)
        data.append(self.data)
        data.append("\(MultipartFormData.crlf)--\(boundary)--\(MultipartFormData.crlf)")
        
        return data
    }
}
