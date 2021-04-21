//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageActionsVC_Tests: XCTestCase {
    private var vc: ChatMessageActionsVC!
    private var chatMessageController: ChatMessageController_Mock<NoExtraData>!
    
    override func setUp() {
        super.setUp()
        
        vc = ChatMessageActionsVC()
        chatMessageController = .mock()
        vc.messageController = chatMessageController
        
        chatMessageController.simulateInitial(
            message: ChatMessage.mock(id: .unique, text: "", author: ChatUser.mock(id: .unique)),
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
    
    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.colorPalette.border = .cyan

        vc.uiConfig = config

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
        AssertSnapshot(vc.embedded())
    }
    
    func test_usesCorrectUIConfigTypes_whenCustomTypesDefined() {
        // Create new config to edit types...
        var customConfig = vc.uiConfig

        class TestChatMessageActionsRouter: ChatMessageActionsRouter {}

        customConfig.navigation.messageActionsRouter = TestChatMessageActionsRouter.self

        vc.uiConfig = customConfig

        XCTAssert(vc.router is TestChatMessageActionsRouter)
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
