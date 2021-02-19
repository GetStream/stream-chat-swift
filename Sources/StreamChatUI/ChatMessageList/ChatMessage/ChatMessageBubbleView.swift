//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

internal typealias ChatMessageBubbleView = _ChatMessageBubbleView<NoExtraData>

internal class _ChatMessageBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    internal var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }
    
    // MARK: - Subviews

    internal private(set) lazy var borderLayer = CAShapeLayer()

    // MARK: - Overrides

    override internal func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
    }

    override internal func defaultAppearance() {
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.contentsScale = layer.contentsScale
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
    }

    override internal func setUp() {
        super.setUp()
        
        layer.addSublayer(borderLayer)
    }
    
    override internal func updateContent() {
        super.updateContent()
        
        borderLayer.maskedCorners = corners
        borderLayer.isHidden = message == nil
        
        borderLayer.borderColor = message?.isSentByCurrentUser == true ?
            uiConfig.colorPalette.border.cgColor :
            uiConfig.colorPalette.border.cgColor
        
        layer.maskedCorners = corners
    }
    
    // MARK: - Private

    private var corners: CACornerMask {
        var roundedCorners: CACornerMask = [
            .layerMinXMinYCorner,
            .layerMinXMaxYCorner,
            .layerMaxXMinYCorner,
            .layerMaxXMaxYCorner
        ]

        guard message?.isPartOfThread == false else { return roundedCorners }

        switch (message?.isLastInGroup, message?.isSentByCurrentUser) {
        case (true, true):
            roundedCorners.remove(.layerMaxXMaxYCorner)
        case (true, false):
            roundedCorners.remove(.layerMinXMaxYCorner)
        default:
            break
        }
        
        return roundedCorners
    }
}
