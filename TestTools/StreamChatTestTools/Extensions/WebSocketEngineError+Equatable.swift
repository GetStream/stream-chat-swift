//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat

extension WebSocketEngineError: Equatable {
    public static func == (lhs: WebSocketEngineError, rhs: WebSocketEngineError) -> Bool {
        String(describing: lhs) == String(describing: rhs)
    }
}
