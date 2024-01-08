//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatSearchWarning: Codable, Hashable {
    public var channelSearchCids: [String]?
    
    public var channelSearchCount: Int?
    
    public var warningCode: Int
    
    public var warningDescription: String
    
    public init(channelSearchCids: [String]?, channelSearchCount: Int?, warningCode: Int, warningDescription: String) {
        self.channelSearchCids = channelSearchCids
        
        self.channelSearchCount = channelSearchCount
        
        self.warningCode = warningCode
        
        self.warningDescription = warningDescription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case channelSearchCids = "channel_search_cids"
        
        case channelSearchCount = "channel_search_count"
        
        case warningCode = "warning_code"
        
        case warningDescription = "warning_description"
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(channelSearchCids, forKey: .channelSearchCids)
        
        try container.encode(channelSearchCount, forKey: .channelSearchCount)
        
        try container.encode(warningCode, forKey: .warningCode)
        
        try container.encode(warningDescription, forKey: .warningDescription)
    }
}
