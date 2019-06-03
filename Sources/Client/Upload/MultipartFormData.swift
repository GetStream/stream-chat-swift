//
//  MultipartFormData.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct MultipartFormData {
    private static let crlf = "\r\n"
    
    enum FormDataProvider {
        case data(Foundation.Data)
        case file(URL)
        
        var data: Data? {
            switch self {
            case .data(let data):
                return data
            case .file(let url):
                return try? Data(contentsOf: url)
            }
        }
    }
    
    let boundary: String
    let provider: FormDataProvider
    let fileName: String
    let mimeType: String?
    
    init(provider: FormDataProvider, fileName: String, mimeType: String? = nil) {
        boundary = String(format: "chat-%08x%08x", arc4random(), arc4random())
        self.provider = provider
        self.fileName = fileName
        self.mimeType = mimeType
    }
    
    var data: Data? {
        guard let providerData = provider.data else {
            return nil
        }
        
        var data = "--\(boundary)\(MultipartFormData.crlf)".data(using: .utf8, allowLossyConversion: false)!
        data.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(fileName)\"\(MultipartFormData.crlf)")
        
        if let mimeType = mimeType {
            data.append("Content-Type: \(mimeType)\(MultipartFormData.crlf)")
        }
        
        data.append(MultipartFormData.crlf)
        data.append(providerData)
        data.append("\(MultipartFormData.crlf)--\(boundary)--\(MultipartFormData.crlf)")
        
        return data
    }
}
