//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageThreadArrowView = _ChatMessageThreadArrowView<NoExtraData>

internal class _ChatMessageThreadArrowView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal enum Direction {
        case toTrailing
        case toLeading
    }

    override internal class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    internal var shape: CAShapeLayer {
        layer as! CAShapeLayer
    }

    internal var direction: Direction = .toTrailing {
        didSet {
            setNeedsDisplay()
        }
    }

    override internal func defaultAppearance() {
        shape.contentsScale = layer.contentsScale
        shape.strokeColor = uiConfig.colorPalette.border.cgColor
        shape.fillColor = nil
        shape.lineWidth = 1.0
    }

    internal var isLeftToRight: Bool {
        let isLeftToRightWithTrailing = direction == .toTrailing && traitCollection.layoutDirection == .leftToRight
        let isRightToLeftWithLeading = direction == .toLeading && traitCollection.layoutDirection == .rightToLeft
        return isLeftToRightWithTrailing || isRightToLeftWithLeading
    }

    override internal func draw(_ rect: CGRect) {
        let corner: CGFloat = 16
        let height = bounds.height
        let lineCenter = shape.lineWidth / 2

        let startX = isLeftToRight ? lineCenter : (bounds.width - lineCenter)
        let endX = isLeftToRight ? corner : (bounds.width - corner)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: 0))
        path.addLine(to: CGPoint(x: startX, y: height - corner))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: height),
            control: CGPoint(x: startX, y: height)
        )
        shape.path = path
        super.draw(rect)
    }
}

internal typealias ChatMessageThreadInfoView = _ChatMessageThreadInfoView<NoExtraData>

internal class _ChatMessageThreadInfoView<ExtraData: ExtraDataTypes>: _Control, UIConfigProvider {
    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    internal private(set) lazy var avatarView = uiConfig
        .messageList
        .messageContentSubviews
        .threadParticipantAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    internal private(set) lazy var replyCountLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = uiConfig.fonts.subheadlineBold
        label.adjustsFontForContentSizeCategory = true
        label.text = L10n.Message.Threads.reply
        label.textColor = tintColor
        return label.withBidirectionalLanguagesSupport
    }()

    internal private(set) lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [avatarView, replyCountLabel]).withoutAutoresizingMaskConstraints
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        stack.isUserInteractionEnabled = false
        return stack
    }()

    // MARK: - Overrides

    override internal var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    override internal func tintColorDidChange() {
        super.tintColorDidChange()
        updateAppearance()
    }

    override internal func setUpLayout() {
        super.setUpLayout()
        embed(stack)
        avatarView.widthAnchor.pin(equalToConstant: 16).isActive = true
        avatarView.heightAnchor.pin(equalToConstant: 16).with(priority: .defaultHigh).isActive = true
        replyCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        replyCountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override internal func updateContent() {
        super.updateContent()
        if message?.parentMessageId == nil {
            updateForThreadStart()
        } else {
            updateForThreadReply()
        }
        updateAppearance()
    }

    // MARK: - State configurations

    internal func updateAppearance() {
        if isHighlighted {
            replyCountLabel.textColor = uiConfig.colorPalette.highlightedColorForColor(tintColor)
        } else {
            replyCountLabel.textColor = tintColor
        }
    }

    internal func updateForThreadStart() {
        if let latestReplyAuthorAvatar = message?.latestReplies.first?.author.imageURL {
            avatarView.isHidden = false
            avatarView.imageView.loadImage(from: latestReplyAuthorAvatar)
        } else {
            avatarView.isHidden = true
            avatarView.imageView.image = nil
        }
        if let replyCount = message?.replyCount {
            replyCountLabel.text = L10n.Message.Threads.count(replyCount)
        } else {
            replyCountLabel.text = L10n.Message.Threads.reply
        }
    }

    internal func updateForThreadReply() {
        avatarView.isHidden = true
        avatarView.imageView.image = nil
        replyCountLabel.text = L10n.Message.Threads.reply
    }
}
