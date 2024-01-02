//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

final class SlackReactionsItemView: UICollectionViewCell {
    var emojis: [String: String] = [
        "love": "❤️",
        "haha": "😂",
        "like": "👍",
        "sad": "😔",
        "wow": "🤯"
    ]

    var reaction: ChatMessageReactionData? {
        didSet {
            guard let reaction = reaction else {
                return
            }

            let emoji = emojis[reaction.type.rawValue] ?? "🙂"

            textLabel.text = "\(emoji) \(reaction.score)"
            textLabel.textColor = reaction.isChosenByCurrentUser ? .blue : .gray
        }
    }

    private let reactionHeight: CGFloat = 26

    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.boldSystemFont(ofSize: 11)
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = frame.height / 2
        backgroundColor = .lightGray.withAlphaComponent(0.5)
    }

    private func configureView() {
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            textLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            textLabel.widthAnchor.constraint(equalToConstant: 35),
            textLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
}
