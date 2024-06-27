//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class ChatThreadListItemView_Tests: XCTestCase {
    var mockThread: ChatThread!

    var mockYoda = ChatUser.mock(id: .unique, name: "Yoda", imageURL: .localYodaImage)
    var mockVader = ChatUser.mock(id: .unique, name: "Vader", imageURL: TestImages.vader.url)

    override func setUp() {
        super.setUp()

        mockThread = .mock(
            parentMessage: .mock(text: "Parent Message", author: mockYoda),
            channel: .mock(cid: .unique, name: "Star Wars Channel"),
            createdBy: mockVader,
            replyCount: 3,
            participantCount: 2,
            threadParticipants: [
                .mock(user: mockYoda),
                .mock(user: mockVader)
            ],
            lastMessageAt: .unique,
            createdAt: .unique,
            updatedAt: .unique,
            title: nil,
            latestReplies: [
                .mock(text: "First Message", author: mockYoda),
                .mock(text: "Second Message", author: mockVader),
                .mock(text: "Third Message", author: mockYoda)
            ],
            reads: [],
            extraData: [:]
        )
    }

    // MARK: - Appearance

    func test_defaultAppearance() {
        let view = threadItemView(
            content: .init(
                thread: mockThread,
                currentUserId: nil
            )
        )

        AssertSnapshot(view)
    }

    func test_defaultAppearance_withUnreads() {
        let currentUser = mockVader
        let thread = mockThread
            .with(reads: [.mock(user: currentUser, lastReadAt: .unique, unreadMessagesCount: 4)])

        let view = threadItemView(
            content: .init(
                thread: thread,
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view)
    }

    func test_defaultAppearance_withThreadTitle() {
        let currentUser = mockVader
        let thread = mockThread
            .with(title: "Thread Title")

        let view = threadItemView(
            content: .init(
                thread: thread,
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_defaultAppearance_withParentMessageDeleted() {
        let currentUser = mockVader
        let thread = mockThread
            .with(parentMessage: .mock(text: "Parent Message", deletedAt: .unique))

        let view = threadItemView(
            content: .init(
                thread: thread,
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_defaultAppearance_withLastReplyDeleted() {
        let currentUser = mockVader
        let thread = mockThread
            .with(latestReplies: [
                .mock(text: "First Message", author: mockYoda),
                .mock(text: "Second Message", author: mockVader),
                .mock(text: "Third Message", author: mockYoda, deletedAt: .unique)
            ])

        let view = threadItemView(
            content: .init(
                thread: thread,
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_defaultAppearance_whenAttachments() {
        let currentUser = mockVader
        let thread = mockThread
            .with(
                parentMessage: .mock(text: "", attachments: [.dummy(type: .giphy)]),
                latestReplies: [
                    .mock(text: "", author: mockYoda, attachments: [.dummy(type: .audio)])
                ]
            )

        let view = threadItemView(
            content: .init(
                thread: thread,
                currentUserId: currentUser.id
            )
        )

        AssertSnapshot(view, variants: [.defaultLight])
    }

    private func threadItemView(
        content: ChatThreadListItemView.Content?,
        components: Components = .mock,
        appearance: Appearance = .default
    ) -> ChatThreadListItemView {
        let view = ChatThreadListItemView().withoutAutoresizingMaskConstraints
        view.components = components
        view.appearance = appearance
        view.appearance.formatters.threadListMessageTimestamp = DefaultMessageTimestampFormatter()
        view.content = content
        view.addSizeConstraints()
        return view
    }
}

private extension ChatThreadListItemView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 400)
        ])
    }
}
