//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChat
import StreamChatTestHelpers
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class FilesAttachmentViewInjector_Tests: XCTestCase {
    private lazy var contentView: ChatMessageContentView! = .init()
    private lazy var subject: FilesAttachmentViewInjector! = .init(contentView)

    override func setUpWithError() throws {
        try super.setUpWithError()

        var components = Components.mock
        components.fileAttachmentListView = MockChatMessageFileAttachmentListView.self
        contentView.components = components
        subject.fileAttachmentView.translatesAutoresizingMaskIntoConstraints = false
        subject.fileAttachmentView.pin(anchors: [.width], to: 320)
    }

    override func tearDownWithError() throws {
        contentView = nil
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - configuration

    func test_fileAttachmentViewWasConfiguredCorrectly() {
        XCTAssertNotNil(subject.fileAttachmentView.itemViewProvider)
        XCTAssertNotNil(subject.fileAttachmentView.didTapOnAttachment)
    }

    // MARK: - contentViewDidPrepareForReuse

    func test_contentViewDidPrepareForReuse_prepareForReuseWasCalledOnFileAttachmentView() throws {
        subject.contentViewDidPrepareForReuse()

        XCTAssertEqual(
            try mockFileAttachmentView().recordedFunctions,
            ["prepareForReuse()"]
        )
    }

    // MARK: - makeItemView

    func test_makeItemView_attachmentIsFileAndAudioButDelegateDoesNotConformToAudioAttachmentPresentationViewDelegate_returnsExpectedResult() {
        let pdfAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .file,
            file: .mock(type: .pdf)
        )

        let audioAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .audio,
            file: .mock(type: .mp3)
        )

        subject.fileAttachmentView.content = [pdfAttachment, audioAttachment]

        AssertSnapshot(subject.fileAttachmentView)
    }

    func test_makeItemView_attachmentIsFileAndAudioAndDelegateConformsToAudioAttachmentPresentationViewDelegate_returnsExpectedResult() {
        let stubDelegate = StubChatMessageContentViewDelegate()
        subject.contentView.delegate = stubDelegate
        let pdfAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .file,
            file: .mock(type: .pdf)
        )

        let audioAttachment = ChatMessageFileAttachment.mock(
            id: .unique,
            type: .audio,
            file: .mock(type: .mp3)
        )

        subject.fileAttachmentView.content = [pdfAttachment, audioAttachment]

        AssertSnapshot(subject.fileAttachmentView)
    }

    // MARK: - Private Helpers

    private func mockFileAttachmentView(
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> MockChatMessageFileAttachmentListView {
        try XCTUnwrap(subject.fileAttachmentView as? MockChatMessageFileAttachmentListView)
    }
}

extension FilesAttachmentViewInjector_Tests {
    private final class MockChatMessageFileAttachmentListView: ChatMessageFileAttachmentListView, Spy {
        var recordedFunctions: [String] = []

        override func prepareForReuse() {
            recordedFunctions.append(#function)
        }
    }

    private class StubChatMessageContentViewDelegate: ChatMessageContentViewDelegate, AudioAttachmentPresentationViewDelegate {
        // MARK: - ChatMessageContentViewDelegate

        func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnQuotedMessage(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {}
        func messageContentViewDidTapOnQuotedMessage(_ quotedMessage: StreamChat.ChatMessage) {}

        // MARK: - AudioAttachmentPresentationViewDelegate

        func audioAttachmentPresentationViewPlaybackContextForAttachment(_ attachment: StreamChat.ChatMessageFileAttachment) -> AudioPlaybackContext { .notLoaded }
        func audioAttachmentPresentationViewBeginPayback(_ attachment: StreamChat.ChatMessageFileAttachment, with delegate: StreamChatUI.AudioPlayingDelegate) {}
        func audioAttachmentPresentationViewPausePayback() {}
        func audioAttachmentPresentationViewUpdatePlaybackRate() {}
        func audioAttachmentPresentationViewSeek(to timeInterval: TimeInterval) {}
    }
}
