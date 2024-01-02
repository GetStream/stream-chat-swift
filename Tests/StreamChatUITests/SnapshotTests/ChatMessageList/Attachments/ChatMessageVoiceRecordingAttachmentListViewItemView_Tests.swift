//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
@testable import StreamChatUI
import UIKit
import XCTest

final class ChatMessageVoiceRecordingAttachmentListViewItemView_Tests: XCTestCase {
    private lazy var presenter: SpyChatMessageVoiceRecordingAttachmentListViewItemViewViewPresenter! = .init(subject)
    private lazy var subject: ChatMessageVoiceRecordingAttachmentListView.ItemView! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        var components = Components.mock
        components.isVoiceRecordingEnabled = true
        subject.components = components
        subject.presenter = presenter
        subject.setUp()
        subject.setUpLayout()
        subject.setUpAppearance()
    }

    override func tearDown() {
        subject = nil
        presenter = nil
        super.tearDown()
    }

    // MARK: - setUp

    func test_setUp_setUpWasCalledOnPresenter() {
        XCTAssertTrue(presenter.setUpWasCalled)
    }

    // MARK: - setUpLayout

    func test_setUpLayout_playbackLoadingClampedViewWasConfiguredCorrectly() {
        XCTAssertTrue(subject.playbackLoadingClampedView.superview === subject.bottomContainerStackView)
        XCTAssertEqual(subject.playbackLoadingClampedView.axis, .vertical)
        XCTAssertEqual(subject.playbackLoadingClampedView.container.arrangedSubviews, [
            subject.playbackLoadingIndicator,
            subject.durationLabel
        ])
    }

    func test_setUpLayout_fileIconAndPlaybackRateClampedViewWasConfiguredCorrectly() {
        XCTAssertTrue(subject.fileIconAndPlaybackRateClampedView.superview === subject.mainContainerStackView)
        XCTAssertEqual(subject.fileIconAndPlaybackRateClampedView.container.arrangedSubviews, [
            subject.fileIconImageView,
            subject.playbackRateButton
        ])
    }

    func test_setUpLayout_bottomContainerStackViewWasConfiguredCorrectly() {
        XCTAssertTrue(subject.bottomContainerStackView.superview === subject.centerContainerStackView)
        XCTAssertEqual(subject.bottomContainerStackView.axis, .horizontal)
        XCTAssertEqual(subject.bottomContainerStackView.spacing, 4)
        XCTAssertEqual(subject.bottomContainerStackView.alignment, .center)
        XCTAssertEqual(subject.bottomContainerStackView.subviews, [
            subject.loadingIndicator,
            subject.fileSizeLabel,
            subject.playbackLoadingClampedView,
            subject.waveformView
        ])
    }

    func test_setUpLayout_centerContainerStackViewWasConfiguredCorrectly() {
        XCTAssertTrue(subject.centerContainerStackView.superview === subject.mainContainerStackView)
        XCTAssertEqual(subject.centerContainerStackView.axis, .vertical)
        XCTAssertEqual(subject.centerContainerStackView.spacing, 8)
        XCTAssertEqual(subject.centerContainerStackView.alignment, .fill)
        XCTAssertEqual(subject.centerContainerStackView.arrangedSubviews, [
            subject.fileNameLabel,
            subject.bottomContainerStackView
        ])
    }

    func test_setUpLayout_mainContainerStackViewWasConfiguredCorrectly() {
        XCTAssertTrue(subject.mainContainerStackView.superview === subject)
        XCTAssertEqual(subject.mainContainerStackView.axis, .horizontal)
        XCTAssertEqual(subject.mainContainerStackView.spacing, 8)
        XCTAssertEqual(subject.mainContainerStackView.alignment, .center)
        XCTAssertEqual(subject.mainContainerStackView.arrangedSubviews, [
            subject.playPauseButton,
            subject.centerContainerStackView,
            subject.fileIconAndPlaybackRateClampedView
        ])
    }

    func test_setUpLayout_durationLabelWasConfiguredCorrectly() {
        XCTAssertEqual(subject.durationLabel.contentHuggingPriority(for: .vertical), .streamRequire)
    }

    func test_setUpLayout_waveformViewWasConfiguredCorrectly() {
        XCTAssertEqual(subject.waveformView.contentHuggingPriority(for: .vertical), .streamLow)
    }

    func test_setUpLayout_fileIconImageViewWasConfiguredCorrectly() {
        XCTAssertEqual(subject.fileIconImageView.contentHuggingPriority(for: .horizontal), .streamRequire)
    }

    // MARK: - setUpAppearance

    func test_setUpAppearance_viewWasConfiguredCorrectly() {
        XCTAssertEqual(subject.backgroundColor, subject.appearance.colorPalette.popoverBackground)
        XCTAssertEqual(subject.layer.cornerRadius, 12)
        XCTAssertEqual(subject.layer.masksToBounds, true)
        XCTAssertEqual(subject.layer.borderWidth, 1)
        XCTAssertEqual(subject.layer.borderColor, subject.appearance.colorPalette.border.cgColor)
    }

    func test_setUpAppearance_fileSizeLabelWasConfiguredCorrectly() {
        XCTAssertEqual(subject.fileSizeLabel.textColor, subject.appearance.colorPalette.subtitleText)
        XCTAssertEqual(subject.fileSizeLabel.font, subject.appearance.fonts.subheadlineBold)
    }

    func test_setUpAppearance_fileNameLabelWasConfiguredCorrectly() {
        XCTAssertEqual(subject.fileNameLabel.lineBreakMode, .byTruncatingMiddle)
        XCTAssertEqual(subject.fileNameLabel.font, subject.appearance.fonts.bodyBold)
    }

    func test_setUpAppearance_fileIconImageViewWasConfiguredCorrectly() {
        XCTAssertEqual(subject.fileIconImageView.contentMode, .center)
        XCTAssertEqual(subject.fileIconImageView.image, subject.appearance.images.fileAac)
    }

    func test_setUpAppearance_durationLabelWasConfiguredCorrectly() {
        XCTAssertEqual(subject.durationLabel.textColor, subject.appearance.colorPalette.textLowEmphasis)
        XCTAssertEqual(subject.durationLabel.font, .monospacedDigitSystemFont(
            ofSize: subject.appearance.fonts.caption1.pointSize, weight: .medium
        ))
    }

    func test_setUpAppearance_playbackRateButtonWasConfiguredCorrectly() {
        XCTAssertEqual(subject.playbackRateButton.titleColor(for: .normal), subject.appearance.colorPalette.staticBlackColorText)
        XCTAssertEqual(subject.playbackRateButton.titleLabel?.font, subject.appearance.fonts.footnote)
    }

    // MARK: - updateContent

    func test_updateContent_contentIsNil_fileNameLabelWasConfiguredCorrectly() {
        subject.content = nil

        XCTAssertNil(subject.fileNameLabel.text)
    }

    func test_updateContent_contentIsNotNil_indexProviderIsNil_fileNameLabelWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique())
        subject.updateContent()

        XCTAssertEqual(subject.fileNameLabel.text, "Recording")
    }

    func test_updateContent_contentIsNotNil_indexProviderIsNotNil_fileNameLabelWasConfiguredCorrectly() {
        subject.indexProvider = { 4 }
        subject.content = .mock(id: .unique, assetURL: .unique())
        subject.updateContent()

        XCTAssertEqual(subject.fileNameLabel.text, "Recording(4)")
    }

    func test_updateContent_contentIsNil_fileSizeLabelWasConfiguredCorrectly() {
        subject.content = nil
        subject.updateContent()

        XCTAssertNil(subject.fileSizeLabel.text)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsUploaded_fileSizeLabelWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploaded)
        subject.updateContent()

        XCTAssertEqual(subject.fileSizeLabel.text, "120 bytes")
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsUploadingFailed_fileSizeLabelWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploadingFailed)
        subject.updateContent()

        XCTAssertEqual(subject.fileSizeLabel.text, "UPLOADING FAILED")
    }

    func test_updateContent_contentIsNotNil_fileSizeLabelWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .pendingUpload)
        subject.updateContent()

        XCTAssertEqual(subject.fileSizeLabel.text, "0/120 bytes")
    }

    func test_updateContent_contentIsNil_loadingIndicatorWasConfiguredCorrectly() {
        subject.content = nil
        subject.updateContent()

        XCTAssertFalse(subject.loadingIndicator.isVisible)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsPendingUpload_loadingIndicatorWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .pendingUpload)
        subject.updateContent()

        XCTAssertTrue(subject.loadingIndicator.isVisible)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsUploading_loadingIndicatorWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploading(progress: 10))
        subject.updateContent()

        XCTAssertTrue(subject.loadingIndicator.isVisible)
    }

    func test_updateContent_contentIsNotNil_loadingIndicatorWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploaded)
        subject.updateContent()

        XCTAssertFalse(subject.loadingIndicator.isVisible)
    }

    func test_updateContent_contentIsNil_playbackComponentsWereConfiguredCorrectly() {
        subject.content = nil
        subject.updateContent()

        XCTAssertTrue(subject.playPauseButton.isHidden)
        XCTAssertTrue(subject.durationLabel.isHidden)
        XCTAssertTrue(subject.playbackRateButton.isHidden)
        XCTAssertTrue(subject.waveformView.isHidden)
        XCTAssertTrue(subject.playbackLoadingClampedView.isHidden)
        XCTAssertFalse(subject.fileSizeLabel.isHidden)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsUploaded_playbackComponentsWereConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploaded)
        subject.updateContent()

        XCTAssertFalse(subject.playPauseButton.isHidden)
        XCTAssertFalse(subject.durationLabel.isHidden)
        XCTAssertFalse(subject.waveformView.isHidden)
        XCTAssertFalse(subject.playbackLoadingClampedView.isHidden)
        XCTAssertTrue(subject.fileSizeLabel.isHidden)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsNil_playbackComponentsWereConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: nil)
        subject.updateContent()

        XCTAssertFalse(subject.playPauseButton.isHidden)
        XCTAssertFalse(subject.durationLabel.isHidden)
        XCTAssertFalse(subject.waveformView.isHidden)
        XCTAssertFalse(subject.playbackLoadingClampedView.isHidden)
        XCTAssertTrue(subject.fileSizeLabel.isHidden)
    }

    func test_updateContent_contentIsNotNil_playbackComponentsWereConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .pendingUpload)
        subject.updateContent()

        XCTAssertTrue(subject.playPauseButton.isHidden)
        XCTAssertTrue(subject.durationLabel.isHidden)
        XCTAssertTrue(subject.playbackRateButton.isHidden)
        XCTAssertTrue(subject.waveformView.isHidden)
        XCTAssertTrue(subject.playbackLoadingClampedView.isHidden)
        XCTAssertFalse(subject.fileSizeLabel.isHidden)
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsUploaded_waveformWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploaded, duration: 90, waveformData: [1, 2])
        subject.updateContent()

        XCTAssertEqual(subject.waveformView.content, .init(
            isRecording: false,
            duration: 90,
            currentTime: 0,
            waveform: [1, 2]
        ))
    }

    func test_updateContent_contentIsNotNil_uploadingStateIsNil_waveformWasConfiguredCorrectly() {
        subject.content = .mock(id: .unique, assetURL: .unique(), localState: .uploaded, duration: 90, waveformData: [1, 2])
        subject.updateContent()

        XCTAssertEqual(subject.waveformView.content, .init(
            isRecording: false,
            duration: 90,
            currentTime: 0,
            waveform: [1, 2]
        ))
    }

    // MARK: - updatePlayPauseButton

    func test_updatePlayPauseButton_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updatePlayPauseButton(for: state)

            XCTAssertEqual(subject.playPauseButton.image(for: .normal), subject.appearance.images.playFill, file: file, line: line)
            switch state {
            case .notLoaded, .loading:
                XCTAssertFalse(subject.playPauseButton.isSelected, file: file, line: line)
                XCTAssertEqual(subject.playPauseButton.image(for: .selected), subject.appearance.images.playFill, file: file, line: line)
            case .paused, .playing, .stopped:
                XCTAssertEqual(subject.playPauseButton.image(for: .selected), subject.appearance.images.pauseFill, file: file, line: line)
                XCTAssertEqual(subject.playPauseButton.isSelected, state == .playing, file: file, line: line)
            default:
                break
            }
        }

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }

    // MARK: - updatePlaybackLoadingIndicator

    func test_updatePlaybackLoadingIndicator_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updatePlaybackLoadingIndicator(for: state)

            switch state {
            case .loading:
                XCTAssertFalse(subject.playbackLoadingIndicator.isHidden, file: file, line: line)
            default:
                XCTAssertTrue(subject.playbackLoadingIndicator.isHidden, file: file, line: line)
            }
        }

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }

    // MARK: - updateDurationLabel

    func test_updateDurationLabel_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updateDurationLabel(for: state, duration: 100, currentTime: 50)

            switch state {
            case .notLoaded, .loading:
                XCTAssertFalse(subject.durationLabel.isHidden, file: file, line: line)
                XCTAssertEqual(subject.durationLabel.text, "01:40", file: file, line: line)
            case .stopped:
                XCTAssertFalse(subject.durationLabel.isHidden, file: file, line: line)
                XCTAssertEqual(subject.durationLabel.text, "01:40", file: file, line: line)
            case .paused, .playing, .stopped:
                XCTAssertFalse(subject.durationLabel.isHidden, file: file, line: line)
                XCTAssertEqual(subject.durationLabel.text, "00:50", file: file, line: line)
            default:
                break
            }
        }

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }

    // MARK: - updateWaveformView

    func test_updateWaveformView_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updateWaveformView(for: state, duration: 100, currentTime: 50)

            XCTAssertEqual(subject.waveformView.content, .init(
                isRecording: false,
                duration: 100,
                currentTime: 50,
                waveform: [0, 1, 2]
            ), file: file, line: line)
        }

        subject.waveformView.content = .init(
            isRecording: false,
            duration: 0,
            currentTime: 0,
            waveform: [0, 1, 2]
        )

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }

    // MARK: - updateFileIconImageView
    
    func test_updateFileIconImageView_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updateFileIconImageView(for: state)

            switch state {
            case .notLoaded, .loading, .stopped:
                XCTAssertFalse(subject.fileIconImageView.isHidden, file: file, line: line)
            case .paused, .playing:
                XCTAssertTrue(subject.fileIconImageView.isHidden, file: file, line: line)
            default:
                break
            }
        }

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }

    // MARK: - updatePlaybackRateButton

    func test_updatePlaybackRateButton_playPauseButtonWasConfiguredCorrectly() {
        func assertView(_ state: AudioPlaybackState, file: StaticString = #file, line: UInt = #line) {
            subject.updatePlaybackRateButton(for: state, value: 1.5)

            switch state {
            case .notLoaded, .loading, .stopped:
                XCTAssertTrue(subject.playbackRateButton.isHidden, file: file, line: line)
                XCTAssertNil(subject.playbackRateButton.title(for: .normal), file: file, line: line)
            case .paused, .playing:
                XCTAssertFalse(subject.playbackRateButton.isHidden, file: file, line: line)
                XCTAssertEqual(subject.playbackRateButton.title(for: .normal), "x1.5", file: file, line: line)
            default:
                break
            }
        }

        assertView(.notLoaded)
        assertView(.loading)
        assertView(.paused)
        assertView(.playing)
        assertView(.stopped)
    }
}

private final class SpyChatMessageVoiceRecordingAttachmentListViewItemViewViewPresenter: ChatMessageVoiceRecordingAttachmentListView.ItemViewPresenter {
    private(set) var setUpWasCalled: Bool = false

    // MARK: - setUp

    override func setUp() {
        setUpWasCalled = true
        super.setUp()
    }
}
