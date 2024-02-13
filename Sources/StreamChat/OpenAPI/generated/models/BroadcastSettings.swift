//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct BroadcastSettings: Codable, Hashable {
    public var enabled: Bool
    public var hls: HLSSettings

    public init(enabled: Bool, hls: HLSSettings) {
        self.enabled = enabled
        self.hls = hls
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
        case hls
    }
}
