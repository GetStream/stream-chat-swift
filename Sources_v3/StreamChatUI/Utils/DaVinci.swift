//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

enum DaVinci {
    private enum Numbers {
        static let smallRadius: CGFloat = 2
        static let bigRadius: CGFloat = 4
        static let border: CGFloat = 1
        static let outline: CGFloat = 2
        static let width = outline + border + bigRadius * 2 + smallRadius + border + outline
        static let height = outline + border + bigRadius * 2 + smallRadius * 2 + border + outline
        static let bigFrame = CGRect(
            x: outline + border,
            y: outline + border,
            width: bigRadius * 2,
            height: bigRadius * 2
        )
        static let smallFrame = CGRect(
            x: bigFrame.maxX - smallRadius,
            y: bigFrame.maxY,
            width: smallRadius * 2,
            height: smallRadius * 2
        )
    }

    private static var bottomCache: [Int: UIImage] = [:]
    private static var topCache: [Int: UIImage] = [:]

    /// Draw two layers of tail of same size
    /// - Parameters:
    ///   - outlineColor:
    ///   - borderColor:
    ///   - innerColor:
    ///   - flipped: `false` is small bubble on the right of big one, `true` otherwise
    static func reactionTail(
        outlineColor: UIColor,
        borderColor: UIColor,
        innerColor: UIColor,
        flipped: Bool
    ) -> (bottom: UIImage, top: UIImage) {
        var bigFrame = Numbers.bigFrame
        var smallFrame = Numbers.smallFrame
        if flipped {
            bigFrame.origin.x = Numbers.width - bigFrame.origin.x - bigFrame.size.width
            smallFrame.origin.x = Numbers.width - smallFrame.origin.x - smallFrame.size.width
        }

        let bottom: UIImage
        let bottomHash = hash(outlineColor, borderColor, flipped)
        if let img = bottomCache[bottomHash] {
            bottom = img
        } else {
            bottom = drawBottomTail(outlineColor, borderColor, bigFrame, smallFrame)
            bottomCache[bottomHash] = bottom
        }

        let top: UIImage
        let topHash = hash(innerColor, flipped)
        if let img = topCache[topHash] {
            top = img
        } else {
            top = drawTopTail(innerColor, bigFrame, smallFrame)
            topCache[topHash] = top
        }

        return (bottom, top)
    }

    /// Draw tail bubbles without borders and outlines
    /// - Parameters:
    ///   - color: fill color
    ///   - flipped: `false` is small bubble on the right of big one, `true` otherwise
    static func reactionTail(color: UIColor, flipped: Bool) -> UIImage {
        let bigRadius: CGFloat = 20 / 3.0
        let smallRadius: CGFloat = 10 / 3.0
        let width: CGFloat = bigRadius * 2 + smallRadius
        let height: CGFloat = bigRadius * 2 + smallRadius * 2

        var bigFrame = CGRect(x: 0, y: 0, width: bigRadius * 2, height: bigRadius * 2)
        var smallFrame = CGRect(x: bigFrame.maxX - smallRadius, y: bigFrame.maxY, width: smallRadius * 2, height: smallRadius * 2)
        if flipped {
            bigFrame.origin.x = width - bigFrame.origin.x - bigFrame.size.width
            smallFrame.origin.x = width - smallFrame.origin.x - smallFrame.size.width
        }

        return UIGraphicsImageRenderer(size: CGSize(width: width, height: height)).image { uiCtx in
            uiCtx.cgContext.setFillColor(color.cgColor)
            uiCtx.cgContext.fillEllipse(in: bigFrame)
            uiCtx.cgContext.fillEllipse(in: smallFrame)
        }
    }

    private static func drawBottomTail(
        _ outlineColor: UIColor,
        _ borderColor: UIColor,
        _ bigFrame: CGRect,
        _ smallFrame: CGRect
    ) -> UIImage {
        let borderInset = -Numbers.border
        let outlineInset = -Numbers.border - Numbers.outline

        return UIGraphicsImageRenderer(size: CGSize(width: Numbers.width, height: Numbers.height)).image { uiCtx in
            let ctx = uiCtx.cgContext
            ctx.setFillColor(outlineColor.cgColor)
            ctx.fillEllipse(in: bigFrame.insetBy(dx: outlineInset, dy: outlineInset))
            ctx.fillEllipse(in: smallFrame.insetBy(dx: outlineInset, dy: outlineInset))

            ctx.setFillColor(borderColor.cgColor)
            ctx.fillEllipse(in: bigFrame.insetBy(dx: borderInset, dy: borderInset))
            ctx.fillEllipse(in: smallFrame.insetBy(dx: borderInset, dy: borderInset))
        }
    }

    private static func drawTopTail(_ innerColor: UIColor, _ bigFrame: CGRect, _ smallFrame: CGRect) -> UIImage {
        UIGraphicsImageRenderer(size: CGSize(width: Numbers.width, height: Numbers.height)).image { uiCtx in
            uiCtx.cgContext.setFillColor(innerColor.cgColor)
            uiCtx.cgContext.fillEllipse(in: bigFrame)
            uiCtx.cgContext.fillEllipse(in: smallFrame)
        }
    }

    private static func hash(_ outlineColor: UIColor, _ borderColor: UIColor, _ flipped: Bool) -> Int {
        var hasher = Hasher()
        hasher.combine(outlineColor)
        hasher.combine(borderColor)
        hasher.combine(flipped)
        return hasher.finalize()
    }

    private static func hash(_ innerColor: UIColor, _ flipped: Bool) -> Int {
        var hasher = Hasher()
        hasher.combine(innerColor)
        hasher.combine(flipped)
        return hasher.finalize()
    }
}
