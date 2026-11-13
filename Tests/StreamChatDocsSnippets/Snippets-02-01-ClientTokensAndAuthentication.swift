//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/tokens-and-authentication/

import StreamChat

struct Snippets_02_01_ClientTokensAndAuthentication {
    var chatClient: ChatClient!

    func developerTokens() async throws {
        // Using a completion handler
        chatClient.connectUser(
            userInfo: .init(id: "john-doe"),
            token: .development(userId: "john-doe")
        ) { error in
            if let error = error {
                print("Connection failed with: \(error)")
            }
        }
        // or using async/await
        try await chatClient.connectUser(
            userInfo: .init(id: "john-doe"),
            token: .development(userId: "john-doe")
        )
    }
}
