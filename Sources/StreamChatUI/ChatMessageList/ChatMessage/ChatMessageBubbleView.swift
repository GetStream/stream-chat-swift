//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public typealias ChatMessageBubbleView = _ChatMessageBubbleView<NoExtraData>

open class _ChatMessageBubbleView<ExtraData: ExtraDataTypes>: _View, UIConfigProvider {
    public var message: _ChatMessageGroupPart<ExtraData>? {
        didSet { updateContentIfNeeded() }
    }
    
    // MARK: - Subviews

    public private(set) lazy var borderLayer = CAShapeLayer()

    // MARK: - Overrides

    override open func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
    }

    override open func setUpAppearance() {
        super.setUpAppearance()
        layer.cornerRadius = 16
        layer.masksToBounds = true
        borderLayer.contentsScale = layer.contentsScale
        borderLayer.cornerRadius = 16
        borderLayer.borderWidth = 1
    }

    override open func setUp() {
        super.setUp()
        
        layer.addSublayer(borderLayer)
    }
    
    override open func updateContent() {
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
