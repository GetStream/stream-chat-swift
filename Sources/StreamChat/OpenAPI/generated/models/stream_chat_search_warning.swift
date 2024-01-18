//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchWarning: Codable, Hashable {
    public var warningCode: Int
    
    public var warningDescription: String
    
    public var channelSearchCids: [String]?
    
    public var channelSearchCount: Int?
    
    public init(warningCode: Int, warningDescription: String, channelSearchCids: [String]?, channelSearchCount: Int?) {
        self.warningCode = warningCode
        
        self.warningDescription = warningDescription
        
        self.channelSearchCids = channelSearchCids
        
        self.channelSearchCount = channelSearchCount
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case warningCode = "warning_code"
        
        case warningDescription = "warning_description"
        
        case channelSearchCids = "channel_search_cids"
        
        case channelSearchCount = "channel_search_count"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(warningCode, forKey: .warningCode)
        
        try container.encode(warningDescription, forKey: .warningDescription)
        
        try container.encode(channelSearchCids, forKey: .channelSearchCids)
        
        try container.encode(channelSearchCount, forKey: .channelSearchCount)
    }
}
