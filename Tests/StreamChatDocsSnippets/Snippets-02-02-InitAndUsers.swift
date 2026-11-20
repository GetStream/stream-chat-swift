//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/init-and-users/

import StreamChat

// Recommendation is to store it as a shared instance
private extension ChatClient {
  static var shared: ChatClient!
}

struct Snippets_02_02_InitAndUsers {
    var chatClient: ChatClient!
    var userID: String!
    var token: Token!

    enum NetworkingLayer {
        static func getChatToken(completion: @escaping (String) -> Void) {}
    }

    func initializationAndUsers() {
        // API key can be found on the dashboard: https://dashboard.getstream.io/?product=chat
        let config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))

        // Create an instance of ChatClient
        let chatClient = ChatClient(config: config)

        ChatClient.shared = chatClient
    }

    // An example of a token provider
    func loadChatToken(completion: @escaping (Result<Token, Error>) -> Void) {
      NetworkingLayer.getChatToken() { token in
        do {
          let token = try Token(rawValue: token)
          completion(.success(token))
        } catch {
          completion(.failure(error))
        }
      }
    }

    func connectingUsers() async throws {
        // Option A: with expiring token
        // The `tokenProvider` closure will be called again when the token is expired
        ChatClient.shared.connectUser(
          userInfo: .init(id: userID),
          tokenProvider: { providerResult in
            loadChatToken(completion: providerResult)
          },
          completion: { error in
            if let error = error {
              print("Connection failed with: \(error)")
            } else {
              // User successfully connected
            }
          }
        )
        // or alternatively, using the async-await method
        let connectedUser = try await ChatClient.shared.connectUser(
          userInfo: .init(id: userID),
          tokenProvider: { providerResult in
            loadChatToken(completion: providerResult)
          }
        )

        // Option B: with a non-expiring token
        // You can generate the token for this user server-side, see /docs/platform/authentication/
        let token: Token = "<# Your User Token Here #>"

        /// Connect the user using a closure based method
        ChatClient.shared.connectUser(
          userInfo: .init(id: userID),
          token: token
        ) { error in
          if let error = error {
            print("Connection failed with: \(error)")
          } else {
            // User successfully connected
          }
        }
        // or alternatively, using the async-await method
        try await ChatClient.shared.connectUser(
          userInfo: .init(id: userID),
          token: token
        )
        suppressUnusedWarning(connectedUser)
    }

    func disconnectingUsers() async {
        chatClient.disconnect {
          // disconnected
        }
        // or
        await chatClient.disconnect()
    }

    func privacySettings() async throws {
        // Connect the user using a closure based method
        chatClient.connectUser(
          userInfo: .init(
            id: userID,
            privacySettings: .init(
              typingIndicators: .init(enabled: false),
              readReceipts: .init(enabled: false)
            )
          ),
          token: token
        ) { error in
          // …
        }
        // or alternatively, using the async-await method
        let connectedUser = try await chatClient.connectUser(
          userInfo: .init(
            id: userID,
            privacySettings: .init(
              typingIndicators: .init(enabled: false),
              readReceipts: .init(enabled: false)
            )
          ),
          token: token
        )
        suppressUnusedWarning(connectedUser)
    }
}
