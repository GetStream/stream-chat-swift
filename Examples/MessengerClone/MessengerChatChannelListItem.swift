//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class MessengerChatChannelListItem: ChatChannelListItemView {
    private lazy var combinedSubtitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    override func setUpAppearance() {
        super.setUpAppearance()
        combinedSubtitleLabel.font = appearance.fonts.footnote
        combinedSubtitleLabel.textColor = appearance.colorPalette.subtitleText
    }

    override func setUpLayout() {
        NSLayoutConstraint.activate([
            avatarView.heightAnchor.constraint(equalToConstant: 50),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor)
        ])

        let textStack = UIStackView(arrangedSubviews: [titleLabel, combinedSubtitleLabel])
        textStack.axis = .vertical
        textStack.alignment = .leading
        textStack.spacing = 3
        textStack.translatesAutoresizingMaskIntoConstraints = false

        mainContainer.addArrangedSubviews([avatarView, textStack])
        mainContainer.alignment = .center
        mainContainer.isLayoutMarginsRelativeArrangement = true

        mainContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainContainer)
        NSLayoutConstraint.activate([
            mainContainer.topAnchor.constraint(equalTo: topAnchor),
            mainContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainContainer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override func updateContent() {
        titleLabel.text = titleText
        let subtitle = subtitleText ?? ""
        let timestamp = timestampText ?? ""
        if subtitle.isEmpty || timestamp.isEmpty {
            combinedSubtitleLabel.text = subtitle + timestamp
        } else {
            combinedSubtitleLabel.text = subtitle + " • " + timestamp
        }
        avatarView.content = (content?.channel, content?.currentUserId)
    }
}
