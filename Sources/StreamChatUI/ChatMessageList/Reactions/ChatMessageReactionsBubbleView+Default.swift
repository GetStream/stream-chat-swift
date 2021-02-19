//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageDefaultReactionsBubbleView = _ChatMessageDefaultReactionsBubbleView<NoExtraData>

internal class _ChatMessageDefaultReactionsBubbleView<ExtraData: ExtraDataTypes>: _ChatMessageReactionsBubbleView<ExtraData> {
    // MARK: - Subviews

    private let contentViewBackground = UIView().withoutAutoresizingMaskConstraints
    private let tailBehind = UIImageView().withoutAutoresizingMaskConstraints
    private let tailInFront = UIImageView().withoutAutoresizingMaskConstraints

    override internal var tailLeadingAnchor: NSLayoutXAxisAnchor { tailBehind.leadingAnchor }
    override internal var tailTrailingAnchor: NSLayoutXAxisAnchor { tailBehind.trailingAnchor }

    // MARK: - Overrides

    override internal func layoutSubviews() {
        super.layoutSubviews()

        contentViewBackground.layer.cornerRadius = contentViewBackground.bounds.height / 2
    }

    override internal func defaultAppearance() {
        super.defaultAppearance()

        contentViewBackground.layer.borderWidth = 1
    }
    
    override internal func setUpLayout() {
        addSubview(tailBehind)
        contentViewBackground.addSubview(contentView)
        contentViewBackground.insetsLayoutMarginsFromSafeArea = false
        contentView.pin(to: contentViewBackground.layoutMarginsGuide)
        embed(contentViewBackground)
        addSubview(tailInFront)

        NSLayoutConstraint.activate([
            tailBehind.centerXAnchor.pin(equalTo: contentViewBackground.centerXAnchor).with(priority: .defaultLow),
            tailBehind.centerYAnchor.pin(equalTo: contentViewBackground.bottomAnchor),
            tailInFront.centerXAnchor.pin(equalTo: tailBehind.centerXAnchor),
            tailInFront.centerYAnchor.pin(equalTo: tailBehind.centerYAnchor)
        ])
    }

    override internal func updateContent() {
        super.updateContent()

        tailBehind.image = tailBackImage
        tailInFront.image = tailFrontImage
        contentViewBackground.backgroundColor = contentBackgroundColor
        contentViewBackground.layer.borderColor = contentBorderColor.cgColor
        contentViewBackground.directionalLayoutMargins = contentLayoutMargins
    }
}

// MARK: - Private

private extension _ChatMessageDefaultReactionsBubbleView {
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
            return uiConfig.colorPalette.popoverBackground
        case .smallIncoming:
            return uiConfig.colorPalette.background2
        }
    }

    var contentBorderColor: UIColor {
        guard let content = content else { return .clear }

        switch content.style {
        case .smallOutgoing:
            return uiConfig.colorPalette.border
        case .smallIncoming:
            return uiConfig.colorPalette.border
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
                    outlineColor: uiConfig.colorPalette.background,
                    borderColor: content.style.isIncoming ?
                        uiConfig.colorPalette.border :
                        uiConfig.colorPalette.border,
                    innerColor: content.style.isIncoming ?
                        uiConfig.colorPalette.background2 :
                        uiConfig.colorPalette.popoverBackground
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
                        uiConfig.colorPalette.background2 :
                        uiConfig.colorPalette.popoverBackground
                )
            )
        }
    }
}
