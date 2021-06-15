//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// Default provider that is used when AttachmentPreviewProvider is not implemented for custom attachment payload. This
/// provider always returns a new instance of `AttachmentPlaceholderView`.
public struct DefaultAttachmentPreviewProvider: AttachmentPreviewProvider {
    public func previewView<ExtraData: ExtraDataTypes>(components: _Components<ExtraData>) -> UIView {
        components.attachmentPreviewViewPlaceholder.init()
    }

    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }
}

/// Default attachment view to be used as a placeholder when attachment preview is not implemented for custom attachments.
open class AttachmentPlaceholderView: _View, AppearanceProvider {
    open private(set) lazy var borderLayer: CAShapeLayer = .init()

    override open func layoutSubviews() {
        super.layoutSubviews()

        borderLayer.frame = bounds
        borderLayer.path = UIBezierPath(roundedRect: bounds, cornerRadius: 16).cgPath
    }

    override open func setUpLayout() {
        super.setUpLayout()
        layer.addSublayer(borderLayer)
        widthAnchor.pin(equalTo: heightAnchor).isActive = true
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        borderLayer.strokeColor = appearance.colorPalette.background4.cgColor
        borderLayer.lineDashPattern = [2, 2]
        borderLayer.fillColor = nil
        borderLayer.masksToBounds = true
    }
}
