//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatMessageComposerImageAttachmentsView_Tests: XCTestCase {
    var view: ChatMessageComposerImageAttachmentsView!

    override func setUp() {
        super.setUp()
        view = makeView(ChatMessageComposerImageAttachmentsView.self)
    }

    override func tearDown() {
        super.tearDown()
        view = nil
    }

    func test_defaultAppearance() {
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingUIConfig() {
        class TestView: ChatMessageComposerImageAttachmentView {
            override func setUpAppearance() {
                super.setUpAppearance()

                contentView.layer.addShadow(color: .black, radius: 4)
                layer.masksToBounds = false
            }

            override func setUpLayout() {
                super.setUpLayout()
                layout.discardButtonConstraints.forEach { $0.isActive = false }

                discardButton.topAnchor.constraint(equalTo: imageView.layoutMarginsGuide.topAnchor).isActive = true
                discardButton.leadingAnchor.constraint(equalTo: imageView.layoutMarginsGuide.leadingAnchor).isActive = true
            }
        }

        var config = UIConfig()
        config.messageComposer.imageAttachmentCellView = TestView.self

        let view = makeView(ChatMessageComposerImageAttachmentsView.self)
        view.collectionView.layer.masksToBounds = false
        view.uiConfig = config
        view.backgroundColor = .yellow
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingAppearanceHook() {
        class TestView: ChatMessageComposerImageAttachmentsView {}
        TestView.defaultAppearance {
            $0.backgroundColor = .yellow
        }

        let view = makeView(TestView.self)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageComposerImageAttachmentsView {
            override func setUpAppearance() {
                super.setUpAppearance()

                backgroundColor = .yellow
            }

            override func setUpLayout() {
                super.setUpLayout()

                flowLayout.itemSize = CGSize(width: 70, height: 70)
                collectionView.heightAnchor.constraint(equalToConstant: 70).isActive = true
            }
        }

        let view = makeView(TestView.self)
        AssertSnapshot(view, variants: [.defaultLight])
    }
}

private extension ChatMessageComposerImageAttachmentsView_Tests {
    func makeView(_ view: ChatMessageComposerImageAttachmentsView.Type) -> ChatMessageComposerImageAttachmentsView {
        let view = view.init().withoutAutoresizingMaskConstraints
        view.content = [
            TestImages.yoda.image,
            TestImages.vader.image,
            TestImages.chewbacca.image,
            TestImages.r2.image
        ]
        view.addSizeConstraints()
        return view
    }
}

private extension ChatMessageComposerImageAttachmentsView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 360)
        ])
    }
}
