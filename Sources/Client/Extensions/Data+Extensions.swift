//
//  Data+Extensions.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 02/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

extension Data {
    
    static let empty = Data()
    
    func prettyPrintedJSONString() throws -> String {
        let object = try JSONSerialization.jsonObject(with: self)
        let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted])
        return String(data: data, encoding: .utf8) ?? data.description
    }
    
    mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        append(string.data(using: encoding, allowLossyConversion: false)!)
    }
    
    /// Conver a data to the HEX string.
    public var hex: String {
        return map({ String(format: String.dataToHEXFormat, $0) }).joined()
    }
}
