//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChatUI
import UIKit

final class iMessageChatChannelListItemView: ChatChannelListItemView {
    private lazy var unreadView = UIView()
    
    override func setUpAppearance() {
        super.setUpAppearance()
              
        unreadView.backgroundColor = .systemBlue
        unreadView.layer.masksToBounds = true
        unreadView.layer.cornerRadius = 5
        unreadView.clipsToBounds = true
        
        timestampLabel.font = .systemFont(ofSize: 15)
        timestampLabel.textColor = .gray
        
        subtitleLabel.numberOfLines = 2
    }
    
    override func setUpLayout() {
        super.setUpLayout()

        // Add left unread view blue dot.
        unreadView.translatesAutoresizingMaskIntoConstraints = false
        mainContainer.insertArrangedSubview(unreadView, at: 0)

        // Also we need to remove unreadCountView while we use the leading-sided unread indicator.
        topContainer.removeArrangedSubview(unreadCountView)

        // Create timestamp with chevron ContainerView.
        let timestampAccessoryView = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(
                    font: .systemFont(ofSize: 14),
                    scale: .default
                )
            )?
                .withRenderingMode(.alwaysTemplate)
        )
        timestampAccessoryView.tintColor = UIColor.gray.withAlphaComponent(0.6)
        timestampAccessoryView.translatesAutoresizingMaskIntoConstraints = false

        // Create container holding the timestamp and accessoryView.
        let timestampContainer = ContainerStackView(
            axis: .horizontal,
            alignment: .bottom,
            spacing: 14,
            arrangedSubviews: [timestampLabel, timestampAccessoryView]
        )

        topContainer.insertArrangedSubview(timestampContainer, at: 1)
        bottomContainer.alignment = .top
        mainContainer.spacing = 8

        // Activate all constraints

        NSLayoutConstraint.activate([
            // Set the constraints for avatarView
            avatarView.topAnchor.constraint(equalTo: topContainer.topAnchor, constant: 6),
            avatarView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 26),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
            // Set constraints to unreadView
            unreadView.centerYAnchor.constraint(equalTo: centerYAnchor),
            unreadView.heightAnchor.constraint(equalToConstant: 10),
            unreadView.widthAnchor.constraint(equalTo: unreadView.heightAnchor),
            // Set constraint from right to container
            mainContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8)
        ])
    }
    
    override func updateContent() {
        super.updateContent()

        avatarView.presenceAvatarView.isOnlineIndicatorVisible = false
        unreadView.isHidden = unreadCountView.content == .noUnread
        timestampLabel.text = content?.channel.lastMessageAt?.formatRelativeString() ?? ""
    }
}

private extension Date {
    func formatRelativeString() -> String {
        let dateFormatter = DateFormatter()
        let calendar = Calendar.autoupdatingCurrent
        dateFormatter.doesRelativeDateFormatting = true

        if calendar.isDateInToday(self) {
            dateFormatter.timeStyle = .short
            dateFormatter.dateStyle = .none
        } else if calendar.isDateInYesterday(self) {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .medium
        } else if calendar.compare(Date(), to: self, toGranularity: .weekOfYear) == .orderedSame {
            let weekday = calendar.dateComponents([.weekday], from: self).weekday ?? 0
            return dateFormatter.weekdaySymbols[weekday - 1]
        } else {
            dateFormatter.timeStyle = .none
            dateFormatter.dateStyle = .short
        }

        return dateFormatter.string(from: self)
    }
}
