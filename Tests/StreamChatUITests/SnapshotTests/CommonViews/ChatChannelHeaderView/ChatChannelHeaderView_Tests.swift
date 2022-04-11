//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelHeaderView_Tests: XCTestCase {
    var sut: ChatChannelHeaderView!
    var mockChannelController: ChatChannelController_Mock!
    
    override func setUp() {
        super.setUp()
        
        let chatClient_mock = ChatClient_Mock.mock
        chatClient_mock.currentUserId_mock = "mock user id"
        mockChannelController = ChatChannelController_Mock.mock(client: chatClient_mock)
        sut = ChatChannelHeaderView().withoutAutoresizingMaskConstraints
        sut.backgroundColor = .darkGray
        sut.channelController = mockChannelController
    }
    
    override func tearDown() {
        sut = nil
        mockChannelController = nil
        
        super.tearDown()
    }
    
    func test_SettingNewChannelName_ChannelNameIsSuccessfullyChanged() {
        // GIVEN
        let newChannelName = "New Channel Name"
        let mockChannel: ChatChannel = .mockNonDMChannel(name: newChannelName)
        mockChannelController.channel_mock = mockChannel
        sut.setUpLayout()
        
        // WHEN
        sut.channelController(sut.channelController!, didUpdateChannel: .update(mockChannel))
        
        // THEN
        let currentChannelName = sut.titleContainerView.titleLabel.text ?? ""
        XCTAssertEqual(currentChannelName.isEmpty, false)
        XCTAssertEqual(newChannelName, currentChannelName)
    }
    
    func test_ChannelNameSet() {
        let newChannelName = "New Channel Name"
        
        mockChannelController.simulateInitial(
            channel: .mockNonDMChannel(name: newChannelName, watcherCount: 2, memberCount: 3),
            messages: [],
            state: .localDataFetched
        )
        
        AssertSnapshot(sut)
    }
}
