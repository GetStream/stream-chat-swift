//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatChannelUnreadCountView_Tests: XCTestCase {
    func test_emptyAppearance() {
        let view = ChatChannelUnreadCountView().withoutAutoresizingMaskConstraints
        AssertSnapshot(view)
    }
    
    func test_defaultAppearance() {
        let view = ChatChannelUnreadCountView().withoutAutoresizingMaskConstraints
        
        view.content = .mock(messages: 10)
        AssertSnapshot(view, suffix: "2digits")
        
        view.content = .mock(messages: 100)
        AssertSnapshot(view, suffix: "3digits")
    }

    func test_appearanceCustomization_usingComponents() {
        var appearance = Appearance()
        appearance.colorPalette.alert = .green

        let view = ChatChannelUnreadCountView().withoutAutoresizingMaskConstraints
        view.appearance = appearance

        view.content = .mock(messages: 10)
        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelUnreadCountView {
            override func setUpAppearance() {
                super.setUpAppearance()
                backgroundColor = .blue
            }

            override func setUpLayout() {
                super.setUpLayout()
                NSLayoutConstraint.activate([
                    heightAnchor.constraint(equalToConstant: 50),
                    widthAnchor.constraint(equalToConstant: 50)
                ])
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.content = .mock(messages: 1000)
        AssertSnapshot(view)
    }
}
