//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class PollAttachmentView_Tests: XCTestCase {
    /// Static setUp() is only run once. Which is what we want in this case to preload the images.
    override class func setUp() {
        /// Dummy snapshot to preload the TestImages.yoda.url image
        /// This was the only workaround to make sure the image always appears in the snapshots.
        let view = UIImageView(frame: .init(center: .zero, size: .init(width: 100, height: 100)))
        Components.default.imageLoader.loadImage(into: view, from: TestImages.yoda.url)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    let currentUser = ChatUser.mock(
        id: .unique,
        imageURL: TestImages.yoda.url
    )

    func test_appearance() {
        let poll = makePoll(isClosed: false)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view)
    }

    func test_appearance_whenClosed() {
        let poll = makePoll(isClosed: true)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight, .defaultDark])
    }

    func test_subtitleText() {
        let pollAttachmentView = PollAttachmentView()
        let pollDefault = makePoll(isClosed: false)
        let pollClosed = makePoll(isClosed: true)
        let pollUniqueVotes = makePoll(isClosed: false, enforceUniqueVote: true)
        let pollMaxVotesAllowed = makePoll(isClosed: false, maxVotesAllowed: 3)

        pollAttachmentView.content = .init(poll: pollDefault, currentUserId: .unique)
        XCTAssertEqual(pollAttachmentView.subtitleText, "Select one or more")

        pollAttachmentView.content = .init(poll: pollClosed, currentUserId: .unique)
        XCTAssertEqual(pollAttachmentView.subtitleText, "Vote ended")

        pollAttachmentView.content = .init(poll: pollUniqueVotes, currentUserId: .unique)
        XCTAssertEqual(pollAttachmentView.subtitleText, "Select one")

        pollAttachmentView.content = .init(poll: pollMaxVotesAllowed, currentUserId: .unique)
        XCTAssertEqual(pollAttachmentView.subtitleText, "Select up to 3")
    }
}

// MARK: - Factory Helpers

extension PollAttachmentView_Tests {
    private func makePoll(
        isClosed: Bool,
        enforceUniqueVote: Bool = false,
        maxVotesAllowed: Int? = nil,
        createdBy: ChatUser? = nil
    ) -> Poll {
        Poll.mock(
            enforceUniqueVote: enforceUniqueVote,
            name: "Best football player",
            voteCount: 6,
            voteCountsByOption: [
                "ronaldo": 3,
                "eusebio": 2,
                "pele": 1,
                "maradona": 0,
                "messi": 0
            ],
            isClosed: isClosed,
            maxVotesAllowed: maxVotesAllowed,
            createdBy: createdBy ?? currentUser,
            options: [
                .init(id: "messi", text: "Messi"),
                .init(id: "ronaldo", text: "Ronaldo", latestVotes: [
                    .mock(user: currentUser),
                    .mock(user: .mock(id: .unique)),
                    .mock(user: .mock(id: .unique))
                ]),
                .init(id: "pele", text: "Pele", latestVotes: [
                    .mock(user: .mock(id: .unique))
                ]),
                .init(id: "maradona", text: "Maradona"),
                .init(id: "eusebio", text: "Eusebio", latestVotes: [
                    .mock(user: currentUser),
                    .mock(user: .mock(id: .unique))
                ])
            ],
            ownVotes: [
                .mock(optionId: "ronaldo"),
                .mock(optionId: "eusebio")
            ]
        )
    }

    private func makeMessageView(
        for poll: Poll,
        appearance: Appearance = .default,
        components: Components = .default
    ) -> ChatMessageContentView {
        let channel = ChatChannel.mock(cid: .unique)
        let message = ChatMessage.mock(text: "", poll: poll)
        let layoutOptions = components.messageLayoutOptionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: .mock(cid: .unique),
            with: .init([message]),
            appearance: appearance
        )

        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: 360).isActive = true
        view.appearance = appearance
        view.components = components
        view.setUpLayoutIfNeeded(
            options: layoutOptions,
            attachmentViewInjectorType: PollAttachmentViewInjector.self
        )
        view.content = message
        view.channel = channel
        view.currentUserId = currentUser.id
        return view
    }
}
