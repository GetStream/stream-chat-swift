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
    private var message: ChatMessageGroupPart!
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
        
        vc = TestChatMessagePopupVC()
        vc.messageContentViewClass = ChatMessageContentView.self
        vc.messageViewFrame = CGRect(x: 50, y: 300, width: 200, height: 50)
        
        let chatMessageController = ChatMessageController_Mock<NoExtraData>.mock()
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, text: "", author: ChatUser.mock(id: .unique)),
            replies: [],
            state: .remoteDataFetched
        )
        reactionsController = ChatMessageReactionsVC()
        reactionsController.messageController = chatMessageController
        vc.reactionsController = reactionsController
        actionsController = ChatMessageActionsVC()
        actionsController.messageController = chatMessageController
        vc.actionsController = actionsController

        message = ChatMessageGroupPart(
            message: .mock(
                id: .unique,
                text: "Message text",
                author: .mock(id: .unique)
            ),
            quotedMessage: .none,
            isFirstInGroup: false,
            isLastInGroup: false,
            didTapOnAttachment: { _ in },
            didTapOnAttachmentAction: { _, _ in }
        )
        vc.message = message
    }
    
    override func tearDown() {
        message = nil
        reactionsController = nil
        actionsController = nil
        vc = nil
        
        super.tearDown()
    }
    
    func test_defaultAppearance_when_largeLongMessage() {
        vc.messageViewFrame = CGRect(x: 50, y: 100, width: 200, height: 50)
        message = ChatMessageGroupPart(
            message: .mock(
                id: .unique,
                text: repeatElement("Message text", count: 8).joined(separator: "\n"),
                author: .mock(id: .unique)
            ),
            quotedMessage: .none,
            isFirstInGroup: false,
            isLastInGroup: false,
            didTapOnAttachment: { _ in },
            didTapOnAttachmentAction: { _, _ in }
        )
        vc.message = message
        AssertSnapshot(vc)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var config = Appearance()
        config.colorPalette.border = .cyan

        vc.appearance = config

        AssertSnapshot(vc)
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

        let vc = TestView()
        vc.actionsController = actionsController
        vc.messageContentViewClass = ChatMessageContentView.self
        vc.messageViewFrame = CGRect(x: 50, y: 300, width: 200, height: 50)
        vc.message = message

        AssertSnapshot(vc)
    }
}
