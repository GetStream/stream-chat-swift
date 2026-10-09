//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

/// A send button that shows a clock, for composers whose action is scheduling the message.
final class DemoScheduleSendButton: SendButton {
    override func setUpAppearance() {
        super.setUpAppearance()

        let configuration = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        let icon = UIImage(systemName: "clock", withConfiguration: configuration)
        setImage(
            icon?.withTintColor(appearance.colorPalette.accentPrimary, renderingMode: .alwaysOriginal),
            for: .normal
        )
        setImage(
            icon?.withTintColor(appearance.colorPalette.inputSendIconDisabled, renderingMode: .alwaysOriginal),
            for: .disabled
        )
    }

    override func isEnabledChangeAnimation(_ isEnabled: Bool) {}
}
