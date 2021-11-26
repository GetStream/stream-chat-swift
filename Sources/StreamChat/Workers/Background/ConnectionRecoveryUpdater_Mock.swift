//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

/// Mock implementation of `ConnectionRecoveryHandler`
final class ConnectionRecoveryHandlerMock: ConnectionRecoveryHandler {
    var registeredChannelLists: [ChatRecoverableComponent] = []
    var registeredChannels: [ChatRecoverableComponent] = []
    
    lazy var mock_registerChannel = MockFunc.mock(for: register(channel:))
    
    func register(channel: ChatRecoverableComponent) {
        mock_registerChannel.call(with: channel)
    }
    
    lazy var mock_registerChannelList = MockFunc.mock(for: register(channelList:))

    func register(channelList: ChatRecoverableComponent) {
        mock_registerChannelList.call(with: channelList)
    }
}
