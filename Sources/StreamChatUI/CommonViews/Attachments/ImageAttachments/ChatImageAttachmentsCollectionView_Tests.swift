//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import XCTest

class ChatImageAttachmentsCollectionView_Tests: XCTestCase {
    var view: ChatImageAttachmentsCollectionView!

    override func setUp() {
        super.setUp()
        view = makeView(ChatImageAttachmentsCollectionView.self)
    }

    override func tearDown() {
        super.tearDown()
        view = nil
    }

    func test_defaultAppearance() {
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_appearanceCustomization_usingComponents() {
        class TestView: ChatImageAttachmentView {
            override func setUpAppearance() {
                super.setUpAppearance()

                layer.addShadow(color: .black, radius: 4)
                layer.masksToBounds = false
            }

            override func setUpLayout() {
                super.setUpLayout()

                discardButton.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor).isActive = true
            }
        }

        var components = Components()
        components.messageComposer.imageAttachmentCellView = TestView.self

        let view = makeView(ChatImageAttachmentsCollectionView.self)
        view.collectionView.layer.masksToBounds = false
        view.components = components
        view.backgroundColor = .yellow
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatImageAttachmentsCollectionView {
            override func setUpAppearance() {
                super.setUpAppearance()

                backgroundColor = .yellow
            }

            override func setUpLayout() {
                super.setUpLayout()

                flowLayout.itemSize = CGSize(width: 70, height: 70)
            }
        }

        let view = makeView(TestView.self)
        AssertSnapshot(view, variants: [.defaultLight])
    }
}

private extension ChatImageAttachmentsCollectionView_Tests {
    func makeView(_ view: ChatImageAttachmentsCollectionView.Type) -> ChatImageAttachmentsCollectionView {
        let view = view.init().withoutAutoresizingMaskConstraints
        view.content = [
            TestImages.yoda.image,
            TestImages.vader.image,
            TestImages.chewbacca.image,
            TestImages.r2.image
        ].map {
            ImageAttachmentPreview(image: $0, localURL: URL(string: "fake")!)
        }
        view.addSizeConstraints()
        return view
    }
}

private extension ChatImageAttachmentsCollectionView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 360),
            heightAnchor.constraint(equalToConstant: 120)
        ])
    }
}
