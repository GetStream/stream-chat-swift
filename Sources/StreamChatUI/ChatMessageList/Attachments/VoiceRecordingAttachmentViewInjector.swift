//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate that will be assigned on an AudioView and will be responsible to handle user interactions
/// from the view.
public protocol VoiceRecordingAttachmentPresentationViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on the play button.
    func voiceRecordingAttachmentPresentationViewConnect(
        delegate: AudioPlayingDelegate
    )

    /// Called when the user taps on the play button.
    func voiceRecordingAttachmentPresentationViewBeginPayback(
        _ attachment: ChatMessageVoiceRecordingAttachment
    )

    /// Called when the user taps on the pause button.
    func voiceRecordingAttachmentPresentationViewPausePayback()

    /// Called when the user taps on the playback rate button.
    func voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(
        _ audioPlaybackRate: AudioPlaybackRate
    )

    /// Called when the user scrubs the progress view.
    func voiceRecordingAttachmentPresentationViewSeek(to timeInterval: TimeInterval)
}

public class VoiceRecordingAttachmentViewInjector: AttachmentViewInjector {
    open lazy var voiceRecordingAttachmentView: ChatMessageVoiceRecordingAttachmentListView = {
        let attachmentListView = contentView
            .components
            .voiceRecordingAttachmentListView
            .init()

        attachmentListView.playbackDelegate = contentView.delegate as? VoiceRecordingAttachmentPresentationViewDelegate

        return attachmentListView.withoutAutoresizingMaskConstraints
    }()

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        contentView.bubbleContentContainer.insertArrangedSubview(voiceRecordingAttachmentView, at: 0, respectsLayoutMargins: false)
    }

    override open func contentViewDidUpdateContent() {
        voiceRecordingAttachmentView.content = voiceRecordingAttachments
    }
}

private extension VoiceRecordingAttachmentViewInjector {
    var voiceRecordingAttachments: [ChatMessageVoiceRecordingAttachment] {
        contentView.content?.voiceRecordingAttachments ?? []
    }
}
