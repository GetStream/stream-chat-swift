//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import CoreData
@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

@available(iOS 13, *)
final class MessageController_Combine_Tests: iOS13TestCase {
    var messageController: ChatMessageController_Mock!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        messageController = ChatMessageController_Mock.mock()
        cancellables = []
    }
    
    override func tearDown() {
        // Release existing subscriptions and make sure the controller gets released, too
        cancellables = nil
        AssertAsync.canBeReleased(&messageController)
        messageController = nil
        super.tearDown()
    }
    
    func test_statePublisher() {
        // Setup Recording publishers
        var recording = Record<DataController.State, Never>.Recording()
        
        // Setup the chain
        messageController
            .statePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatMessageController_Mock? = messageController
        messageController = nil
        
        controller?.delegateCallback { $0.controller(controller!, didChangeState: .remoteDataFetched) }
        
        AssertAsync.willBeEqual(recording.output, [.localDataFetched, .remoteDataFetched])
    }

    func test_messageChangePublisher() {
        // Setup Recording publishers
        var recording = Record<EntityChange<ChatMessage>, Never>.Recording()
        
        // Setup the chain
        messageController
            .messageChangePublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatMessageController_Mock? = messageController
        messageController = nil

        let newMessage: ChatMessage = .unique
        controller?.message_mock = newMessage
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeMessage: .create(newMessage))
        }
        
        XCTAssertEqual(recording.output, [.create(newMessage)])
    }
    
    func test_repliesChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ListChange<ChatMessage>], Never>.Recording()
        
        // Setup the chain
        messageController
            .repliesChangesPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)
        
        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatMessageController_Mock? = messageController
        messageController = nil

        let newReply: ChatMessage = .unique
        controller?.replies_mock = [newReply]
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeReplies: [.insert(newReply, index: .init())])
        }
        
        XCTAssertEqual(recording.output, [[.insert(newReply, index: .init())]])
    }

    func test_reactionsChangesPublisher() {
        // Setup Recording publishers
        var recording = Record<[ChatMessageReaction], Never>.Recording()

        // Setup the chain
        messageController
            .reactionsPublisher
            .sink(receiveValue: { recording.receive($0) })
            .store(in: &cancellables)

        // Keep only the weak reference to the controller. The existing publisher should keep it alive.
        weak var controller: ChatMessageController_Mock? = messageController
        messageController = nil

        let newReaction: ChatMessageReaction = .init(
            type: "like",
            score: 1,
            createdAt: .unique,
            updatedAt: .unique,
            author: .unique,
            extraData: [:]
        )
        controller?.reactions = []
        controller?.delegateCallback {
            $0.messageController(controller!, didChangeReactions: [newReaction])
        }

        XCTAssertEqual(recording.output, [[], [newReaction]])
    }
}
