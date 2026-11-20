//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// https://getstream.io/chat/docs/ios-swift/

import Combine
import StreamChat
import UIKit

// For simplicity, we extend ChatClient to add a static `shared` singleton
private extension ChatClient {
    static var shared: ChatClient!
}

@MainActor
struct Snippets_01_01_IOSIntroduction {
    var channelController: ChatChannelController!
    var chat: Chat!
    var cancellables: Set<AnyCancellable>!

    enum NetworkingLayer {
        static func getChatToken(completion: @escaping (String) -> Void) {}
    }

    class ViewController: UIViewController, ChatChannelControllerDelegate {
        func channelController(
            _ channelController: ChatChannelController,
            didUpdateMessages changes: [ListChange<ChatMessage>]
        ) {
            // animate the changes to the message list
        }
    }

    // An example of a token provider
    nonisolated func loadChatToken(completion: @escaping (Result<Token, Error>) -> Void) {
      NetworkingLayer.getChatToken() { token in
        do {
          let token = try Token(rawValue: token)
          completion(.success(token))
        } catch {
          completion(.failure(error))
        }
      }
    }

    func chatClient() async throws {
        // Import StreamChat framework.

        // API key can be found on the dashboard: https://dashboard.getstream.io/?product=chat
        let config = ChatClientConfig(apiKey: .init("<# Your API Key Here #>"))
        let userID = "leia_organa"

        // Create an instance of ChatClient and share it using the singleton
        ChatClient.shared = ChatClient(config: config)

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
        // You can generate the token for this user server-side, see /chat/docs/ios-swift/tokens-and-authentication/
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
        // or alternatively, using the async-await version
        try await ChatClient.shared.connectUser(
          userInfo: .init(id: userID),
          token: token
        )
        suppressUnusedWarning(connectedUser)
    }

    func guestAndAnonymousUsers() async throws {
        // Connect as a guest user: the backend generates a token automatically
        try await ChatClient.shared.connectGuestUser(userInfo: .init(id: "guest_user"))

        // Connect as an anonymous user: no user identity is required
        try await ChatClient.shared.connectAnonymousUser()
    }

    func disconnectingAndLoggingOut() async {
        // Disconnect: keeps local data intact for offline use
        await ChatClient.shared.disconnect()

        // Logout: clears the session and removes the push device token
        await ChatClient.shared.logout()

        // Logout while keeping push notifications active (e.g. for silent pushes)
        ChatClient.shared.logout(removeDevice: false) {
          // Logout completed
        }
    }

    func channels() throws {
        /// 1: Create a `ChannelId` that represents the channel you want to create.
        let channelId = ChannelId(type: .messaging, id: "general")

        /// 2: Use the `ChatClient` to create a `ChatChannelController` with the `ChannelId`.
        let channelController = try ChatClient.shared.channelController(
          createChannelWithId: channelId,
          extraData: ["info": .string("Hello")]
        )

        /// 3: Call `ChatChannelController.synchronize` to create the channel.
        channelController.synchronize { error in
          if let error = error {
            /// 4: Handle possible errors
            print(error)
          }
        }
    }

    func channels2() async throws {
        /// 1: Create a `ChannelId` that represents the channel you want to create.
        let channelId = ChannelId(type: .messaging, id: "general")

        /// 2: Use the `ChatClient` to create a `Chat` with the `ChannelId`.
        let chat = try ChatClient.shared.makeChat(
          with: channelId,
          extraData: ["info": .string("Hello")]
        )

        /// 3: Call `Chat.get(watch:)` to create the channel.
        try await chat.get(watch: true)
    }

    func messages() {
        channelController.createNewMessage(
          text: "Hello",
          extraData: ["info": .string("secret message")]
        ) { result in
          switch result {
          case .success(let messageId):
            /// 2: Handle success
            print(messageId)
          case .failure(let error):
            /// 3: Handle errors
            print(error)
          }
        }
    }

    func messages2() async throws {
        let sentMessage = try await chat.sendMessage(
          with: "Hello",
          extraData: ["info": .string("secret message")]
        )
        suppressUnusedWarning(sentMessage)
    }

    func messages3() {
        //> import UIKit
        //> import StreamChat

        /// * Delegates *

        let viewController = ViewController()
        channelController.delegate = viewController
    }

    mutating func messages4() {
        // Observing message list changes using the state-layer
        chat.state.$messages
          .sink { messages in
            // updated array of `messages`
          }
          .store(in: &cancellables)
    }
}
