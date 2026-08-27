//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class DeliveryReceiptsPrivacySettings: @unchecked Sendable, Codable, JSONEncodable {
    public var enabled: Bool

    public init(enabled: Bool = true) {
        self.enabled = enabled
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case enabled
    }
}
