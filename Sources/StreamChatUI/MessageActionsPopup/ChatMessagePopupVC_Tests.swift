//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

extension _ChatMessagePopupVC: AppearanceProvider {}

final class ChatMessagePopupVC_Tests: XCTestCase {
    private var vc: ChatMessagePopupVC!
    private var message: ChatMessage!
    private var reactionsController: ChatMessageReactionsVC!
    private var actionsController: ChatMessageActionsVC!
    
    private class TestChatMessagePopupVC: ChatMessagePopupVC {
        // `actionsController` and `reactionsController` are visible only after animation
        // therefore we set them to be visible by default
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            
            blurView.alpha = 1
            
            reactionsController?.view.alpha = 1
            reactionsController?.view.transform = .identity

            actionsController.view.alpha = 1
            actionsController.view.transform = .identity
        }
    }
    
    override func setUp() {
        super.setUp()

        message = .mock(
            id: .unique,
            cid: .unique,
            text: "Message",
            author: .mock(id: .unique)
        )

        let messageContentView = ChatMessageContentView().withoutAutoresizingMaskConstraints
        messageContentView.setUpLayoutIfNeeded(
            options: message.layout(isLastInGroup: false),
            attachmentViewInjectorType: nil
        )
        messageContentView.content = message
        
        vc = TestChatMessagePopupVC()
        vc.messageBubbleViewInsets.right = 70
        vc.messageContentView = messageContentView
        vc.messageViewFrame = CGRect(x: 50, y: 300, width: 220, height: 200)
        vc.messageViewFrame.size = vc.messageContentView.systemLayoutSizeFitting(
            CGSize(width: vc.messageViewFrame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .streamRequire,
            verticalFittingPriority: .streamLow
        )

        messageContentView.translatesAutoresizingMaskIntoConstraints = false
        vc.messageContentContainerView.embed(messageContentView)
        
        let chatMessageController = ChatMessageController_Mock<NoExtraData>.mock()
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, cid: .unique, text: "", author: ChatUser.mock(id: .unique)),
            replies: [],
            state: .remoteDataFetched
        )
        reactionsController = ChatMessageReactionsVC()
        reactionsController.messageController = chatMessageController
        vc.reactionsController = reactionsController
        actionsController = ChatMessageActionsVC()
        actionsController.messageController = chatMessageController
        actionsController.channelConfig = .mock()
        vc.actionsController = actionsController
    }
    
    override func tearDown() {
        message = nil
        reactionsController = nil
        actionsController = nil
        vc = nil
        
        super.tearDown()
    }
    
    func test_defaultAppearance_when_largeLongMessage() {
        vc.messageContentView.content = .mock(
            id: .unique,
            cid: .unique,
            text: repeatElement("Message text", count: 8).joined(separator: "\n"),
            author: .mock(id: .unique)
        )
        vc.messageViewFrame.size = vc.messageContentView.systemLayoutSizeFitting(
            CGSize(width: vc.messageViewFrame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .streamRequire,
            verticalFittingPriority: .streamLow
        )
        AssertSnapshot(vc, variants: [.defaultDark, .defaultLight])
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var config = Appearance()
        config.colorPalette.border = .cyan

        vc.appearance = config

        AssertSnapshot(vc, variants: [.defaultDark, .defaultLight])
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: TestChatMessagePopupVC {
            override var blurView: UIView {
                let view = UIView()
                view.backgroundColor = .cyan
                return view
                    .withoutAutoresizingMaskConstraints
            }
        }

        let messageContentView = ChatMessageContentView().withoutAutoresizingMaskConstraints
        messageContentView.setUpLayoutIfNeeded(
            options: message.layout(isLastInGroup: false),
            attachmentViewInjectorType: nil
        )
        messageContentView.content = message

        let vc = TestView()
        vc.actionsController = actionsController
        vc.messageContentView = messageContentView
        vc.messageViewFrame = CGRect(x: 50, y: 300, width: 220, height: 50)
        vc.messageViewFrame.size = vc.messageContentView.systemLayoutSizeFitting(
            CGSize(width: vc.messageViewFrame.width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .streamRequire,
            verticalFittingPriority: .streamLow
        )
        messageContentView.translatesAutoresizingMaskIntoConstraints = false
        vc.messageContentContainerView.embed(messageContentView)

        AssertSnapshot(vc, variants: [.defaultDark, .defaultLight])
    }
}
