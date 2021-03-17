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
        
        unreadView.translatesAutoresizingMaskIntoConstraints = false
        cellContentView.addSubview(unreadView)
        NSLayoutConstraint.activate([
            unreadView.centerYAnchor.constraint(equalTo: cellContentView.centerYAnchor),
            unreadView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: 5),
            unreadView.heightAnchor.constraint(equalToConstant: 10),
            unreadView.widthAnchor.constraint(equalTo: unreadView.heightAnchor)
        ])
        
        let timestampStackView = UIStackView()
        timestampStackView.spacing = 14
        timestampStackView.alignment = .center
        timestampStackView.translatesAutoresizingMaskIntoConstraints = false
        cellContentView.addSubview(timestampStackView)
        NSLayoutConstraint.activate([
            timestampStackView.topAnchor.constraint(equalTo: cellContentView.topAnchor, constant: 9),
            timestampStackView.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: 12),
            timestampStackView.trailingAnchor.constraint(equalTo: cellContentView.trailingAnchor, constant: -20)
        ])

        timestampStackView.addArrangedSubview(titleLabel)
        
        timestampLabel.setContentHuggingPriority(.required, for: .horizontal)
        timestampLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.deactivate(layout.timestampLabelConstraints)
        timestampStackView.addArrangedSubview(timestampLabel)
        
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
        timestampAccessoryView.setContentHuggingPriority(.required, for: .horizontal)
        timestampStackView.addArrangedSubview(timestampAccessoryView)
        NSLayoutConstraint.activate([
            timestampAccessoryView.heightAnchor.constraint(equalTo: timestampLabel.heightAnchor, constant: -6)
        ])
        
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        NSLayoutConstraint.activate([
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.trailingAnchor.constraint(equalTo: timestampAccessoryView.trailingAnchor),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            avatarView.topAnchor.constraint(equalTo: timestampStackView.topAnchor, constant: 6),
            avatarView.leadingAnchor.constraint(equalTo: cellContentView.leadingAnchor, constant: 26),
            avatarView.heightAnchor.constraint(equalToConstant: 48),
            avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor)
        ])
    }
    
    override func updateContent() {
        super.updateContent()

        unreadView.isHidden = unreadCountView.isHidden
        unreadCountView.isHidden = true

        timestampLabel.text = content.channel?.lastMessageAt?.formatRelativeString() ?? ""
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
