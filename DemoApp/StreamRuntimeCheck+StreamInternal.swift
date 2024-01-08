//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension StreamRuntimeCheck {
    static var isStreamInternalConfiguration: Bool {
        ProcessInfo.processInfo.environment["STREAM_DEV"] != nil
    }
}
