//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct DeleteChannelsResult: Codable, Hashable {
    public var status: String
    public var error: String? = nil

    public init(status: String, error: String? = nil) {
        self.status = status
        self.error = error
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case status
        case error
    }
}