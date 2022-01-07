//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class TypingIndicatorViewTests: XCTestCase {
    override func setUp() {
        super.setUp()
        // Disable animations.
        UIView.setAnimationsEnabled(false)
    }
    
    func test_defaultAppearance() {
        let view = TypingIndicatorView().withoutAutoresizingMaskConstraints
        view.content = "Luke Skywalker is typing"
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
  
        appearance.colorPalette.overlayBackground = .brown
        appearance.fonts.body = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .green
      
        let view = TypingIndicatorView().withoutAutoresizingMaskConstraints
        view.appearance = appearance
        view.content = "Luke Skywalker is typing"

        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class CustomTitleView: TypingIndicatorView {
            lazy var customLabel = UILabel()
                .withoutAutoresizingMaskConstraints

            override func setUpAppearance() {
                // Not call super on purpose
                customLabel.textColor = .red
            }

            override func setUpLayout() {
                super.setUpLayout()
                componentContainerView.addArrangedSubview(customLabel)
            }

            override func updateContent() {
                super.updateContent()
                customLabel.text = " + 4 people online"
            }
        }

        let view = CustomTitleView().withoutAutoresizingMaskConstraints
        view.content = "Luke Skywalker is typing"

        AssertSnapshot(view)
    }
}
