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
        let newChannel: ChatChannel = .init(cid: .unique, extraData: .defaultValue)
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
        let newMessage: ChatMessage = .unique
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
        let newState: DataController.State = .remoteDataFetchFailed(ClientError(with: TestError()))
        channelController.state_simulated = newState
        channelController.delegateCallback {
            $0.controller(
                self.channelController,
                didChangeState: newState
            )
        }
        
        AssertAsync.willBeEqual(observableObject.state, newState)
    }
    
    func test_observableObject_reactsToDelegateTypingMembersChangeCallback() {
        let observableObject = channelController.observableObject
        
        let typingMember = ChatChannelMember(
            id: .unique,
            isOnline: true,
            isBanned: false,
            userRole: .user,
            userCreatedAt: .unique,
            userUpdatedAt: .unique,
            lastActiveAt: .unique,
            extraData: .defaultValue,
            memberRole: .member,
            memberCreatedAt: .unique,
            memberUpdatedAt: .unique,
            isInvited: false,
            inviteAcceptedAt: nil,
            inviteRejectedAt: nil
        )
        
        // Simulate typing members change
        channelController.delegateCallback {
            $0.channelController(
                self.channelController,
                didChangeTypingMembers: [typingMember]
            )
        }
        
        AssertAsync.willBeEqual(observableObject.typingMembers, [typingMember])
    }
}

class ChannelControllerMock: ChatChannelController {
    @Atomic var synchronize_called = false
    
    var channel_simulated: _ChatChannel<DefaultExtraData>?
    override var channel: _ChatChannel<DefaultExtraData>? {
        channel_simulated
    }
    
    var messages_simulated: [_ChatMessage<DefaultExtraData>]?
    override var messages: [_ChatMessage<DefaultExtraData>] {
        messages_simulated ?? super.messages
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init() {
        super.init(channelQuery: .init(channelPayload: .unique), client: .mock)
    }
    
    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}

extension _ChatMessage {
    static var unique: ChatMessage {
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
