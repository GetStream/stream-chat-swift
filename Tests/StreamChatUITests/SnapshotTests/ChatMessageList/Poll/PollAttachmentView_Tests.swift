//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

@MainActor final class PollAttachmentView_Tests: XCTestCase {
    let currentUser = ChatUser.mock(
        id: .unique,
        imageURL: TestImages.yoda.url
    )

    lazy var pollFactory = PollMockFactory(currentUser: currentUser)

    func test_appearance() {
        let poll = pollFactory.makePoll(isClosed: false)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view)
    }

    func test_appearance_whenClosed() {
        let poll = pollFactory.makePoll(
            isClosed: true,
            allowAnswers: true,
            allowUserSuggestedOptions: true
        )
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight, .defaultDark])
    }

    func test_appearance_withComments() {
        let poll = pollFactory.makePoll(allowAnswers: true, answersCount: 5)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight, .defaultDark])
    }

    func test_appearance_withZeroComments() {
        let poll = pollFactory.makePoll(allowAnswers: true, answersCount: 0)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenSuggestionsEnabled() {
        let poll = pollFactory.makePoll(allowAnswers: true, allowUserSuggestedOptions: true, answersCount: 3)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenAnonymous() {
        let poll = pollFactory.makePoll(allowAnswers: true, answersCount: 3, votingVisibility: .anonymous)
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_withComments_whenCurrentUserAlreadyComment() {
        let poll = pollFactory.makePoll(
            allowAnswers: true,
            answersCount: 5,
            latestAnswers: [.mock(user: currentUser)]
        )
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_appearance_whenOptionsMoreThanMaxVisibleOptions() {
        let voteCountsByOption: [String: Int] = [
            "1": 2,
            "2": 1,
            "3": 1,
            "4": 1,
            "5": 1,
            "6": 1,
            "7": 1,
            "8": 1,
            "9": 1,
            "10": 1,
            "11": 1,
            "12": 1
        ]
        let poll = Poll.mock(
            allowAnswers: true,
            answersCount: 3,
            name: "Many Options",
            voteCountsByOption: voteCountsByOption,
            isClosed: false,
            options: voteCountsByOption.sorted(by: { $0.key > $1.key }).map {
                .init(text: $0.key)
            }
        )
        let view = makeMessageView(for: poll)
        AssertSnapshot(view, variants: [.defaultLight])
    }

    func test_translation_whenAutoTranslationEnabled_showsTranslatedTexts() throws {
        let view = makeMessageView(
            for: makeTranslatedPoll(),
            components: translationComponents(),
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .spanish))
        )
        let pollView = try pollAttachmentView(in: view)

        XCTAssertEqual(pollView.content?.translationLanguage, .spanish)
        XCTAssertEqual(pollView.pollTitleLabel.text, "¿Qué hay de almuerzo?")
        XCTAssertEqual(
            pollView.optionListView.itemViews.map(\.optionNameLabel.text),
            ["Sopa", "Pizza", "Ensalada"]
        )
        XCTAssertEqual(view.translationLabel?.text, "Translated to Spanish")
    }

    func test_translation_whenAutoTranslationDisabled_showsOriginalTexts() throws {
        let view = makeMessageView(
            for: makeTranslatedPoll(),
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .spanish))
        )
        let pollView = try pollAttachmentView(in: view)

        XCTAssertNil(pollView.content?.translationLanguage)
        XCTAssertEqual(pollView.pollTitleLabel.text, "What's for lunch?")
        XCTAssertEqual(
            pollView.optionListView.itemViews.map(\.optionNameLabel.text),
            ["Soup", "Pizza", "Salad"]
        )
        XCTAssertNil(view.translationLabel)
    }

    func test_translation_whenUserLanguageHasNoTranslation_showsOriginalTexts() throws {
        let view = makeMessageView(
            for: makeTranslatedPoll(),
            components: translationComponents(),
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .french))
        )
        let pollView = try pollAttachmentView(in: view)

        XCTAssertEqual(pollView.pollTitleLabel.text, "What's for lunch?")
        XCTAssertEqual(
            pollView.optionListView.itemViews.map(\.optionNameLabel.text),
            ["Soup", "Pizza", "Salad"]
        )
        XCTAssertNil(view.translationLabel)
    }

    func test_appearance_whenTranslated() {
        let view = makeMessageView(
            for: makeTranslatedPoll(),
            components: translationComponents(),
            channel: .mock(cid: .unique, membership: .mock(id: .unique, language: .spanish)),
            width: 500
        )
        AssertSnapshot(view)
    }

    func test_subtitleText() {
        let pollAttachmentView = PollAttachmentView()
        let pollDefault = pollFactory.makePoll(isClosed: false)
        let pollClosed = pollFactory.makePoll(isClosed: true)
        let pollUniqueVotes = pollFactory.makePoll(isClosed: false, enforceUniqueVote: true)
        let pollMaxVotesAllowed = pollFactory.makePoll(isClosed: false, maxVotesAllowed: 3)

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
    private func pollAttachmentView(in messageView: ChatMessageContentView) throws -> PollAttachmentView {
        let container = UIView()
        container.addSubview(messageView)
        messageView.updateContent()
        messageView.layoutIfNeeded()
        return try XCTUnwrap((messageView.attachmentViewInjector as? PollAttachmentViewInjector)?.pollAttachmentView)
    }

    private func translationComponents() -> Components {
        var components = Components.mock
        components.messageAutoTranslationEnabled = true
        return components
    }

    private func makeTranslatedPoll() -> Poll {
        Poll.mock(
            name: "What's for lunch?",
            voteCountsByOption: ["soup": 2, "pizza": 1],
            options: [
                .init(id: "soup", text: "Soup", translations: [.spanish: "Sopa"], originalLanguage: .english),
                .init(id: "pizza", text: "Pizza", translations: [.spanish: "Pizza"], originalLanguage: .english),
                .init(id: "salad", text: "Salad", translations: [.spanish: "Ensalada"], originalLanguage: .english)
            ],
            nameTranslations: [.english: "What's for lunch?", .spanish: "¿Qué hay de almuerzo?"],
            originalLanguage: .english
        )
    }

    private func makeMessageView(
        for poll: Poll,
        appearance: Appearance? = nil,
        components: Components? = nil,
        channel: ChatChannel? = nil,
        width: CGFloat = 360
    ) -> ChatMessageContentView {
        let appearance = appearance ?? .default
        let components = components ?? .mock
        let channel = channel ?? ChatChannel.mock(cid: .unique)
        let message = ChatMessage.mock(text: "", poll: poll)
        components.messageLayoutOptionsResolver.components = components
        let layoutOptions = components.messageLayoutOptionsResolver.optionsForMessage(
            at: .init(item: 0, section: 0),
            in: channel,
            with: .init([message]),
            appearance: appearance
        )

        let view = ChatMessageContentView().withoutAutoresizingMaskConstraints
        view.widthAnchor.constraint(equalToConstant: width).isActive = true
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
