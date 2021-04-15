//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageReactionsView = _ChatMessageReactionsView<NoExtraData>

class ReactionsBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    private let tailHeight: CGFloat = 6

    var tailDirection: _ChatMessageThreadArrowView<ExtraData>.Direction? {
        didSet {
            updateContentIfNeeded()
        }
    }

    override func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        strokeColor?.setStroke()
        fillColor?.setFill()

        let bubbleAndTail = bubblePath()
        bubbleAndTail.stroke()
        bubbleAndTail.fill()
    }

    override func setUpLayout() {
        directionalLayoutMargins.bottom += tailHeight
    }

    override func updateContent() {
        setNeedsDisplay()
    }

    var maskingPath: UIBezierPath {
        bubblePath(withRadiiIncreasedBy: 4)
    }
}

private extension ReactionsBubbleView {
    var fillColor: UIColor? {
        tailDirection.map {
            $0 == .toTrailing ?
                uiConfig.colorPalette.popoverBackground :
                uiConfig.colorPalette.background2
        }
    }

    var strokeColor: UIColor? {
        tailDirection.map {
            $0 == .toTrailing ?
                uiConfig.colorPalette.border :
                uiConfig.colorPalette.background2
        }
    }

    var bubbleBodyCenter: CGPoint {
        bounds
            .inset(by: .init(top: 0, left: 0, bottom: tailHeight, right: 0))
            .center
    }

    var bigTailCirleCenter: CGPoint {
        bubbleBodyCenter.offsetBy(
            dx: tailDirection == .toTrailing ? 10 : -10,
            dy: 14
        )
    }

    var smallTailCirleCenter: CGPoint {
        bigTailCirleCenter.offsetBy(
            dx: tailDirection == .toTrailing ? 4 : -4,
            dy: 6
        )
    }

    func bubblePath(withRadiiIncreasedBy dr: CGFloat = 0) -> UIBezierPath {
        let borderLineWidth: CGFloat = 1
        let dr = dr - borderLineWidth / 2

        let bubbleBodyRect = CGRect(
            center: bubbleBodyCenter,
            size: .init(
                width: bounds.width + dr,
                height: bounds.height - tailHeight + dr
            )
        )

        let bubbleBodyPath = UIBezierPath(
            roundedRect: bubbleBodyRect,
            cornerRadius: bubbleBodyRect.height / 2
        )

        let bigTailPath = UIBezierPath(
            ovalIn: .circleBounds(
                center: bigTailCirleCenter,
                radius: 4 + dr
            )
        )

        let smallTailPath = UIBezierPath(
            ovalIn: .circleBounds(
                center: smallTailCirleCenter,
                radius: 2 + dr
            )
        )

        let path = UIBezierPath()
        path.lineWidth = borderLineWidth
        path.append(bubbleBodyPath)
        path.append(bigTailPath)
        path.append(smallTailPath)
        return path
    }
}

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
        embed(stackView)
    }
    
    override func updateContent() {
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
            itemView.setContentCompressionResistancePriority(.required, for: .horizontal)
            itemView.setContentCompressionResistancePriority(.required, for: .vertical)
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
