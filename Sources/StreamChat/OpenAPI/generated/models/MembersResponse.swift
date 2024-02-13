//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct MembersResponse: Codable, Hashable {
    public var duration: String
    public var members: [ChannelMember?]

    public init(duration: String, members: [ChannelMember?]) {
        self.duration = duration
        self.members = members
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case duration
        case members
    }
}
