//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

extension ChatClient {
    static var current: ChatClient?
    
    static func forCredentials(_ userCredentials: UserCredentials) -> ChatClient {
        // Create a token
        let token = try! Token(rawValue: userCredentials.token)
        
        // Create config
        var config = ChatClientConfig(apiKey: .init(userCredentials.apiKey))
        // Set database to app group location to share data with chat widget
        config.localStorageFolderURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: UserDefaults.groupId)
        // Create client
        return ChatClient(config: config, tokenProvider: .static(token))
    }
}
