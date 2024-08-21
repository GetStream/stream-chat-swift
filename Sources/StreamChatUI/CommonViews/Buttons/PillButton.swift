//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A button that is being used to show a PillButton during the playback flow of a VoiceRecording.
open class PillButton: MediaButton {
    // MARK: - UI Lifecycle

    override open func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
        layer.shadowOpacity = 0.25
        layer.shadowRadius = 2
        layer.shadowOffset = .init(width: 0, height: 2)
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        titleEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 4)
    }
}
