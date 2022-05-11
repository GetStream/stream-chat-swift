//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
#if TESTS
@testable import StreamChat
import OHHTTPStubs
#else
import StreamChat
#endif
import StreamChatUI
import UIKit

final class StreamChatWrapper {

    static let shared = StreamChatWrapper()

    var userCredentials: UserCredentials?

    func setupChatClient(with userCredentials: UserCredentials) {
        self.userCredentials = userCredentials

        var config = ChatClientConfig(apiKey: .init(apiKey))
        config.isLocalStorageEnabled = false

        // Customization
        var components = Components.default
        components.channelListRouter = CustomChannelListRouter.self
        components.messageListRouter = CustomMessageListRouter.self
        components.channelVC = ChannelVC.self
        components.threadVC = ThreadVC.self
        Components.default = components

        // create an instance of ChatClient and share it using the singleton
        let environment = ChatClient.Environment()
        ChatClient.shared = ChatClient(config: config, environment: environment)

        // connect to chat
        ChatClient.shared.connectUser(
            userInfo: UserInfo(
                id: userCredentials.id,
                name: userCredentials.name,
                imageURL: userCredentials.avatarURL
            ),
            token: userCredentials.token
        )
    }

    func makeChannelListViewController() -> ChannelList {
        // UI
        let query = ChannelListQuery(filter: .containMembers(userIds: [userCredentials?.id ?? ""]))
        let controller = ChatClient.shared.channelListController(query: query)
        let channelList = ChannelList.make(with: controller)
        return channelList
    }

}

extension StreamChatWrapper {

    func mockConnection(isConnected: Bool) {
        #if TESTS
        let client = ChatClient.shared

        if isConnected == false {
            // Stub all HTTP requests with No internet connection error
            HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                let baseURL = ChatClient.shared.config.baseURL.restAPIBaseURL.absoluteString
                return request.url?.absoluteString.contains(baseURL) ?? false
            }, withStubResponse: { _ -> HTTPStubsResponse in
                let error = NSError(domain: "NSURLErrorDomain",
                                    code: -1009,
                                    userInfo: nil)
                return HTTPStubsResponse(error: error)
            })

            // Swap monitor with the mocked one
            let monitor = InternetConnectionMonitor_Mock()
            var environment = ChatClient.Environment()
            environment.monitor = monitor
            client?.setupConnectionRecoveryHandler(with: environment)

            // Update monitor with mocked status
            monitor.update(with: .unavailable)

            // Disconnect from websockets
            client?.webSocketClient?.disconnect(source: .systemInitiated)

        } else {
            HTTPStubs.removeAllStubs()
            client?.setupConnectionRecoveryHandler(with: ChatClient.Environment())
            client?.webSocketClient?.connect()
        }
        #endif
    }
}
