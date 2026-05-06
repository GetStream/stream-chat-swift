//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public extension EmptyResponse {
    init() {
        self = try! JSONDecoder().decode(Self.self, from: Data("{}".utf8))
    }
}
