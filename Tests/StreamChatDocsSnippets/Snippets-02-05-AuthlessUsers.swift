//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/authless-users/

import StreamChat

struct Snippets_02_05_AuthlessUsers {
    var chatClient: ChatClient!

    func guestUsers() async throws {
        chatClient.connectGuestUser(
          userInfo: .init(id: "john-doe")
        ) { error in
          // …
        }
        // or
        let connectedUser = try await chatClient.connectGuestUser(
          userInfo: .init(id: "john-doe")
        )
        suppressUnusedWarning(connectedUser)
    }

    func anonymousUsers() async throws {
        chatClient.connectAnonymousUser() { error in
          // …
        }
        // or
        let connectedUser = try await chatClient.connectAnonymousUser()
        suppressUnusedWarning(connectedUser)
    }
}
