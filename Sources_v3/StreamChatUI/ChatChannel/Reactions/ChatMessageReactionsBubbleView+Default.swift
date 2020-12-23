//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatMessageDefaultReactionsBubbleView<ExtraData: ExtraDataTypes>: ChatMessageReactionsBubbleView<ExtraData> {

    // MARK: - Subviews

    private let contentViewBackground = UIView().withoutAutoresizingMaskConstraints
    private let tailBehind = UIImageView().withoutAutoresizingMaskConstraints
    private let tailInFront = UIImageView().withoutAutoresizingMaskConstraints

    override open var tailLeadingAnchor: NSLayoutXAxisAnchor { tailBehind.leadingAnchor }
    override open var tailTrailingAnchor: NSLayoutXAxisAnchor { tailBehind.trailingAnchor }

    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        contentViewBackground.layer.cornerRadius = contentViewBackground.bounds.height / 2
    }

    override public func defaultAppearance() {
        super.defaultAppearance()

        contentViewBackground.layer.borderWidth = 1
    }
    
    override open func setUpLayout() {
        addSubview(tailBehind)
        contentViewBackground.addSubview(contentView)
        contentView.pin(to: contentViewBackground.layoutMarginsGuide)
        embed(contentViewBackground)
        addSubview(tailInFront)

        NSLayoutConstraint.activate([
            tailBehind.centerXAnchor.constraint(equalTo: contentViewBackground.centerXAnchor).with(priority: .defaultLow),
            tailBehind.centerYAnchor.constraint(equalTo: contentViewBackground.bottomAnchor),
            tailInFront.centerXAnchor.constraint(equalTo: tailBehind.centerXAnchor),
            tailInFront.centerYAnchor.constraint(equalTo: tailBehind.centerYAnchor)
        ])
    }

    override open func updateContent() {
        super.updateContent()

        tailBehind.image = tailBackImage
        tailInFront.image = tailFrontImage
        contentViewBackground.backgroundColor = contentBackgroundColor
        contentViewBackground.layer.borderColor = contentBorderColor.cgColor
        contentViewBackground.directionalLayoutMargins = contentLayoutMargins
    }
}

// MARK: - Private

private extension ChatMessageDefaultReactionsBubbleView {
    var contentLayoutMargins: NSDirectionalEdgeInsets {
        guard let content = content else { return .zero }

        return content.style.isBig ?
            .init(top: 8, leading: 16, bottom: 8, trailing: 16) :
            .init(top: 4, leading: 4, bottom: 4, trailing: 4)
    }
    
    var contentBackgroundColor: UIColor {
        guard let content = content else { return .clear }

        switch content.style {
        case .bigIncoming, .bigOutgoing, .smallOutgoing:
            return uiConfig.colorPalette.incomingMessageBubbleBackground
        case .smallIncoming:
            return uiConfig.colorPalette.outgoingMessageBubbleBackground
        }
    }

    var contentBorderColor: UIColor {
        guard let content = content else { return .clear }

        switch content.style {
        case .smallOutgoing:
            return uiConfig.colorPalette.incomingMessageBubbleBorder
        case .smallIncoming:
            return uiConfig.colorPalette.outgoingMessageBubbleBorder
        default:
            return contentBackgroundColor
        }
    }

    var tailBackImage: UIImage? {
        guard let content = content else { return nil }

        switch content.style {
        case .bigIncoming, .bigOutgoing:
            return .tail(
                options: .large(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: .clear,
                    borderColor: .clear,
                    innerColor: contentBorderColor
                )
            )
        case .smallIncoming, .smallOutgoing:
            return .tail(
                options: .small(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: uiConfig.colorPalette.generalBackground,
                    borderColor: content.style.isIncoming ?
                        uiConfig.colorPalette.outgoingMessageBubbleBorder :
                        uiConfig.colorPalette.incomingMessageBubbleBorder,
                    innerColor: content.style.isIncoming ?
                        uiConfig.colorPalette.outgoingMessageBubbleBackground :
                        uiConfig.colorPalette.incomingMessageBubbleBackground
                )
            )
        }
    }

    var tailFrontImage: UIImage? {
        guard let content = content else { return nil }

        switch content.style {
        case .bigIncoming, .bigOutgoing:
            return nil
        case .smallIncoming, .smallOutgoing:
            return .tail(
                options: .small(flipped: content.style.isIncoming),
                colors: .init(
                    outlineColor: .clear,
                    borderColor: .clear,
                    innerColor: content.style.isIncoming ?
                        uiConfig.colorPalette.outgoingMessageBubbleBackground :
                        uiConfig.colorPalette.incomingMessageBubbleBackground
                )
            )
        }
    }
}
