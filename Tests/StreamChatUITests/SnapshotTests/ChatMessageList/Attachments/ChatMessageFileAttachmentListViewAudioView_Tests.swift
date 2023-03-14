//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestHelpers
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class ChatMessageFileAttachmentListViewAudioView_Tests: XCTestCase {
    private lazy var audioPlayer: MockAudioPlayer! = .init()
    private lazy var delegate: MockAudioAttachmentPresentationViewDelegate! = .init()
    private lazy var subject: ChatMessageFileAttachmentListView.AudioView! = .init()

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        try super.setUpWithError()
        subject.translatesAutoresizingMaskIntoConstraints = false
        subject.delegate = delegate
        subject.content = .mock(id: .unique, type: .audio, file: .mock(type: .mp3))
        subject.pin(anchors: [.width], to: 320)
    }

    override func tearDownWithError() throws {
        subject = nil
        audioPlayer = nil
        delegate = nil
        try super.tearDownWithError()
    }

    // MARK: - updateContent

    func test_updateContent_viewHasBeenConfiguredCorrectlyForEachPlaybackState() {
        AudioPlaybackState.allCases
            .forEach { assertViewWithPlaybackContext(.dummy(duration: 100, currentTime: 50, state: $0)) }
    }

    // MARK: - didTapLeadingButton

    func test_didTapLeadingButton_senderIsNotSelected_callsBeginPlaybackOnDelegateWithExpectedData() {
        let attachment = ChatMessageFileAttachment.mock(id: .unique)
        subject.content = attachment
        subject.leadingButton.isSelected = false

        subject.didTapLeadingButton(subject.leadingButton)

        XCTAssertEqual(delegate.audioAttachmentPresentationViewBeginPaybackWasCalledWith?.attachment, attachment)
        XCTAssertEqual(delegate.audioAttachmentPresentationViewBeginPaybackWasCalledWith?.delegate as? ChatMessageFileAttachmentListView.AudioView, subject)
    }

    func test_didTapLeadingButton_senderIsSelected_callsPausePlaybackOnDelegate() {
        subject.leadingButton.isSelected = true

        subject.didTapLeadingButton(subject.leadingButton)

        XCTAssertEqual(delegate.recordedFunctions, ["audioAttachmentPresentationViewPausePayback()"])
    }

    // MARK: - didTapTrailingButton

    func test_didTapTrailingButton_callsUpdateRateOnDelegate() {
        subject.didTapTrailingButton(subject.trailingButton)

        XCTAssertEqual(delegate.recordedFunctions, ["audioAttachmentPresentationViewUpdatePlaybackRate()"])
    }

    // MARK: - didChangeSliderValue

    func test_didChangeSliderValue_callsAudioAttachmentPresentationViewSeekOnDelegate() {
        subject.progressView.maximumValue = 10
        subject.progressView.value = 5

        subject.didChangeSliderValue(subject.progressView)

        XCTAssertEqual(delegate.recordedFunctions, ["audioAttachmentPresentationViewSeek(to:)"])
        XCTAssertEqual(delegate.audioAttachmentPresentationViewSeekWasCalledWith, 5)
    }

    // MARK: - Private Helpers

    private func assertViewWithPlaybackContext(
        _ context: AudioPlaybackContext,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        delegate.stubbedAudioAttachmentPresentationViewPlaybackContextForAttachmentResult = context
        subject.audioPlayer(audioPlayer, didUpdateContext: context)
        AssertSnapshot(subject, suffix: "\(context.state)", line: line, file: file, function: function)
    }
}

extension ChatMessageFileAttachmentListViewAudioView_Tests {
    private final class MockAudioPlayer: AudioPlaying {
        private(set) var playbackContextWasCalledWithURL: URL?
        var stubbedPlaybackContextResult: AudioPlaybackContext = .notLoaded

        static func build() -> StreamChatUI.AudioPlaying { MockAudioPlayer() }
        func playbackContext(for url: URL) -> AudioPlaybackContext {
            playbackContextWasCalledWithURL = url
            return stubbedPlaybackContextResult
        }

        func loadAsset(from url: URL?, delegate: StreamChatUI.AudioPlayingDelegate) {}
        func play() {}
        func pause() {}
        func stop() {}
        func updateRate() {}
        func seek(to time: TimeInterval) {}
    }

    private final class MockAudioAttachmentPresentationViewDelegate: AudioAttachmentPresentationViewDelegate, Spy {
        var recordedFunctions: [String] = []

        var stubbedAudioAttachmentPresentationViewPlaybackContextForAttachmentResult: AudioPlaybackContext = .notLoaded

        private(set) var audioAttachmentPresentationViewBeginPaybackWasCalledWith: (attachment: StreamChat.ChatMessageFileAttachment, delegate: StreamChatUI.AudioPlayingDelegate)?
        private(set) var audioAttachmentPresentationViewSeekWasCalledWith: TimeInterval?

        func audioAttachmentPresentationViewPlaybackContextForAttachment(
            _ attachment: StreamChat.ChatMessageFileAttachment
        ) -> StreamChatUI.AudioPlaybackContext {
            record()
            return stubbedAudioAttachmentPresentationViewPlaybackContextForAttachmentResult
        }

        func audioAttachmentPresentationViewBeginPayback(
            _ attachment: StreamChat.ChatMessageFileAttachment,
            with delegate: StreamChatUI.AudioPlayingDelegate
        ) {
            record()
            audioAttachmentPresentationViewBeginPaybackWasCalledWith = (attachment, delegate)
        }

        func audioAttachmentPresentationViewPausePayback() {
            record()
        }

        func audioAttachmentPresentationViewUpdatePlaybackRate() {
            record()
        }

        func audioAttachmentPresentationViewSeek(to timeInterval: TimeInterval) {
            record()
            audioAttachmentPresentationViewSeekWasCalledWith = timeInterval
        }

        func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {}
    }
}
