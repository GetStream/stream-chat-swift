//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Atlantis
import StreamChat
import StreamChatUI
import UIKit

enum CaseToCover: CaseIterable {
    case slowTokenProvider
    case showingChannelListWithoutWaitingForConnection
    case delayedConnect

    var title: String {
        switch self {
        case .slowTokenProvider:
            return "Slow token fetch"
        case .showingChannelListWithoutWaitingForConnection:
            return "Show channel list immediately"
        case .delayedConnect:
            return "Delayed connection"
        }
    }

    var subtitle: String {
        switch self {
        case .slowTokenProvider:
            return "Takes 11s to fetch the token to check behaviour against timeouts on token waiter"
        case .showingChannelListWithoutWaitingForConnection:
            return "Shows the channel list without waiting for a successful WS connection"
        case .delayedConnect:
            return "Delays the connection execution by 2s"
        }
    }
}

class EdgeCasesCoordinator {
    let chatClient: ChatClient
    var currentUser = UserCredentials.hanSolo
    var cases: [CaseToCover] = [.showingChannelListWithoutWaitingForConnection, .delayedConnect, .slowTokenProvider]

    init() {
        let config = ChatClientConfig(apiKeyString: apiKeyString)
        chatClient = ChatClient(config: config)
    }

    func start(with window: UIWindow) {
        Atlantis.start()
        configureStream()

        let cases = self.cases
        let showChannelList = { [weak self] in
            self?.showChannelList(on: window)
        }

        let connect = { [weak self] in
            self?.connect { error in
                if let error = error {
                    print(error)
                } else if !cases.contains(.showingChannelListWithoutWaitingForConnection) {
                    DispatchQueue.main.async {
                        showChannelList()
                    }
                }
            }
        }

        if cases.contains(.delayedConnect) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                connect()
            }
        } else {
            connect()
        }

        if cases.contains(.showingChannelListWithoutWaitingForConnection) {
            showChannelList()
        }

        window.makeKeyAndVisible()
    }

    private func configureStream() {
        StreamRuntimeCheck.assertionsEnabled = true
    }

    private func connect(completion: @escaping (Error?) -> Void) {
        let cases = self.cases
        let userInfo = UserInfo(
            id: currentUser.userInfo.id,
            name: currentUser.userInfo.name,
            imageURL: currentUser.userInfo.imageURL,
            isInvisible: false,
            extraData: currentUser.userInfo.extraData
        )

        var token = currentUser.token

        let tokenProvider: TokenProvider = { completion in
            if cases.contains(.slowTokenProvider) {
                // Waiters timeout is 10s
                DispatchQueue.main.asyncAfter(deadline: .now() + 11) {
                    completion(.success(token))
                }
            } else {
                completion(.success(token))
            }
        }

        chatClient.connectUser(userInfo: userInfo, tokenProvider: tokenProvider) { error in
            print("🐞 Connect result: \(error == nil ? "Success" : error!.localizedDescription)")
            completion(error)
        }
    }

    private func showChannelList(on window: UIWindow) {
        let query = ChannelListQuery(filter: .containMembers(userIds: [currentUser.id]))
        let controller = chatClient.channelListController(query: query)
        let viewController = EdgeCasesChannelList.make(with: controller)
        viewController.coordinator = self
        window.rootViewController = UINavigationController(rootViewController: viewController)
    }

    // Connects with another user without logging out beforehand
    func logInWithAnotherUser(completion: ((Error?) -> Void)? = nil) {
        currentUser = currentUser.userInfo.id == UserCredentials.hanSolo.id ? .leia : .hanSolo
        connect {
            completion?($0)
        }
    }

    // Connects with same user without logging out beforehand
    func logInWithSameUser(completion: ((Error?) -> Void)? = nil) {
        connect {
            completion?($0)
        }
    }

    // Connects with another user after logging out
    func logInLogOutDance(completion: ((Error?) -> Void)? = nil) {
        chatClient.logout { [weak self] in
            self?.logInWithAnotherUser(completion: completion)
        }
    }
}
