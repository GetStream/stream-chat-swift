//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAPIError: Codable, Hashable {
    public var exceptionFields: [String: RawJSON]?
    
    public var message: String
    
    public var moreInfo: String
    
    public var statusCode: Int
    
    public var code: Int
    
    public var details: [Int]
    
    public var duration: String
    
    public init(exceptionFields: [String: RawJSON]?, message: String, moreInfo: String, statusCode: Int, code: Int, details: [Int], duration: String) {
        self.exceptionFields = exceptionFields
        
        self.message = message
        
        self.moreInfo = moreInfo
        
        self.statusCode = statusCode
        
        self.code = code
        
        self.details = details
        
        self.duration = duration
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case exceptionFields = "exception_fields"
        
        case message
        
        case moreInfo = "more_info"
        
        case statusCode = "StatusCode"
        
        case code
        
        case details
        
        case duration
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(exceptionFields, forKey: .exceptionFields)
        
        try container.encode(message, forKey: .message)
        
        try container.encode(moreInfo, forKey: .moreInfo)
        
        try container.encode(statusCode, forKey: .statusCode)
        
        try container.encode(code, forKey: .code)
        
        try container.encode(details, forKey: .details)
        
        try container.encode(duration, forKey: .duration)
    }
}
