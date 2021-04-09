//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageReactionsView = _ChatMessageReactionsView<NoExtraData>

class _ReactionsCompactView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    var content: _ChatMessage<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override func setUpLayout() {
        addSubview(stackView)
        directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        stackView.pin(to: layoutMarginsGuide)
    }

    override func defaultAppearance() {
        layer.contentsScale = layer.contentsScale
        layer.borderWidth = 1
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 2
    }
    
    override func updateContent() {
        backgroundColor = content.map {
            $0.isSentByCurrentUser ?
                uiConfig.colorPalette.popoverBackground :
                uiConfig.colorPalette.background2
        }

        layer.borderColor = content.map {
            $0.isSentByCurrentUser ?
                uiConfig.colorPalette.border.cgColor :
                uiConfig.colorPalette.background2.cgColor
        }

        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        reactions.forEach { reaction in
            let itemView = uiConfig.messageList.messageReactions.reactionItemView.init()
            itemView.content = .init(
                useBigIcon: false,
                reaction: reaction,
                onTap: nil
            )
            stackView.addArrangedSubview(itemView)
        }
    }

    private var reactions: [ChatMessageReactionData] {
        guard let message = content else { return [] }

        let userReactionIDs = Set(message.currentUserReactions.map(\.type))

        return message
            .reactionScores
            .keys
            .sorted { $0.rawValue < $1.rawValue }
            .map { .init(type: $0, isChosenByCurrentUser: userReactionIDs.contains($0)) }
    }
}

open class _ChatMessageReactionsView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    // MARK: - Subviews

    public private(set) lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = UIStackView.spacingUseSystem
        return stack.withoutAutoresizingMaskConstraints
    }()

    // MARK: - Overrides

    override open func setUpLayout() {
        embed(stackView)
    }

    override open func updateContent() {
        stackView.arrangedSubviews.forEach {
            $0.removeFromSuperview()
        }

        guard let content = content else { return }

        content.reactions.forEach { reaction in
            let itemView = uiConfig.messageList.messageReactions.reactionItemView.init()
            itemView.content = .init(
                useBigIcon: content.useBigIcons,
                reaction: reaction,
                onTap: content.didTapOnReaction
            )
            stackView.addArrangedSubview(itemView)
        }
    }
}

// MARK: - Content

extension _ChatMessageReactionsView {
    public struct Content {
        public let useBigIcons: Bool
        public let reactions: [ChatMessageReactionData]
        public let didTapOnReaction: (MessageReactionType) -> Void

        public init(
            useBigIcons: Bool,
            reactions: [ChatMessageReactionData],
            didTapOnReaction: @escaping (MessageReactionType) -> Void
        ) {
            self.useBigIcons = useBigIcons
            self.reactions = reactions
            self.didTapOnReaction = didTapOnReaction
        }
    }
}
