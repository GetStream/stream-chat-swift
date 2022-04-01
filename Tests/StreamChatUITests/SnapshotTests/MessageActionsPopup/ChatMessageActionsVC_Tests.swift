//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageActionsVC_Tests: XCTestCase {
    private var vc: ChatMessageActionsVC!
    private var chatMessageController: ChatMessageController_Mock!
    
    override func setUp() {
        super.setUp()

        chatMessageController = .mock()
        vc = ChatMessageActionsVC()
        vc.messageController = chatMessageController
        vc.channelConfig = .mock()

        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, cid: .unique, text: "", author: ChatUser.mock(id: .unique)),
            replies: [],
            state: .remoteDataFetched
        )
    }
    
    override func tearDown() {
        vc = nil
        chatMessageController = nil
        
        super.tearDown()
    }
    
    func test_emptyAppearance() {
        chatMessageController = .mock()
        vc.messageController = chatMessageController
        AssertSnapshot(vc)
    }

    func test_defaultAppearance() {
        AssertSnapshot(vc.embedded())
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.border = .cyan

        vc.appearance = appearance

        AssertSnapshot(vc.embedded())
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageActionsVC {
            override var messageActions: [ChatMessageActionItem] {
                super.messageActions.dropLast()
            }
        }

        let vc = TestView()
        vc.messageController = chatMessageController
        vc.channelConfig = .mock()
        AssertSnapshot(vc.embedded())
    }
    
    func test_usesCorrectComponentsTypes_whenCustomTypesDefined() {
        // Create new config to edit types...
        var components = vc.components

        class TestAlertsRouter: AlertsRouter {}
        components.alertsRouter = TestAlertsRouter.self
        vc.components = components

        XCTAssert(vc.alertsRouter is TestAlertsRouter)
    }

    func test_messageActions_whenMutesEnabled_containsMuteAction() {
        vc.channelConfig = .mock(mutesEnabled: true)

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is MuteUserActionItem }))
    }

    func test_messageActions_whenMutesDisabled_doesNotContainMuteAction() {
        vc.channelConfig = .mock(mutesEnabled: false)

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is MuteUserActionItem }))
    }
    
    func test_messageActions_whenQuotesEnabled_containsQuoteAction() {
        vc.channelConfig = .mock(quotesEnabled: true)

        XCTAssertTrue(vc.messageActions.contains(where: { $0 is InlineReplyActionItem }))
    }

    func test_messageActions_whenQuotesDisabled_doesNotContainQuoteAction() {
        vc.channelConfig = .mock(quotesEnabled: false)

        XCTAssertFalse(vc.messageActions.contains(where: { $0 is InlineReplyActionItem }))
    }
}

private extension UIViewController {
    /// `ChatMessageActionsVC` is not used as a root view controller, so we embed it to snapshot its more realistic size.
    func embedded() -> UIViewController {
        let viewController = UIViewController()
        viewController.addChildViewController(self, targetView: viewController.view)
        view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor)
        ])
        
        return viewController
    }
}
