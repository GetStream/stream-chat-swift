//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PollOption {
    public let id: String
    public var text: String?
    public var custom: [String: RawJSON]?
}
