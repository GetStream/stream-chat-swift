//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

final class MessengerChatMessageContentView: ChatMessageContentView {
    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var avatarView: ChatAvatarView = {
        let view = ChatAvatarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var messageBubbleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 0
        return label
    }()

    private lazy var leadingSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var trailingSpacer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var bubbleRow: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [leadingSpacer, avatarView, messageBubbleView, trailingSpacer])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.alignment = .bottom
        stack.spacing = 8
        return stack
    }()

    private lazy var outerStack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [dateLabel, bubbleRow])
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .vertical
        stack.spacing = 4
        return stack
    }()

    override func layout(options: ChatMessageLayoutOptions) {
        messageBubbleView.layer.cornerRadius = 18
        messageBubbleView.addSubview(messageLabel)
        NSLayoutConstraint.activate([
            messageLabel.topAnchor.constraint(equalTo: messageBubbleView.topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: messageBubbleView.bottomAnchor, constant: -8),
            messageLabel.leadingAnchor.constraint(equalTo: messageBubbleView.leadingAnchor, constant: 12),
            messageLabel.trailingAnchor.constraint(equalTo: messageBubbleView.trailingAnchor, constant: -12)
        ])

        NSLayoutConstraint.activate([
            avatarView.widthAnchor.constraint(equalToConstant: 30),
            avatarView.heightAnchor.constraint(equalToConstant: 30)
        ])

        addSubview(outerStack)
        NSLayoutConstraint.activate([
            outerStack.topAnchor.constraint(equalTo: topAnchor),
            outerStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            outerStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            outerStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }

    override func updateContent() {
        guard let message = content else { return }

        dateLabel.text = dateFormatter.string(from: message.createdAt)
        dateLabel.font = appearance.fonts.subheadline
        dateLabel.textColor = appearance.colorPalette.subtitleText
        dateLabel.textAlignment = .center

        messageLabel.text = message.text
        messageLabel.font = appearance.fonts.body

        if message.isSentByCurrentUser {
            messageBubbleView.backgroundColor = appearance.colorPalette.background2
            messageLabel.textColor = appearance.colorPalette.text
            leadingSpacer.isHidden = false
            trailingSpacer.isHidden = true
            avatarView.isHidden = true
        } else {
            messageBubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            leadingSpacer.isHidden = true
            trailingSpacer.isHidden = false
            avatarView.isHidden = false
        }

        let placeholder = appearance.images.userAvatarPlaceholder1
        if let imageURL = message.author.imageURL {
            components.imageLoader.loadImage(
                into: avatarView.imageView,
                from: imageURL,
                with: ImageLoaderOptions(
                    resize: .init(components.avatarThumbnailSize),
                    placeholder: placeholder
                )
            )
        } else {
            avatarView.imageView.image = placeholder
        }
    }
}
