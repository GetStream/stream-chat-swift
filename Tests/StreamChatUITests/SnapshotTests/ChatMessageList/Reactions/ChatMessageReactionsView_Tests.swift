//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageReactionsView_Tests: XCTestCase {
    var sut: ChatMessageReactionsView!

    var mockedReactionsData: [ChatMessageReactionData] {
        [
            .init(type: "love", score: 1, isChosenByCurrentUser: true),
            .init(type: "haha", score: 5, isChosenByCurrentUser: true),
            .init(type: "like", score: 3, isChosenByCurrentUser: false),
            .init(type: "wow", score: 3, isChosenByCurrentUser: false),
            .init(type: "sad", score: 1, isChosenByCurrentUser: false)
        ]
    }

    override func setUp() {
        super.setUp()

        sut = ChatMessageReactionsView().withoutAutoresizingMaskConstraints
        sut.addSizeConstraints()
    }

    override func tearDown() {
        sut = nil

        super.tearDown()
    }

    func test_defaultAppearance_whenBigIcons() {
        sut.content = .init(
            useBigIcons: true,
            reactions: mockedReactionsData,
            didTapOnReaction: nil
        )
        AssertSnapshot(sut)
    }

    func test_defaultAppearance_whenSmallIcons() {
        sut.content = .init(
            useBigIcons: false,
            reactions: mockedReactionsData,
            didTapOnReaction: nil
        )
        AssertSnapshot(sut)
    }

    func test_defaultAppearance_whenCustomSorting() {
        sut.components = .mock
        sut.components.reactionsSorting = { $0.score > $1.score }
        sut.content = .init(
            useBigIcons: false,
            reactions: mockedReactionsData,
            didTapOnReaction: nil
        )
        AssertSnapshot(sut, variants: [.defaultLight])
    }
}

private extension ChatMessageReactionsView {
    func addSizeConstraints() {
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 300),
            heightAnchor.constraint(equalToConstant: 60)
        ])
    }
}
