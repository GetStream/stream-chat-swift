//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageThreadArrowView = _ChatMessageThreadArrowView<NoExtraData>

open class _ChatMessageThreadArrowView<ExtraData: ExtraDataTypes>: View, UIConfigProvider {
    public enum Direction {
        case toTrailing
        case toLeading
    }

    override public class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    public var shape: CAShapeLayer {
        layer as! CAShapeLayer
    }

    public var direction: Direction = .toTrailing {
        didSet {
            setNeedsDisplay()
        }
    }

    override public func defaultAppearance() {
        shape.contentsScale = layer.contentsScale
        shape.strokeColor = uiConfig.colorPalette.border.cgColor
        shape.fillColor = nil
        shape.lineWidth = 1.0
    }

    public var isLeftToRight: Bool {
        let isLeftToRightWithTrailing = direction == .toTrailing && traitCollection.layoutDirection == .leftToRight
        let isRightToLeftWithLeading = direction == .toLeading && traitCollection.layoutDirection == .rightToLeft
        return isLeftToRightWithTrailing || isRightToLeftWithLeading
    }

    override open func draw(_ rect: CGRect) {
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

public typealias ChatMessageThreadInfoView = _ChatMessageThreadInfoView<NoExtraData>

open class _ChatMessageThreadInfoView<ExtraData: ExtraDataTypes>: Control, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }

    public private(set) lazy var avatarView = uiConfig
        .messageList
        .messageContentSubviews
        .threadParticipantAvatarView.init()
        .withoutAutoresizingMaskConstraints
    
    public private(set) lazy var replyCountLabel: UILabel = {
        let label = UILabel().withoutAutoresizingMaskConstraints
        label.font = uiConfig.font.subheadlineBold
        label.adjustsFontForContentSizeCategory = true
        label.text = L10n.Message.Threads.reply
        label.textColor = tintColor
        return label
    }()

    public private(set) lazy var stack: UIStackView = {
        let stack = UIStackView(arrangedSubviews: [avatarView, replyCountLabel]).withoutAutoresizingMaskConstraints
        stack.distribution = .fill
        stack.alignment = .center
        stack.axis = .horizontal
        stack.spacing = UIStackView.spacingUseSystem
        stack.isUserInteractionEnabled = false
        return stack
    }()

    // MARK: - Overrides

    override open var isHighlighted: Bool {
        didSet { updateAppearance() }
    }

    override open func tintColorDidChange() {
        super.tintColorDidChange()
        updateAppearance()
    }

    override open func setUpLayout() {
        super.setUpLayout()
        embed(stack)
        avatarView.widthAnchor.pin(equalToConstant: 16).isActive = true
        avatarView.heightAnchor.pin(equalToConstant: 16).with(priority: .defaultHigh).isActive = true
        replyCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        replyCountLabel.setContentCompressionResistancePriority(.required, for: .vertical)
    }

    override open func updateContent() {
        super.updateContent()
        if message?.parentMessageId == nil {
            updateForThreadStart()
        } else {
            updateForThreadReply()
        }
        updateAppearance()
    }

    // MARK: - State configurations

    open func updateAppearance() {
        if isHighlighted {
            replyCountLabel.textColor = uiConfig.colorPalette.highlightedColorForColor(tintColor)
        } else {
            replyCountLabel.textColor = tintColor
        }
    }

    open func updateForThreadStart() {
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

    open func updateForThreadReply() {
        avatarView.isHidden = true
        avatarView.imageView.image = nil
        replyCountLabel.text = L10n.Message.Threads.reply
    }
}
