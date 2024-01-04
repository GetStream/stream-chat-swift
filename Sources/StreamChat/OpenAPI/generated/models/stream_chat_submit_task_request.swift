//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSubmitTaskRequest: Codable, Hashable {
    public var evaluations: [StreamChatEvaluationRequest?]?
    
    public var extra: [String: RawJSON]?
    
    public var payload: [String: RawJSON]
    
    public var contentType: String
    
    public init(evaluations: [StreamChatEvaluationRequest?]?, extra: [String: RawJSON]?, payload: [String: RawJSON], contentType: String) {
        self.evaluations = evaluations
        
        self.extra = extra
        
        self.payload = payload
        
        self.contentType = contentType
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case evaluations
        
        case extra
        
        case payload
        
        case contentType = "content_type"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(evaluations, forKey: .evaluations)
        
        try container.encode(extra, forKey: .extra)
        
        try container.encode(payload, forKey: .payload)
        
        try container.encode(contentType, forKey: .contentType)
    }
}
