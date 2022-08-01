//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatChannelListEmptyView_Tests: XCTestCase {
    var vc: UIViewController!

    override func setUp() {
        super.setUp()
        vc = UIViewController()
    }

    func test_defaultAppearance() {
        let view = ChatChannelListEmptyView().withoutAutoresizingMaskConstraints
        vc.view.embed(view)
        AssertSnapshot(vc)
    }

    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.bodyBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .cyan
        appearance.colorPalette.text = .green
        appearance.colorPalette.background2 = .magenta

        let view = ChatChannelListEmptyView().withoutAutoresizingMaskConstraints
        view.appearance = appearance

        vc.view.embed(view)

        AssertSnapshot(vc)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatChannelListEmptyView {
            override func setUpAppearance() {
                super.setUpAppearance()
                titleLabel.textColor = .orange
                subtitleLabel.textColor = .blue
                backgroundColor = .brown
            }

            override func setUpLayout() {
                super.setUpLayout()
                iconView.removeFromSuperview()
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        vc.view.embed(view)

        AssertSnapshot(vc)
    }
}
