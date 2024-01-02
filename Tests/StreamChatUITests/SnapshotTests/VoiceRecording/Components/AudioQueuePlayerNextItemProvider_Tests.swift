//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class AudioQueuePlayerNextItemProvider_Tests: XCTestCase {
    private lazy var userA: ChatUser! = .mock(id: .unique)
    private lazy var userB: ChatUser! = .mock(id: .unique)
    private lazy var userC: ChatUser! = .mock(id: .unique)
    private lazy var encoder: JSONEncoder! = .init()
    private lazy var subject: AudioQueuePlayerNextItemProvider! = .init()
    private lazy var messages: [ChatMessage]! = [
        .mock(author: userA),
        .mock(author: userA),
        .mock(author: userB),
        .mock(author: userA),
        .mock(author: userC, isSentByCurrentUser: true),
        .mock(
            author: userB,
            attachments: [
                makeAttachment(of: .voiceRecording)
            ]
        ),
        .mock(
            author: userB,
            attachments: [
                makeAttachment(of: .voiceRecording),
                makeAttachment(of: .image),
                makeAttachment(of: .voiceRecording),
                makeAttachment(of: .file)
            ]
        ),
        .mock(author: userC, isSentByCurrentUser: true),
        .mock(author: userA),
        .mock(author: userC, isSentByCurrentUser: true),
        .mock(author: userB)
    ]

    private var messageFromUserBWithMoreThanOneVoiceRecording: ChatMessage { messages[6] }
    private var messageFromUserBWithOneVoiceRecording: ChatMessage { messages[5] }

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        messages = nil
        encoder = nil
        userC = nil
        userB = nil
        userA = nil
        super.tearDown()
    }

    // MARK: - findNextItem(in:currentVoiceRecordingURL:lookUpScope)

    func test_findNextItem_messagesIsEmpty_returnsNil() {
        XCTAssertNil(
            subject.findNextItem(
                in: [],
                currentVoiceRecordingURL: .unique(),
                lookUpScope: .sameMessage
            )
        )
    }

    func test_findNextItem_currentVoiceRecordingURLIsNil_returnsNil() {
        XCTAssertNil(
            subject.findNextItem(
                in: messages,
                currentVoiceRecordingURL: .unique(),
                lookUpScope: .sameMessage
            )
        )
    }

    func test_findNextItem_lookUpScopeIsSameMessage_currentMessageContainsNextVoiceRecording_returnsExpectedValue() throws {
        let currentVoiceRecordingURL = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.first?.voiceRecordingURL)
        let expected = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.last?.voiceRecordingURL)

        let actual = subject.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentVoiceRecordingURL,
            lookUpScope: .sameMessage
        )

        XCTAssertEqual(expected, actual)
    }

    func test_findNextItem_lookUpScopeIsSameMessage_currentMessageDoesNotContainNextVoiceRecording_returnsNil() throws {
        let currentVoiceRecordingURL = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.last?.voiceRecordingURL)

        let actual = subject.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentVoiceRecordingURL,
            lookUpScope: .sameMessage
        )

        XCTAssertNil(actual)
    }

    func test_findNextItem_lookUpScopeIsSubsequentMessagesFromUser_currentMessageContainsNextVoiceRecording_returnsExpectedValue() throws {
        let currentVoiceRecordingURL = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.first?.voiceRecordingURL)
        let expected = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.last?.voiceRecordingURL)

        let actual = subject.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentVoiceRecordingURL,
            lookUpScope: .subsequentMessagesFromUser
        )

        XCTAssertEqual(expected, actual)
    }

    func test_findNextItem_lookUpScopeIsSubsequentMessagesFromUser_currentMessageDoesNotContainNextVoiceRecording_returnsExpectedValue() throws {
        let currentVoiceRecordingURL = try XCTUnwrap(messageFromUserBWithMoreThanOneVoiceRecording.voiceRecordingAttachments.last?.voiceRecordingURL)
        let expected = try XCTUnwrap(messageFromUserBWithOneVoiceRecording.voiceRecordingAttachments.first?.voiceRecordingURL)

        let actual = subject.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentVoiceRecordingURL,
            lookUpScope: .subsequentMessagesFromUser
        )

        XCTAssertEqual(expected, actual)
    }

    func test_findNextItem_lookUpScopeIsSubsequentMessagesFromUser_currentMessageDoesNotContainNextVoiceRecordingAndNoValidSubsequentMessageDoes_returnsNil() throws {
        let currentVoiceRecordingURL = try XCTUnwrap(messageFromUserBWithOneVoiceRecording.voiceRecordingAttachments.first?.voiceRecordingURL)

        let actual = subject.findNextItem(
            in: messages,
            currentVoiceRecordingURL: currentVoiceRecordingURL,
            lookUpScope: .subsequentMessagesFromUser
        )

        XCTAssertNil(actual)
    }

    // MARK: - Private Helpers

    private func makeAttachment(of type: AttachmentType) -> AnyChatMessageAttachment {
        let payload = VoiceRecordingAttachmentPayload(
            title: .unique,
            voiceRecordingRemoteURL: .unique(),
            file: .init(type: .aac, size: 120, mimeType: nil),
            duration: nil,
            waveformData: nil,
            extraData: nil
        )
        return AnyChatMessageAttachment(
            id: .init(cid: .unique, messageId: .unique, index: 0),
            type: type,
            payload: try! encoder.encode(payload),
            uploadingState: nil
        )
    }
}
