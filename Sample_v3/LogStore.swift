//
//  LogStore.swift
//  StreamChatClient
//
//  Created by Matheus Cardoso on 20/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import Foundation

class LogStore: BaseLogDestination {
    var logs = ""
    
    static let shared = LogStore()
    
    static func registerShared() {
        log.destinations.append(LogStore.shared)
    }
    
    override func write(message: String) {
        logs += message
    }
}
