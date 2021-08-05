//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelListErrorView_Tests: XCTestCase {
    func test_defaultAppearance() {
        let view = ChatChannelListErrorView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.bodyBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .blue
        appearance.colorPalette.text = .green
        appearance.colorPalette.background2 = .magenta
        
        let view = ChatChannelListErrorView().withoutAutoresizingMaskConstraints
        view.appearance = appearance
        view.addSizeConstraints()
        
        AssertSnapshot(view)
    }
        
    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelListErrorView {
            override func setUpAppearance() {
                super.setUpAppearance()
                titleLabel.textColor = .orange
                backgroundColor = .brown
            }

            override func setUpLayout() {
                super.setUpLayout()
                retryButton.removeFromSuperview()
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        AssertSnapshot(view)
    }
}

private extension ChatChannelListErrorView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400),
            heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
