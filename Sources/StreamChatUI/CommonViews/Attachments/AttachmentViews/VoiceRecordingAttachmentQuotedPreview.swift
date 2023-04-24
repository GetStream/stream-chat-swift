//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A view that displays the file attachment.
open class VoiceRecordingAttachmentQuotedPreview: VoiceRecordingAttachmentComposerPreview {
    override open func setUpLayout() {
        embed(container, insets: .init(top: 8, leading: 8, bottom: 8, trailing: 8))

        container.axis = .horizontal
        container.spacing = 4

        container.addArrangedSubview(fileNameAndSizeStack)
        container.addArrangedSubview(fileIconImageView)
    }
}
