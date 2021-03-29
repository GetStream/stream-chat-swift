//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

class ChatMessageComposerSendButton_Tests: XCTestCase {
    private lazy var container = UIView().withoutAutoresizingMaskConstraints

    override func setUp() {
        super.setUp()
        container.subviews.forEach { $0.removeFromSuperview() }
    }

    func test_defaultAppearance_newMessage() {
        let view = ChatMessageComposerSendButton().withoutAutoresizingMaskConstraints
        container.embed(view)

        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")

        view.mode = .edit
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-disabled")
    }

    func test_appearanceCustomization_usingUIConfig() {
        var config = UIConfig()
        config.images.messageComposerSendMessage = UIImage(
            named: "reaction_love_big",
            in: .streamChatUI
        )!
            .tinted(with: .systemPink)!
        config.colorPalette.inactiveTint = .black

        let view = ChatMessageComposerSendButton().withoutAutoresizingMaskConstraints
        view.uiConfig = config

        container.embed(view)

        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")

        view.mode = .edit
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-disabled")
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageComposerSendButton {}
        TestView.defaultAppearance {
            $0.tintColor = .green
        }

        let view = TestView().withoutAutoresizingMaskConstraints

        container.embed(view)

        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")

        view.mode = .edit
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-disabled")
    }

    func test_customizationUsingSubclassingHook() {
        class TestView: ChatMessageComposerSendButton {
            override func updateContent() {
                switch mode {
                case .new:
                    setTitle("🥪", for: .normal)
                    setTitle("🤷🏻‍♂️", for: .disabled)
                case .edit:
                    setTitle("🖌", for: .normal)
                    setTitle("🔏", for: .disabled)
                }
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints

        container.embed(view)
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "new-disabled")

        view.mode = .edit
        view.isEnabled = true
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-enabled")

        view.isEnabled = false
        AssertSnapshot(container, variants: .onlyUserInterfaceStyles, suffix: "edit-disabled")
    }
}
