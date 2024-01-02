//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import StreamSwiftTestHelpers
import UIKit
import XCTest

final class ChatMessageVoiceRecordingAttachmentListView_Tests: XCTestCase {
    private lazy var playbackDelegate: MockVoiceRecordingAttachmentPresentationViewDelegate! = .init()
    private lazy var subject: ChatMessageVoiceRecordingAttachmentListView! = .init().withoutAutoresizingMaskConstraints
    private lazy var duration: TimeInterval! = 10
    private lazy var waveformData: [Float]! = [0, 0, 0, 0.3, 0.7, 0.6, 0.55, 0, 0, 0]

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        subject.playbackDelegate = playbackDelegate
        playbackDelegate.onConnectCallWithContextAndPlayer = (MockAudioPlayer(), .notLoaded)
    }

    override func tearDown() {
        playbackDelegate = nil
        waveformData = nil
        duration = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - appearance

    func test_appearance_one_attachment() throws {
        subject.content = [.mock(id: .unique, duration: duration, waveformData: waveformData)]
        AssertSnapshot(subject)
    }

    func test_appearance_two_attachments() {
        subject.content = [
            .mock(id: .unique, duration: duration, waveformData: waveformData),
            .mock(id: .unique, title: "Test Title", duration: duration, waveformData: waveformData)
        ]

        AssertSnapshot(subject)
    }

    func test_appearance_five_attachments() {
        subject.content = [
            .mock(
                id: .unique,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .aac, size: 400, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .aac, size: 3600, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .aac, size: 18320, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .aac, size: 500_000, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            )
        ]

        AssertSnapshot(subject)
    }

    func test_appearanceCustomization_usingSubclassing() {
        class TestView: ChatMessageVoiceRecordingAttachmentListView {
            override func setUpLayout() {
                super.setUpLayout()

                containerStackView.axis = .horizontal
                containerStackView.spacing = 20
            }
        }

        let subject = TestView().withoutAutoresizingMaskConstraints
        subject.playbackDelegate = playbackDelegate

        subject.content = [
            .mock(
                id: .unique,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample2",
                file: .init(type: .aac, size: 400, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample3",
                file: .init(type: .aac, size: 3600, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample4",
                file: .init(type: .aac, size: 18320, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            ),
            .mock(
                id: .unique,
                title: "Sample5",
                file: .init(type: .aac, size: 500_000, mimeType: nil),
                localState: .uploaded,
                duration: duration,
                waveformData: waveformData
            )
        ]

        AssertSnapshot(subject)
    }

    // MARK: - updateContent

    func test_updateContent_arrangedSubviewsHaveTheirDelegateAndIndexProviderSetCorrectly() throws {
        let playbackDelegate = MockVoiceRecordingAttachmentPresentationViewDelegate()
        subject.playbackDelegate = playbackDelegate

        subject.content = [
            .mock(id: .unique),
            .mock(id: .unique, title: "Test Title")
        ]

        let subviews = try XCTUnwrap(subject.containerStackView.arrangedSubviews as? [ChatMessageVoiceRecordingAttachmentListView.ItemView])
        subviews.enumerated().forEach { entry in
            XCTAssertTrue(entry.element.presenter.delegate === playbackDelegate)
            XCTAssertEqual(entry.element.indexProvider?(), entry.offset)
        }
    }
}
