//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// The delegate that will be assigned on an AudioView and will be responsible to handle user interactions
/// from the view.
public protocol AudioAttachmentPresentationViewDelegate: ChatMessageContentViewDelegate {
    /// Called when the user taps on the play button.
    func audioAttachmentPresentationViewConnect(
        delegate: AudioPlayingDelegate
    )

    /// Called when the view is about to be presented to determine if the attachment is ready for playback
    /// or if there are unmet requirements (e.g. download the attachment before playing)
    func audioAttachmentPresentationViewPlaybackContextForAttachment(
        _ attachment: ChatMessageFileAttachment
    ) -> AudioPlaybackContext

    /// Called when the user taps on the play button.
    func audioAttachmentPresentationViewBeginPayback(
        _ attachment: ChatMessageVoiceRecordingAttachment
    )

    /// Called when the user taps on the pause button.
    func audioAttachmentPresentationViewPausePayback()

    /// Called when the user taps on the playback rate button.
    func audioAttachmentPresentationViewUpdatePlaybackRate(
        _ audioPlaybackRate: AudioPlaybackRate
    )

    /// Called when the user scrubs the progress view.
    func audioAttachmentPresentationViewSeek(to timeInterval: TimeInterval)
}

public class VoiceRecordingAttachmentViewInjector: AttachmentViewInjector {
    open lazy var voiceRecordingAttachmentView: ChatMessageVoiceRecordingAttachmentListView = {
        let attachmentListView = contentView
            .components
            .voiceRecordingAttachmentListView
            .init()

        attachmentListView.playbackDelegate = contentView.delegate as? AudioAttachmentPresentationViewDelegate

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
