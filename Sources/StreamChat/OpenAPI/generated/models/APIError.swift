//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct APIError: Codable, Hashable {
    public var code: Int
    
    public var duration: String
    
    public var message: String
    
    public var moreInfo: String
    
    public var statusCode: Int
    
    public var details: [Int]
    
    public var exceptionFields: [String: String]? = nil
    
    public init(code: Int, duration: String, message: String, moreInfo: String, statusCode: Int, details: [Int], exceptionFields: [String: String]? = nil) {
        self.code = code
        
        self.duration = duration
        
        self.message = message
        
        self.moreInfo = moreInfo
        
        self.statusCode = statusCode
        
        self.details = details
        
        self.exceptionFields = exceptionFields
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case code
        
        case duration
        
        case message
        
        case moreInfo = "more_info"
        
        case statusCode = "StatusCode"
        
        case details
        
        case exceptionFields = "exception_fields"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(code, forKey: .code)
        
        try container.encode(duration, forKey: .duration)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(moreInfo, forKey: .moreInfo)
        
        try container.encode(statusCode, forKey: .statusCode)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(exceptionFields, forKey: .exceptionFields)
    }
}
