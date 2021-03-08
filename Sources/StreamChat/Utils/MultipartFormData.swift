//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation

struct MultipartFormData {
    private static let crlf = "\r\n"

    let boundary: String
    let data: Data
    let fileName: String
    let mimeType: String?

    init(_ data: Data, fileName: String, mimeType: String? = nil) {
        boundary = String(format: "chat-%08x%08x", UInt32.random(in: 0...UInt32.max), UInt32.random(in: 0...UInt32.max))
        self.data = data
        self.fileName = fileName
        self.mimeType = mimeType
    }

    func getMultipartFormData() -> Data {
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

private extension Data {
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        append(string.data(using: encoding, allowLossyConversion: false)!)
    }
}
