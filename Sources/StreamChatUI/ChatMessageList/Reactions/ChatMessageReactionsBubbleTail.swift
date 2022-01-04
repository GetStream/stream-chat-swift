//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit

enum ChatMessageReactionsBubbleTail {
    struct Options {
        let smallRadius: CGFloat
        let bigRadius: CGFloat
        let border: CGFloat
        let outline: CGFloat
        let flipped: Bool

        static func small(flipped: Bool) -> Self {
            .init(
                smallRadius: 2,
                bigRadius: 4,
                border: 1,
                outline: 2,
                flipped: flipped
            )
        }

        static func large(flipped: Bool) -> Self {
            .init(
                smallRadius: 3,
                bigRadius: 6,
                border: 0,
                outline: 1,
                flipped: flipped
            )
        }
    }

    struct Colors {
        let outlineColor: UIColor
        let borderColor: UIColor
        let innerColor: UIColor
    }
}

extension UIImage {
    static func tail(
        options: ChatMessageReactionsBubbleTail.Options,
        colors: ChatMessageReactionsBubbleTail.Colors
    ) -> UIImage {
        UIGraphicsImageRenderer(size: options.imageSize).image {
            let ctx = $0.cgContext

            // Draw outline ellipse.
            ctx.setFillColor(colors.outlineColor.cgColor)
            ctx.fillEllipse(in: options.bigOutlineFrame)
            ctx.fillEllipse(in: options.smallOutlineFrame)

            // Draw border ellipse.
            ctx.setFillColor(colors.borderColor.cgColor)
            ctx.fillEllipse(in: options.bigBorderFrame)
            ctx.fillEllipse(in: options.smallBorderFrame)

            // Draw inner ellipse.
            ctx.setFillColor(colors.innerColor.cgColor)
            ctx.fillEllipse(in: options.bigFrame)
            ctx.fillEllipse(in: options.smallFrame)
        }
    }
}

// MARK: - Math

private extension ChatMessageReactionsBubbleTail.Options {
    var imageSize: CGSize {
        .init(
            width: outline + border + bigRadius * 2 + smallRadius + border + outline,
            height: outline + border + bigRadius * 2 + smallRadius * 2 + border + outline
        )
    }

    var bigOutlineFrame: CGRect {
        bigBorderFrame.insetBy(dx: -outline, dy: -outline)
    }

    var bigBorderFrame: CGRect {
        bigFrame.insetBy(dx: -border, dy: -border)
    }

    var bigFrame: CGRect {
        .init(
            x: flipped ?
                imageSize.width - outline - border - 2 * bigRadius :
                outline + border,
            y: outline + border,
            width: bigRadius * 2,
            height: bigRadius * 2
        )
    }

    var smallOutlineFrame: CGRect {
        smallBorderFrame.insetBy(dx: -outline, dy: -outline)
    }

    var smallBorderFrame: CGRect {
        smallFrame.insetBy(dx: -border, dy: -border)
    }

    var smallFrame: CGRect {
        .init(
            x: flipped ?
                bigFrame.minX - smallRadius :
                bigFrame.maxX - smallRadius,
            y: bigFrame.maxY,
            width: smallRadius * 2,
            height: smallRadius * 2
        )
    }
}
