//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamChat
@testable import StreamChatUI
import XCTest

final class TitleContainerView_Tests: XCTestCase {
    func test_defaultAppearance() {
        let view = TitleContainerView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        
        view.content = (nil, nil)
        AssertSnapshot(view, suffix: "empty")

        view.content = ("Title", "Subtitle")
        AssertSnapshot(view, suffix: "full")

        view.content = ("Title", nil)
        AssertSnapshot(view, suffix: "only title")
        
        view.content = (nil, "Subtitle")
        AssertSnapshot(view, suffix: "only subtitle")
    }
    
    func test_appearanceCustomization_usingAppearance() {
        var appearance = Appearance()
        appearance.fonts.headlineBold = .italicSystemFont(ofSize: 20)
        appearance.colorPalette.subtitleText = .cyan
        
        let view = TitleContainerView().withoutAutoresizingMaskConstraints
        view.appearance = appearance
        view.content = ("Red", "Blue")
        view.addSizeConstraints()
        
        AssertSnapshot(view)
    }
    
    func test_appearanceCustomization_usingSubclassing() {
        class CustomTitleView: TitleContainerView {
            lazy var customLabel = UILabel()
                .withoutAutoresizingMaskConstraints
            
            override func setUpAppearance() {
                customLabel.textColor = .red
            }
            
            override func setUpLayout() {
                addSubview(customLabel)
                customLabel.pin(to: self)
            }
            
            override func updateContent() {
                customLabel.text = content.title
            }
        }
        
        let view = CustomTitleView().withoutAutoresizingMaskConstraints
        view.content = ("Title", "Subtitle")
        view.addSizeConstraints()
        
        AssertSnapshot(view)
    }
}

@available(iOS 13, *)
final class TitleContainerView_Swift_Tests: iOS13TestCase {
    func test_swiftUIWrapper() {
        let view = TitleContainerView.asView((title: "Luke Skywalker", subtitle: "Last seen a long time ago..."))
        AssertSnapshot(view.frame(width: 320, height: 44))
    }
}

extension TitleContainerView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 320),
            heightAnchor.constraint(equalToConstant: 44)
        ])
    }
}
