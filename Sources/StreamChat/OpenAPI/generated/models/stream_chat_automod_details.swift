//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAutomodDetails: Codable, Hashable {
    public var action: String?
    
    public var imageLabels: [String]?
    
    public var messageDetails: StreamChatFlagMessageDetails?
    
    public var originalMessageType: String?
    
    public var result: StreamChatMessageModerationResult?
    
    public init(action: String?, imageLabels: [String]?, messageDetails: StreamChatFlagMessageDetails?, originalMessageType: String?, result: StreamChatMessageModerationResult?) {
        self.action = action
        
        self.imageLabels = imageLabels
        
        self.messageDetails = messageDetails
        
        self.originalMessageType = originalMessageType
        
        self.result = result
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case action
        
        case imageLabels = "image_labels"
        
        case messageDetails = "message_details"
        
        case originalMessageType = "original_message_type"
        
        case result
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(action, forKey: .action)
        
        try container.encode(imageLabels, forKey: .imageLabels)
        
        try container.encode(messageDetails, forKey: .messageDetails)
        
        try container.encode(originalMessageType, forKey: .originalMessageType)
        
        try container.encode(result, forKey: .result)
    }
}
