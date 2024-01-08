//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatUI
import XCTest

final class TextViewMentionedUsersHandler_Tests: XCTestCase {
    func test_mentionedUserTapped_whenRangeIncludesMention() {
        let textView = UITextView()
        textView.text = "@Leia Hello!"

        let sut = TextViewMentionedUsersHandler()
        let user = sut.mentionedUserTapped(
            on: textView,
            in: .init(location: 0, length: 5),
            with: [.mock(id: "leia", name: "Leia")]
        )

        XCTAssertEqual(user?.name, "Leia")
    }

    func test_mentionedUserTapped_whenRangeDoesNotIncludeMention() {
        let textView = UITextView()
        textView.text = "@Leia Hello!"

        let sut = TextViewMentionedUsersHandler()
        let user = sut.mentionedUserTapped(
            on: textView,
            in: .init(location: 3, length: 7),
            with: [.mock(id: "leia", name: "Leia")]
        )

        XCTAssertEqual(user?.name, nil)
    }

    func test_mentionedUserTapped_whenIncludesSpecialCharacter() {
        let textView = UITextView()
        textView.text = "@Lei@ Hello!"

        let sut = TextViewMentionedUsersHandler()
        let user = sut.mentionedUserTapped(
            on: textView,
            in: .init(location: 0, length: 5),
            with: [.mock(id: "leia", name: "Lei@")]
        )

        XCTAssertEqual(user?.name, "Lei@")
    }

    // Customers can customise how mentions are presented, and so they can chose not to show it.
    func test_mentionedUserTapped_whenAtSignIsNotPresent() {
        let textView = UITextView()
        textView.text = "Lei@ Hello!"

        let sut = TextViewMentionedUsersHandler()
        let user = sut.mentionedUserTapped(
            on: textView,
            in: .init(location: 0, length: 5),
            with: [.mock(id: "leia", name: "Lei@")]
        )

        XCTAssertEqual(user?.name, "Lei@")
    }

    func test_mentionedUserTapped_whenUserDoesNotHaveName() {
        let textView = UITextView()
        textView.text = "leia Hello!"

        let sut = TextViewMentionedUsersHandler()
        let user = sut.mentionedUserTapped(
            on: textView,
            in: .init(location: 0, length: 5),
            with: [.mock(id: "leia", name: nil)]
        )

        XCTAssertEqual(user?.id, "leia")
    }
}
