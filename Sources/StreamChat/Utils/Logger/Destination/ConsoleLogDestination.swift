//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic destination for outputting messages to console.
public class ConsoleLogDestination: BaseLogDestination, @unchecked Sendable {
    override open func write(message: String) {
        print(message)
    }
}
