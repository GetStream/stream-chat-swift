//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class DemoChatMessageListVC: ChatMessageListVC {
    private static let premiumTypingColor = UIColor(red: 1, green: 0.84, blue: 0, alpha: 1)

    override func showTypingIndicator(typingUsers: [TypingUser]) {
        super.showTypingIndicator(typingUsers: typingUsers)
        applyPremiumTypingAppearance(typingUsers: typingUsers)
    }

    override func hideTypingIndicator() {
        super.hideTypingIndicator()
        applyPremiumTypingAppearance(typingUsers: [])
    }

    private func applyPremiumTypingAppearance(typingUsers: [TypingUser]) {
        let isPremium = AppConfig.shared.demoAppConfig.shouldShowPremiumBadge
            && typingUsers.contains { $0.memberInfo?.isPremium == true }
        let color = isPremium ? Self.premiumTypingColor : appearance.colorPalette.chatTextTypingIndicator
        typingIndicatorView.informationLabel.textColor = color
        typingIndicatorView.typingAnimationView.dotLayer.backgroundColor = color.cgColor
    }
}
