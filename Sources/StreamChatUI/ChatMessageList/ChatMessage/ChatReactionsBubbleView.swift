//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ChatReactionBubbleBaseView: _View, AppearanceProvider {
    open var tailDirection: ChatThreadArrowView.Direction? {
        didSet { updateContentIfNeeded() }
    }
}

open class ChatReactionsBubbleView: ChatReactionBubbleBaseView {
    public let tailHeight: CGFloat = 6

    override open func setUpAppearance() {
        super.setUpAppearance()

        backgroundColor = .clear
    }

    override open func draw(_ rect: CGRect) {
        super.draw(rect)

        strokeColor?.setStroke()
        fillColor?.setFill()

        let bubbleAndTail = bubblePath()
        bubbleAndTail.stroke()
        bubbleAndTail.fill()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        directionalLayoutMargins.bottom += tailHeight
    }

    override open func updateContent() {
        super.updateContent()

        setNeedsDisplay()
    }

    open var maskingPath: UIBezierPath {
        bubblePath(withRadiiIncreasedBy: 4)
    }
}

private extension ChatReactionsBubbleView {
    var fillColor: UIColor? {
        tailDirection.map {
            $0 == .toTrailing ?
                appearance.colorPalette.popoverBackground :
                appearance.colorPalette.background2
        }
    }

    var strokeColor: UIColor? {
        tailDirection.map {
            $0 == .toTrailing ?
                appearance.colorPalette.border :
                appearance.colorPalette.background2
        }
    }

    var bubbleBodyCenter: CGPoint {
        bounds
            .inset(by: .init(top: 0, left: 0, bottom: tailHeight, right: 0))
            .center
    }

    var bigTailCircleCenter: CGPoint {
        bubbleBodyCenter.offsetBy(
            dx: tailDirection == .toTrailing ? 10 : -10,
            dy: 14
        )
    }

    var smallTailCircleCenter: CGPoint {
        bigTailCircleCenter.offsetBy(
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
                center: bigTailCircleCenter,
                radius: 4 + dr
            )
        )

        let smallTailPath = UIBezierPath(
            ovalIn: .circleBounds(
                center: smallTailCircleCenter,
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
