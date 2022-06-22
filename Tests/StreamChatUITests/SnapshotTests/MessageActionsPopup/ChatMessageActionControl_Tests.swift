//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageActionControl_Tests: XCTestCase {
    struct TestChatMessageActionItem: ChatMessageActionItem {
        let title: String
        let icon: UIImage
        let isDestructive: Bool
        let isPrimary: Bool
        let action: (ChatMessageActionItem) -> Void = { _ in }
        
        init(
            title: String,
            icon: UIImage,
            isDestructive: Bool = false,
            isPrimary: Bool = false
        ) {
            self.title = title
            self.icon = icon
            self.isDestructive = isDestructive
            self.isPrimary = isPrimary
        }
    }
    
    private var content: TestChatMessageActionItem!
    
    override func setUp() {
        super.setUp()
        
        content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!
        )
    }
    
    override func tearDown() {
        content = nil
        
        super.tearDown()
    }

    func test_emptyState() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 50)
        ])
        view.content = content
        view.content = TestChatMessageActionItem(title: "", icon: UIImage())
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = content
        AssertSnapshot(view)
    }

    func test_defaultMultilineAppearance() {
        content = TestChatMessageActionItem(
            title: "Action that takes\n 2 lines of text",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!
        )
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = content
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance_whenHighlighted() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = content
        view.isHighlighted = true
        
        // Simulate background.
        let backgroundView = UIView()
            .withoutAutoresizingMaskConstraints
        backgroundView.backgroundColor = view.appearance.colorPalette.background
        backgroundView.embed(view)
        
        AssertSnapshot(backgroundView)
    }

    func test_defaultAppearance_whenDestructive() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isDestructive: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance_whenPrimary() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isPrimary: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance_whenPrimaryAndDestructive() {
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = TestChatMessageActionItem(
            title: "Action 1",
            icon: UIImage(named: "icn_inline_reply", in: .streamChatUI)!,
            isDestructive: true,
            isPrimary: true
        )
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.colorPalette.text = .blue
        
        let view = ChatMessageActionControl().withoutAutoresizingMaskConstraints
        view.content = content
        view.appearance = appearance
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageActionControl {
            override func setUpAppearance() {
                super.setUpAppearance()
                backgroundColor = .cyan
            }
            
            override func updateContent() {
                super.updateContent()
                
                titleLabel.textColor = .red
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints

        view.content = content
        AssertSnapshot(view)
    }
}
