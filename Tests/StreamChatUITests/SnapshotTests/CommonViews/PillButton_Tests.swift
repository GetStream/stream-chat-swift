//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import XCTest

final class PillButton_Tests: XCTestCase {
    private var subject: PillButton! = .init().withoutAutoresizingMaskConstraints

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        subject.setUp()
        subject.setUpAppearance()
        subject.setTitle("This text should appear in a pill.", for: .normal)
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - isHighlighted

    func test_isHighlighted_isTrue_backgroundColorWasSetCorrectly() {
        subject.isHighlighted = true

        XCTAssertEqual(subject.backgroundColor, subject.appearance.colorPalette.highlightedBackground)
    }

    func test_isHighlighted_isFalse_backgroundColorWasSetCorrectly() {
        subject.isHighlighted = false

        XCTAssertEqual(subject.backgroundColor, subject.appearance.colorPalette.staticColorText)
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_isHighlighted_wasConfiguredCorrectly() {
        subject.isHighlighted = true

        XCTAssertEqual(subject.tintColor, subject.appearance.colorPalette.staticBlackColorText)
        XCTAssertEqual(subject.backgroundColor, subject.appearance.colorPalette.highlightedBackground)
        XCTAssertEqual(subject.layer.shadowColor, subject.appearance.colorPalette.staticBlackColorText.cgColor)
    }

    func test_setUpAppearance_isNotHighlighted_wasConfiguredCorrectly() {
        subject.isHighlighted = false

        XCTAssertEqual(subject.tintColor, subject.appearance.colorPalette.staticBlackColorText)
        XCTAssertEqual(subject.backgroundColor, subject.appearance.colorPalette.staticColorText)
        XCTAssertEqual(subject.layer.shadowColor, subject.appearance.colorPalette.staticBlackColorText.cgColor)
    }

    // MARK: - layoutSubviews

    func test_layoutSubviews_wasConfiguredCorrectly() {
        subject.bounds = .init(x: 0, y: 0, width: 50, height: 50)

        subject.layoutSubviews()

        XCTAssertEqual(subject.layer.cornerRadius, 25)
        XCTAssertEqual(subject.layer.shadowOpacity, 0.25)
        XCTAssertEqual(subject.layer.shadowRadius, 2)
        XCTAssertEqual(subject.layer.shadowOffset.width, 0)
        XCTAssertEqual(subject.layer.shadowOffset.height, 2)
    }

    // MARK: - touchesBegan

    func test_touchesBegan_isHighlightedIsTrue() {
        subject.isHighlighted = false

        subject.touchesBegan(.init(), with: nil)

        XCTAssertTrue(subject.isHighlighted)
    }

    // MARK: - touchesEnded

    func test_touchesEnded_isHighlightedIsFalse() {
        subject.isHighlighted = true

        subject.touchesEnded(.init(), with: nil)

        XCTAssertFalse(subject.isHighlighted)
    }

    // MARK: - touchesCancelled

    func test_touchesCancelled_isHighlightedIsFalse() {
        subject.isHighlighted = true

        subject.touchesCancelled(.init(), with: nil)

        XCTAssertFalse(subject.isHighlighted)
    }

    // MARK: - Snapshots

    func test_appearance_wasConfiguredCorrectly() {
        AssertSnapshot(subject)

        subject.isHighlighted = true

        AssertSnapshot(subject, suffix: "-isHighlighted")
    }
}
