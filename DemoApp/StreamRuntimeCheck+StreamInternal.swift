//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension StreamRuntimeCheck {
    static var isStreamInternalConfiguration: Bool {
        ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
    }
    
    static var logLevel: LogLevel? {
        guard let value = ProcessInfo.processInfo.environment["STREAM_LOG_LEVEL"] else { return nil }
        guard let intValue = Int(value) else { return nil }
        return LogLevel(rawValue: intValue)
    }
}
