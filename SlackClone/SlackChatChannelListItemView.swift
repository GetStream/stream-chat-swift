//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class SlackChatChannelListItemView: ChatChannelListItemView {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        avatarView.layer.cornerRadius = 4
    }
    
    override func setUpLayout() {
        super.setUpLayout()
        
        let topStackView = UIStackView()
        topStackView.spacing = 14
        topStackView.alignment = .center
        topStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topStackView)
        NSLayoutConstraint.activate([
            topStackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            topStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            topStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10)
        ])
        
        NSLayoutConstraint.deactivate(layout.titleLabelConstraints)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        topStackView.addArrangedSubview(titleLabel)
        
        NSLayoutConstraint.deactivate(layout.timestampLabelConstraints)
        timestampLabel.setContentHuggingPriority(.required, for: .horizontal)
        topStackView.addArrangedSubview(timestampLabel)
        
        NSLayoutConstraint.deactivate(layout.unreadCountViewConstraints)
        NSLayoutConstraint.activate([
            unreadCountView.topAnchor.constraint(equalTo: timestampLabel.bottomAnchor),
            unreadCountView.trailingAnchor.constraint(equalTo: topStackView.trailingAnchor)
        ])
        
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 35),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 15)
        ])
        
        NSLayoutConstraint.activate([
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor)
        ])
    }
}
