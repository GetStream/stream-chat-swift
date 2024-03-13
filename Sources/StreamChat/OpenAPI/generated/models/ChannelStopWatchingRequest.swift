//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct ChannelStopWatchingRequest: Codable, Hashable {
    public var clientId: String? = nil
    public var connectionId: String? = nil

    public init(clientId: String? = nil, connectionId: String? = nil) {
        self.clientId = clientId
        self.connectionId = connectionId
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case clientId = "client_id"
        case connectionId = "connection_id"
    }
}
