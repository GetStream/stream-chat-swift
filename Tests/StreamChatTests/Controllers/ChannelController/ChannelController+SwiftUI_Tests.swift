//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
import XCTest

@available(iOS 13, *)
class ChannelController_SwiftUI_Tests: iOS13TestCase {
    var channelController: ChannelControllerMock!
    
    override func setUp() {
        super.setUp()
        channelController = ChannelControllerMock()
    }
    
    override func tearDown() {
        AssertAsync.canBeReleased(&channelController)
        super.tearDown()
    }
    
    func test_controllerInitialValuesAreLoaded() {
        channelController.state_simulated = .localDataFetched
        channelController.channel_simulated = .mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: [:])
        channelController.messages_simulated = [.unique]
        
        let observableObject = channelController.observableObject
        
        XCTAssertEqual(observableObject.state, channelController.state)
        XCTAssertEqual(observableObject.channel, channelController.channel)
        XCTAssertEqual(observableObject.messages, channelController.messages)
    }
    
    func test_observableObject_reactsToDelegateChannelChangesCallback() {
        let observableObject = channelController.observableObject
        
        // Simulate channel change
        let newChannel: ChatChannel = .mock(cid: .unique, name: .unique, imageURL: .unique(), extraData: [:])
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
        
        AssertAsync.willBeEqual(Array(observableObject.messages), [newMessage])
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
    
    func test_observableObject_reactsToDelegateTypingUsersChangeCallback() {
        let observableObject = channelController.observableObject
        
        let typingUser = ChatUser(
            id: .unique,
            name: .unique,
            imageURL: .unique(),
            isOnline: true,
            isBanned: false,
            isFlaggedByCurrentUser: false,
            userRole: .user,
            createdAt: .unique,
            updatedAt: .unique,
            lastActiveAt: .unique,
            teams: [],
            extraData: [:]
        )
        
        // Simulate typing users change
        channelController.delegateCallback {
            $0.channelController(
                self.channelController,
                didChangeTypingUsers: [typingUser]
            )
        }
        
        AssertAsync.willBeEqual(observableObject.typingUsers, [typingUser])
    }
}

class ChannelControllerMock: ChatChannelController {
    @Atomic var synchronize_called = false
    
    var channel_simulated: ChatChannel?
    override var channel: ChatChannel? {
        channel_simulated
    }
    
    var messages_simulated: [ChatMessage]?
    override var messages: LazyCachedMapCollection<ChatMessage> {
        messages_simulated.map { $0.lazyCachedMap { $0 } } ?? super.messages
    }

    var state_simulated: DataController.State?
    override var state: DataController.State {
        get { state_simulated ?? super.state }
        set { super.state = newValue }
    }
    
    init(channelQuery: ChannelQuery = .init(channelPayload: .unique)) {
        super.init(
            channelQuery: channelQuery,
            channelListQuery: nil,
            client: .mock
        )
    }
    
    override func synchronize(_ completion: ((Error?) -> Void)? = nil) {
        synchronize_called = true
    }
}

extension ChatMessage {
    static var unique: ChatMessage {
        .init(
            id: .unique,
            cid: .unique,
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
            extraData: [:],
            quotedMessage: { nil },
            isSilent: false,
            isShadowed: false,
            reactionScores: ["like": 1],
            reactionCounts: ["like": 1],
            author: { .mock(id: .unique) },
            mentionedUsers: { [] },
            threadParticipants: { [] },
            attachments: { [] },
            latestReplies: { [] },
            localState: nil,
            isFlaggedByCurrentUser: false,
            latestReactions: { [] },
            currentUserReactions: { [] },
            isSentByCurrentUser: false,
            pinDetails: nil,
            translations: nil,
            underlyingContext: nil
        )
    }
}
