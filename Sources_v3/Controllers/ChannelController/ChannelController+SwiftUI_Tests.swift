//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

@testable import StreamChatClient
import XCTest

@available(iOS 13, *)
class ChannelController_SwiftUI_Tests: iOS13TestCase {
    var channelController: ChannelControllerMock!
    
    override func setUp() {
        super.setUp()
        channelController = ChannelControllerMock()
    }
    
    func test_startUpdatingIsCalled_whenObservableObjectCreated() {
        assert(channelController.startUpdating_called == false)
        _ = channelController.observableObject
        XCTAssertTrue(channelController.startUpdating_called)
    }
    
    func test_controllerInitialValuesAreLoaded() {
        channelController.state_simulated = .localDataFetched
        channelController.channel_simulated = .init(cid: .unique, extraData: .defaultValue)
        channelController.messages_simulated = [.unique]
        
        let observableObject = channelController.observableObject
        
        XCTAssertEqual(observableObject.state, channelController.state)
        XCTAssertEqual(observableObject.channel, channelController.channel)
        XCTAssertEqual(observableObject.messages, channelController.messages)
    }
    
    func test_observableObject_reactsToDelegateChannelChangesCallback() {
        let observableObject = channelController.observableObject
        
        // Simulate channel change
        let newChannel: Channel = .init(cid: .unique, extraData: .defaultValue)
        channelController.channel_simulated = newChannel
        channelController.delegateCallback {
            $0.channelController(
                self.channelController,
                didUpdateChannel: .create(newChannel)
            )
        }
                    
        AssertAsync.willBeEqual(observableObject.channel, newChannel)
    }
    
    func test_observableObject_reactsToDelegateMessagesChangesCallback() {
        let observableObject = channelController.observableObject
        
        // Simulate messages change
        let newMessage: Message = .unique
        channelController.messages_simulated = [newMessage]
        channelController.delegateCallback {
            $0.channelController(
                self.channelController,
                didUpdateMessages: [.insert(newMessage, index: .init())]
            )
        }
        
        AssertAsync.willBeEqual(observableObject.messages, [newMessage])
    }
    
    func test_observableObject_reactsToDelegateStateChangesCallback() {
        let observableObject = channelController.observableObject
        
        // Simulate state change
        let newState: Controller.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        channelController.state_simulated = newState
        channelController.delegateCallback {
            $0.controller(
                self.channelController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
}

class ChannelControllerMock: ChannelController {
    @Atomic var startUpdating_called = false
    
    var channel_simulated: ChannelModel<DefaultDataTypes>?
    override var channel: ChannelModel<DefaultDataTypes>? {
        channel_simulated
    }
    
    var messages_simulated: [MessageModel<DefaultDataTypes>]?
    override var messages: [MessageModel<DefaultDataTypes>] {
        messages_simulated ?? super.messages
    }

    var state_simulated: Controller.State?
    override var state: Controller.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(channelQuery: .init(channelPayload: .unique), client: .mock)
    }
    
    override func startUpdating(_ completion: ((Error?) -> Void)? = nil) {
        startUpdating_called = true
    }
}

extension MessageModel {
    static var unique: Message {
        .init(
            id: .unique,
            text: "",
            type: .regular,
            command: nil,
            createdAt: Date(),
            locallyCreatedAt: nil,
            updatedAt: Date(),
            deletedAt: nil,
            arguments: nil,
            parentMessageId: nil,
            showReplyInChannel: true,
            replyCount: 2,
            extraData: .init(),
            isSilent: false,
            reactionScores: ["": 1],
            author: .init(id: .unique),
            mentionedUsers: [],
            localState: nil
        )
    }
}
