//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the VoiceRecording attachment in the quoted flow.
open class VoiceRecordingAttachmentQuotedPreview: VoiceRecordingAttachmentComposerPreview {
    override open func setUpLayout() {
        embed(container, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))

        container.axis = .horizontal
        container.spacing = 4

        container.addArrangedSubview(fileNameAndDurationStack)
        container.addArrangedSubview(fileIconImageView)
    }
}
