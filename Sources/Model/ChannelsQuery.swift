//
//  ChannelsQuery.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 17/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import Foundation

struct ChannelsQuery: Encodable {
    private enum CodingKeys: String, CodingKey {
        case filter = "filter_conditions"
        case sort
        case user = "user_details"
        case limit
        case state
        case watch
        case presence
        case offset
    }
    
    let filter: Filter
    let sort: [Sorting]
    let limit: Int = 20
    let user: User
    let state = true
    let watch = true
    let presence = false
    let offset = 0
}

extension ChannelsQuery {
    struct Filter: Encodable {
        let type: ChannelType
    }
    
    enum Sorting: Encodable {
        private enum CodingKeys: String, CodingKey {
            case field
            case direction
        }
        
        case lastMessage(isAscending: Bool)
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .lastMessage(let isAscending):
                try container.encode("last_message_at", forKey: .field)
                try container.encode(isAscending ? 1 : -1, forKey: .direction)
            }
        }
    }
}
