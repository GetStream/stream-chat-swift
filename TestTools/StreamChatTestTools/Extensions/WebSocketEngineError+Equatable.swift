//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension WebSocketEngineError: @retroactive Equatable {
    public static func == (lhs: WebSocketEngineError, rhs: WebSocketEngineError) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
