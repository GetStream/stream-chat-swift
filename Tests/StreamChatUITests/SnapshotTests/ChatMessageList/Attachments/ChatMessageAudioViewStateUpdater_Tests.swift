//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatUI
import XCTest

final class ChatMessageAudioViewStateUpdater_Tests: XCTestCase {
    private lazy var audioView: ChatMessageFileAttachmentListView.AudioView! = .init()
    private lazy var subject: ChatMessageAudioViewStateUpdater! = .init()

    override func tearDownWithError() throws {
        audioView = nil
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - configure(leadingButton:for:with)

    func test_configureLeadingButton_notLoadedAndLoading_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded, .loading],
            element: \.leadingButton,
            configurationCall: { subject.configure(leadingButton: $0, for: $1, with: $2) }
        ) { element, _, appearance in
            XCTAssertFalse(element.isSelected)
            XCTAssertEqual(element.image(for: .normal), appearance.images.play)
            XCTAssertEqual(element.image(for: .selected), appearance.images.play)
        }
    }

    func test_configureLeadingButton_pausedPlayingStopped_configuresViewCorrectly() throws {
        try assertViewState(
            [.paused, .playing, .stopped],
            element: \.leadingButton,
            configurationCall: { subject.configure(leadingButton: $0, for: $1, with: $2) }
        ) { element, state, appearance in
            XCTAssertEqual(element.isSelected, state == .playing)
            XCTAssertEqual(element.image(for: .normal), appearance.images.play)
            XCTAssertEqual(element.image(for: .selected), appearance.images.pause)
        }
    }

    // MARK: - configure(loadingIndicator:for:with)

    func test_configureLoadingIndicator_loading_configuresViewCorrectly() throws {
        try assertViewState(
            [.loading],
            element: \.loadingIndicator,
            configurationCall: { subject.configure(loadingIndicator: $0, for: $1, with: $2) }
        ) { element, _, _ in
            XCTAssertFalse(element.isHidden)
            XCTAssertNotNil(element.layer.animation(forKey: ChatLoadingIndicator.kRotationAnimationKey))
        }
    }

    func test_configureLoadingIndicator_anyOtherThanLoading_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded, .playing, .stopped, .paused],
            element: \.loadingIndicator,
            configurationCall: { subject.configure(loadingIndicator: $0, for: $1, with: $2) }
        ) { element, _, _ in
            XCTAssertTrue(element.isHidden)
            XCTAssertNil(element.layer.animation(forKey: ChatLoadingIndicator.kRotationAnimationKey))
        }
    }

    // MARK: - configure(detailsLabel:for:with:value)

    func test_configureDetailsLabel_notLoaded_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded],
            element: \.detailsLabel,
            configurationCall: { subject.configure(detailsLabel: $0, for: $1, with: $2, value: "test") }
        ) { element, _, appearance in
            XCTAssertFalse(element.isHidden)
            XCTAssertEqual(element.font, appearance.fonts.caption1)
            XCTAssertEqual(element.text, "test")
        }
    }

    func test_configureDetailsLabel_loading_configuresViewCorrectly() throws {
        try assertViewState(
            [.loading],
            element: \.detailsLabel,
            configurationCall: { subject.configure(detailsLabel: $0, for: $1, with: $2, value: "test") }
        ) { element, _, _ in
            XCTAssertTrue(element.isHidden)
            XCTAssertNil(element.text)
        }
    }

    func test_configureDetailsLabel_pausedPlayingStopped_configuresViewCorrectly() throws {
        try assertViewState(
            [.paused, .playing, .stopped],
            element: \.detailsLabel,
            configurationCall: { subject.configure(detailsLabel: $0, for: $1, with: $2, value: "test") }
        ) { element, _, appearance in
            XCTAssertFalse(element.isHidden)
            XCTAssertEqual(element.font, .monospacedDigitSystemFont(ofSize: appearance.fonts.caption1.pointSize, weight: .medium))
            XCTAssertEqual(element.text, "test")
        }
    }

    // MARK: - configure(progressView:for:with:maximumValue:value)

    func test_configureProgressView_notLoadedLoadingStopped_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded, .loading, .stopped],
            element: \.progressView,
            configurationCall: { subject.configure(progressView: $0, for: $1, with: $2, maximumValue: 100, value: 50) }
        ) { element, _, _ in
            XCTAssertFalse(element.isEnabled)
            XCTAssertEqual(element.maximumValue, 0)
            XCTAssertEqual(element.value, 0)
        }
    }

    func test_configureProgressView_pausedPlaying_configuresViewCorrectly() throws {
        try assertViewState(
            [.paused, .playing],
            element: \.progressView,
            configurationCall: { subject.configure(progressView: $0, for: $1, with: $2, maximumValue: 100, value: 50) }
        ) { element, _, _ in
            XCTAssertTrue(element.isEnabled)
            XCTAssertEqual(element.maximumValue, 100)
            XCTAssertEqual(element.value, 50)
        }
    }

    // MARK: - configure(fileIconImageView:for:with)

    func test_configureFileIconImageView_notLoadedLoadingStopped_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded, .loading, .stopped],
            element: \.fileIconImageView,
            configurationCall: { subject.configure(fileIconImageView: $0, for: $1, with: $2) }
        ) { element, _, _ in
            XCTAssertFalse(element.isHidden)
        }
    }

    func test_configureFileIconImageView_pausedPlaying_configuresViewCorrectly() throws {
        try assertViewState(
            [.paused, .playing],
            element: \.fileIconImageView,
            configurationCall: { subject.configure(fileIconImageView: $0, for: $1, with: $2) }
        ) { element, _, _ in
            XCTAssertTrue(element.isHidden)
        }
    }

    // MARK: - configure(trailingButton:for:with:value:)

    func test_configureTrailingButton_notLoadedLoadingStopped_configuresViewCorrectly() throws {
        try assertViewState(
            [.notLoaded, .loading, .stopped],
            element: \.trailingButton,
            configurationCall: { subject.configure(trailingButton: $0, for: $1, with: $2, value: "x1.5") }
        ) { element, _, _ in
            XCTAssertTrue(element.isHidden)
            XCTAssertEqual(element.title(for: .normal), nil)
        }
    }

    func test_configureTrailingButton_pausedPlaying_configuresViewCorrectly() throws {
        try assertViewState(
            [.paused, .playing],
            element: \.trailingButton,
            configurationCall: { subject.configure(trailingButton: $0, for: $1, with: $2, value: "x1.5") }
        ) { element, _, _ in
            XCTAssertFalse(element.isHidden)
            XCTAssertEqual(element.title(for: .normal), "x1.5")
        }
    }

    // MARK: - Private Helpers

    private func assertViewState<ViewElement: UIView>(
        _ states: [AudioPlaybackState],
        element: KeyPath<ChatMessageFileAttachmentListView.AudioView, ViewElement>,
        configurationCall: (ViewElement, AudioPlaybackState, Appearance) -> Void,
        validationBlock: (ViewElement, AudioPlaybackState, Appearance) -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let audioView = try XCTUnwrap(audioView, file: file, line: line)
        let appearance = audioView.appearance
        let element = audioView[keyPath: element]
        for state in states {
            configurationCall(element, state, audioView.appearance)
            validationBlock(element, state, appearance)
        }
    }
}
