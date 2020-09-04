//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChatClient

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
