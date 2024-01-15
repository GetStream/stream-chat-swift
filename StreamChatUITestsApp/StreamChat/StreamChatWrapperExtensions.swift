//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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

extension StreamChatWrapper {

    func mockConnection(isConnected: Bool) {
        #if TESTS
        let client = StreamChatWrapper.shared.client

        if isConnected == false {
            // Stub all HTTP requests with No internet connection error
            HTTPStubs.stubRequests(passingTest: { (request) -> Bool in
                let baseURL = StreamChatWrapper.shared.config.baseURL.restAPIBaseURL.absoluteString
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
            client?.webSocketClient?.disconnect(source: .systemInitiated) {}

        } else {
            HTTPStubs.removeAllStubs()
            client?.setupConnectionRecoveryHandler(with: ChatClient.Environment())
            client?.webSocketClient?.connect()
        }
        #endif
    }

    func makeChannelListViewController() -> ChannelList {
        // UI
        let query = ChannelListQuery(filter: .containMembers(userIds: [UserCredentials.default.id]))
        let controller = client!.channelListController(query: query)
        let channelList = ChannelList.make(with: controller)
        return channelList
    }

}
