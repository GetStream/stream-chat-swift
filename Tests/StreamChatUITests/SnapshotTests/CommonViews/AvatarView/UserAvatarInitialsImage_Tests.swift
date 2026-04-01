//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatCommonUI
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class UserAvatarInitialsImage_InitialsTests: XCTestCase {
    // MARK: - initials(from:)

    func test_initials_naturalLanguageName_twoWords() {
        XCTAssertEqual(UserAvatarInitialsImage.initials(from: "John Doe"), "JD")
    }

    func test_initials_naturalLanguageName_singleWord() {
        let result = UserAvatarInitialsImage.initials(from: "John")
        XCTAssertFalse(result.isEmpty, "Single word name should produce at least one initial")
    }

    func test_initials_naturalLanguageName_threeWords() {
        // PersonNameComponentsFormatter abbreviates to at most 2 characters
        let result = UserAvatarInitialsImage.initials(from: "John Michael Doe")
        XCTAssertFalse(result.isEmpty)
        XCTAssertLessThanOrEqual(result.count, 3)
    }

    func test_initials_singleWordUsername_fallsBackToFirstLetter() {
        let result = UserAvatarInitialsImage.initials(from: "johndoe")
        XCTAssertFalse(result.isEmpty, "Single-word identifier should produce at least one initial")
    }

    func test_initials_emptyName_returnsEmpty() {
        XCTAssertEqual(UserAvatarInitialsImage.initials(from: ""), "")
    }

    func test_initials_numericId_returnsFirstCharacter() {
        let result = UserAvatarInitialsImage.initials(from: "1234")
        XCTAssertFalse(result.isEmpty, "Numeric identifier should produce at least one initial")
        XCTAssertEqual(result.first, "1")
    }

    func test_initials_uppercasedResult() {
        let result = UserAvatarInitialsImage.initials(from: "anna_karenina")
        XCTAssertEqual(result, result.uppercased(), "Initials should be uppercased")
    }

    func test_initials_maxTwoCharacters_fromFallback() {
        // Fallback takes at most the first letter of the first two words
        let result = UserAvatarInitialsImage.initials(from: "a_b_c_d")
        XCTAssertLessThanOrEqual(result.count, 2)
    }
}

// MARK: - Snapshot tests

@MainActor final class UserAvatarInitialsImage_SnapshotTests: XCTestCase {
    private let size = CGSize(width: 50, height: 50)

    func test_image_withTwoWordName() {
        let image = UserAvatarInitialsImage.image(
            name: "Luke Skywalker",
            size: size,
            appearance: .init()
        )
        let view = imageView(for: image)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_image_withSingleWordName() {
        let image = UserAvatarInitialsImage.image(
            name: "Yoda",
            size: size,
            appearance: .init()
        )
        let view = imageView(for: image)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_image_withNonStandardUsername() {
        let image = UserAvatarInitialsImage.image(
            name: "han_solo",
            size: size,
            appearance: .init()
        )
        let view = imageView(for: image)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_image_withEmptyName_showsPersonIcon() {
        let image = UserAvatarInitialsImage.image(
            name: "",
            size: size,
            appearance: .init()
        )
        let view = imageView(for: image)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    func test_image_smallSize_singleInitial() {
        // Sizes < 28pt should show only 1 initial
        let smallSize = CGSize(width: 24, height: 24)
        let image = UserAvatarInitialsImage.image(
            name: "Luke Skywalker",
            size: smallSize,
            appearance: .init()
        )
        let view = imageView(for: image)
        AssertSnapshot(view, variants: .onlyUserInterfaceStyles)
    }

    // MARK: - Helpers

    private func imageView(for image: UIImage) -> UIImageView {
        let imageView = UIImageView(image: image)
        imageView.layer.cornerRadius = image.size.width / 2
        imageView.clipsToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: image.size.width),
            imageView.heightAnchor.constraint(equalToConstant: image.size.height)
        ])
        return imageView
    }
}
