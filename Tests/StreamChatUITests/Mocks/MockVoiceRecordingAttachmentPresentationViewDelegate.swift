//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import StreamChatUI

final class MockVoiceRecordingAttachmentPresentationViewDelegate: VoiceRecordingAttachmentPresentationViewDelegate {
    private(set) var voiceRecordingAttachmentPresentationViewConnectWasCalledWithDelegate: AudioPlayingDelegate?
    var onConnectCallWithContextAndPlayer: (AudioPlaying, AudioPlaybackContext)?

    private(set) var voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment: ChatMessageVoiceRecordingAttachment?

    private(set) var voiceRecordingAttachmentPresentationViewPausePaybackWasCalled = false

    private(set) var voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalledWithAudioPlaybackRate: AudioPlaybackRate?

    private(set) var voiceRecordingAttachmentPresentationViewSeekWasCalledWithTimeInterval: TimeInterval?

    init() {}

    func voiceRecordingAttachmentPresentationViewConnect(
        delegate: AudioPlayingDelegate
    ) {
        voiceRecordingAttachmentPresentationViewConnectWasCalledWithDelegate = delegate
        onConnectCallWithContextAndPlayer.map { delegate.audioPlayer($0.0, didUpdateContext: $0.1) }
    }

    func voiceRecordingAttachmentPresentationViewBeginPayback(
        _ attachment: ChatMessageVoiceRecordingAttachment
    ) {
        voiceRecordingAttachmentPresentationViewBeginPaybackWasCalledWithAttachment = attachment
    }

    func voiceRecordingAttachmentPresentationViewPausePayback() {
        voiceRecordingAttachmentPresentationViewPausePaybackWasCalled = true
    }

    func voiceRecordingAttachmentPresentationViewUpdatePlaybackRate(
        _ audioPlaybackRate: AudioPlaybackRate
    ) {
        voiceRecordingAttachmentPresentationViewUpdatePlaybackRateWasCalledWithAudioPlaybackRate = audioPlaybackRate
    }

    func voiceRecordingAttachmentPresentationViewSeek(
        to timeInterval: TimeInterval
    ) {
        voiceRecordingAttachmentPresentationViewSeekWasCalledWithTimeInterval = timeInterval
    }

    func messageContentViewDidTapOnErrorIndicator(_ indexPath: IndexPath?) {}

    func messageContentViewDidTapOnThread(_ indexPath: IndexPath?) {}

    func messageContentViewDidTapOnQuotedMessage(_ quotedMessage: ChatMessage) {}

    func messageContentViewDidTapOnAvatarView(_ indexPath: IndexPath?) {}

    func messageContentViewDidTapOnReactionsView(_ indexPath: IndexPath?) {}
}
