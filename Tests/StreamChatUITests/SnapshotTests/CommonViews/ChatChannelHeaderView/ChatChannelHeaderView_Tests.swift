//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelHeaderView_Tests: XCTestCase {
    var view: ChatChannelHeaderView!
    var mockChannelController: ChatChannelController_Mock!
    
    override func setUp() {
        super.setUp()
        
        mockChannelController = ChatChannelController_Mock.mock()
        view = ChatChannelHeaderView().withoutAutoresizingMaskConstraints
        view.backgroundColor = .gray
        view.addSizeConstraints()
        view.channelController = mockChannelController
    }
    
    override func tearDown() {
        view = nil
        mockChannelController = nil
        
        super.tearDown()
    }
    
    func test_SetNewChannelName_IsSuccessfullyChanged() {
        // Given
        let newChannelName = "New Channel Name"
        let mockChannel: ChatChannel = .mockDMChannel(name: newChannelName)
        mockChannelController.channel_mock = mockChannel
        
        // When
        view.channelController(view.channelController!, didUpdateChannel: .update(mockChannel))
        
        // Then
        let currentChannelName = view.titleContainerView.titleLabel.text ?? ""
        XCTAssertEqual(currentChannelName.isEmpty, false)
        XCTAssertEqual(newChannelName, currentChannelName)
    }
    
    func test_ChannelNameSet() {
        let newChannelName = "New Channel Name"
        mockChannelController.simulateInitial(
            channel: .mockDMChannel(name: newChannelName),
            messages: [],
            state: .localDataFetched
        )
        
        AssertSnapshot(view)
    }
}

private extension ChatChannelHeaderView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 360),
            heightAnchor.constraint(equalToConstant: 360)
        ])
    }
}
