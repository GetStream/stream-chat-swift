//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatThreadArrowView: _View, AppearanceProvider {
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

    private var isLeftToRight: Bool {
        let isLeftToRightWithTrailing = direction == .toTrailing && traitCollection.layoutDirection == .leftToRight
        let isRightToLeftWithLeading = direction == .toLeading && traitCollection.layoutDirection == .rightToLeft
        return isLeftToRightWithTrailing || isRightToLeftWithLeading
    }

    public var direction: Direction = .toTrailing {
        didSet {
            setNeedsDisplay()
        }
    }

    override open func setUpAppearance() {
        super.setUpAppearance()

        shape.contentsScale = layer.contentsScale
        shape.strokeColor = appearance.colorPalette.border.cgColor
        shape.fillColor = nil
        shape.lineWidth = 1
    }

    override open func draw(_ rect: CGRect) {
        let corner: CGFloat = 16
        let height = bounds.height / 2
        let lineCenter = shape.lineWidth / 2

        let startX = isLeftToRight ? lineCenter : (bounds.width - lineCenter)
        let endX = isLeftToRight ? corner : (bounds.width - corner)

        let path = CGMutablePath()
        path.move(to: CGPoint(x: startX, y: -3 * height))
        path.addLine(to: CGPoint(x: startX, y: height - corner))
        path.addQuadCurve(
            to: CGPoint(x: endX, y: height),
            control: CGPoint(x: startX, y: height)
        )
        shape.path = path
        super.draw(rect)
    }
}
