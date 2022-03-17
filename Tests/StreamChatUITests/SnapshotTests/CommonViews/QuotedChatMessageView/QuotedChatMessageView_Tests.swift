//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

final class QuotedChatMessageView_Tests: XCTestCase {
    var view: QuotedChatMessageView!

    override func setUp() {
        super.setUp()
        view = QuotedChatMessageView().withoutAutoresizingMaskConstraints
        view.addSizeConstraints()
        view.components = .mock
        view.backgroundColor = .gray
    }

    override func tearDown() {
        super.tearDown()
        view = nil
    }

    func test_emptyAppearance() {
        view.content = makeContent(text: "")

        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_defaultAppearance() {
        view.content = makeContent(text: "Hello Vader!")

        AssertSnapshot(view)
    }

    func test_withImageAttachmentAppearance() {
        let attachment = ChatMessageImageAttachment.mock(
            id: .unique,
            imageURL: TestImages.yoda.url,
            title: ""
        )
        view.content = makeContent(text: "Hello Vader!", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view)

        view.content = makeContent(text: "", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view, suffix: "-emptyText")
    }

    func test_withFileAttachmentAppearance() {
        let attachment = ChatMessageFileAttachment.mock(
            id: .unique,
            title: "Data.csv",
            assetURL: .unique(),
            file: AttachmentFile(type: .csv, size: 0, mimeType: "text/csv"),
            localState: nil
        )

        view.content = makeContent(text: "Hello Vader!", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view)

        view.content = makeContent(text: "", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view, suffix: "-emptyText")
    }

    func test_withLinkAttachmentAppearance() {
        let attachment = ChatMessageLinkAttachment.mock(
            id: .unique,
            originalURL: URL(string: "https://www.yoda.com")!,
            assetURL: .unique(),
            previewURL: TestImages.yoda.url
        )

        view.content = makeContent(text: "Hello Vader!", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view)
    }

    func test_withGiphyAttachmentAppearance() {
        let attachment = ChatMessageGiphyAttachment(
            id: .unique,
            type: .giphy,
            payload: .init(title: "", previewURL: TestImages.yoda.url, actions: []),
            uploadingState: nil
        )

        view.content = makeContent(text: "Hello Vader!", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view)

        view.content = makeContent(text: "", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view, suffix: "-emptyText")
    }

    func test_withLongTextAppearance() {
        let attachment = ChatMessageImageAttachment.mock(
            id: .unique,
            imageURL: TestImages.yoda.url,
            title: ""
        )
        view.content = makeContent(text: "Hello Darth Vader! Where is my light saber?", attachments: [attachment.asAnyAttachment])

        AssertSnapshot(view)
    }

    func test_withAvatarAlignmentRightAppearance() {
        view.content = makeContent(text: "Hello Vader!", avatarAlignment: .trailing)

        AssertSnapshot(view)
    }

    func test_withAvatarAlignmentLeftAppearance() {
        view.content = makeContent(text: "Hello Vader!", avatarAlignment: .leading)

        AssertSnapshot(view)
    }

    func test_appearanceCustomization_usingComponents() {
        class TestView: ChatAvatarView {
            override func setUpAppearance() {
                super.setUpAppearance()

                imageView.layer.shadowColor = UIColor.black.cgColor
                imageView.layer.shadowOpacity = 1
                imageView.layer.shadowOffset = .zero
                imageView.layer.shadowRadius = 5
                imageView.clipsToBounds = false
            }
        }

        var components = Components()
        components.avatarView = TestView.self

        view.content = makeContent(text: "Hello Vader!")
        view.components = components

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: QuotedChatMessageView {
            override func setUpAppearance() {
                super.setUpAppearance()

                contentContainerView.layer.borderColor = UIColor.yellow.cgColor
                contentContainerView.backgroundColor = .lightGray
            }

            override func setUpLayout() {
                super.setUpLayout()

                containerView.alignment = .center

                attachmentPreviewView.widthAnchor.constraint(equalToConstant: 50).isActive = true
                attachmentPreviewView.heightAnchor.constraint(equalToConstant: 50).isActive = true
                attachmentPreviewView.layer.cornerRadius = 50 / 4

                authorAvatarView.widthAnchor.constraint(equalToConstant: 28).isActive = true
                authorAvatarView.heightAnchor.constraint(equalToConstant: 28).isActive = true
            }
        }

        let view = TestView().withoutAutoresizingMaskConstraints
        let attachment = ChatMessageImageAttachment.mock(
            id: .unique,
            imageURL: TestImages.yoda.url,
            title: ""
        )
        view.content = makeContent(text: "Hello Vader!", attachments: [attachment.asAnyAttachment])
        view.addSizeConstraints()
        view.components = .mock

        AssertSnapshot(view, variants: [.defaultLight])
    }

    @available(iOS 13.0, *)
    func test_wrappedInSwiftUI() {
        struct CustomView: View {
            @EnvironmentObject var components: Components.ObservableObject
            let content: QuotedChatMessageView.Content

            var body: some View {
                components.quotedMessageView.asView(content)
            }
        }
        
        // TODO: We have to replace default as the components are not injected in SwiftUI views.
        Components.default = .mock
        let view = CustomView(
            content: .init(
                message: .mock(
                    id: .unique,
                    cid: .unique,
                    text: "Hello world!",
                    author: .mock(id: .unique, imageURL: TestImages.yoda.url)
                ),
                avatarAlignment: .leading
            )
        )
        .environmentObject(Components.mock.asObservableObject)

        AssertSnapshot(view, variants: [.defaultLight])
    }
}

private extension QuotedChatMessageView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 360)
        ])
    }
}

// MARK: - Factory Helper

extension QuotedChatMessageView_Tests {
    func makeContent(
        text: String,
        isSentByCurrentUser: Bool = false,
        avatarAlignment: QuotedAvatarAlignment = .leading,
        attachments: [AnyChatMessageAttachment] = []
    ) -> QuotedChatMessageView.Content {
        let message = ChatMessage.mock(
            id: .unique,
            cid: .unique,
            text: text,
            author: .mock(id: .unique),
            attachments: attachments,
            isSentByCurrentUser: isSentByCurrentUser
        )
        return .init(message: message, avatarAlignment: avatarAlignment)
    }
}
