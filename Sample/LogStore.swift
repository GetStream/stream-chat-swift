//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

class LogStore: BaseLogDestination {
    @Atomic var logs = ""
    
    static let shared = LogStore()
    
    static func registerShared() {
        log.destinations.append(LogStore.shared)
    }
    
    override func write(message: String) {
        _logs { $0 += message }
    }
}
