//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic destination for outputting messages to console.
public final class ConsoleLogDestination: BaseLogDestination, @unchecked Sendable {
    override public func write(message: String) {
        print(message)
    }
}
