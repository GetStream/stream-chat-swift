//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// Basic destination for outputting messages to console.
public class ConsoleLogDestination: BaseLogDestination {
    override open func write(message: String) {
        print(message)
    }
}
