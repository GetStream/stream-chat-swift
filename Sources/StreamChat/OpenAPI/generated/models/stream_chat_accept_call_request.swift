//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatAcceptCallRequest: Codable, Hashable {
    public init() {}

//    public enum CodingKeys: String, CodingKey, CaseIterable {
//
//    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
    }
}
