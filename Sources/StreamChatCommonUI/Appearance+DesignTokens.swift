//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

extension Appearance {
    @MainActor public final class DesignSystemTokens {
        // MARK: Chat

        public lazy var buttonHitTargetMinHeight: CGFloat = size48
        public lazy var buttonHitTargetMinWidth: CGFloat = size48
        public lazy var buttonPaddingXIconOnlyLg: CGFloat = 14
        public lazy var buttonPaddingXIconOnlyMd: CGFloat = 10
        public lazy var buttonPaddingXIconOnlySm: CGFloat = 6
        public lazy var buttonPaddingXIconOnlyXs: CGFloat = 4
        public lazy var buttonPaddingXWithLabelLg: CGFloat = 16
        public lazy var buttonPaddingXWithLabelMd: CGFloat = 16
        public lazy var buttonPaddingXWithLabelSm: CGFloat = 16
        public lazy var buttonPaddingXWithLabelXs: CGFloat = 12
        public lazy var buttonPaddingYLg: CGFloat = 14
        public lazy var buttonPaddingYMd: CGFloat = 10
        public lazy var buttonPaddingYSm: CGFloat = 6
        public lazy var buttonPaddingYXs: CGFloat = 4
        public lazy var buttonRadiusFull: CGFloat = radiusFull
        public lazy var buttonRadiusLg: CGFloat = radiusFull
        public lazy var buttonRadiusMd: CGFloat = radiusFull
        public lazy var buttonRadiusSm: CGFloat = radiusFull
        public lazy var buttonVisualHeightLg: CGFloat = size48
        public lazy var buttonVisualHeightMd: CGFloat = size40
        public lazy var buttonVisualHeightSm: CGFloat = size32
        public lazy var buttonVisualHeightXs: CGFloat = size24
        public lazy var composerRadiusFixed: CGFloat = radius3xl
        public lazy var composerRadiusFloating: CGFloat = radius3xl
        public lazy var darkElevation1: BoxShadow = BoxShadow(x: 0, y: 1, blur: 3, spread: 0, color: UIColor(hex: 0x00000033))
        public lazy var darkElevation2: BoxShadow = BoxShadow(x: 0, y: 2, blur: 6, spread: 0, color: UIColor(hex: 0x00000038))
        public lazy var darkElevation3: BoxShadow = BoxShadow(x: 0, y: 4, blur: 12, spread: 0, color: UIColor(hex: 0x0000003d))
        public lazy var darkElevation4: BoxShadow = BoxShadow(x: 0, y: 8, blur: 24, spread: 0, color: UIColor(hex: 0x00000047))
        public lazy var deviceRadius: CGFloat = 62
        public lazy var deviceSafeAreaBottom: CGFloat = space32
        public lazy var deviceSafeAreaTop: CGFloat = 50
        public lazy var iconSizeLg: CGFloat = size32
        public lazy var iconSizeMd: CGFloat = size20
        public lazy var iconSizeSm: CGFloat = size16
        public lazy var iconSizeXs: CGFloat = size12
        public lazy var iconStrokeDefault: CGFloat = w150
        public lazy var iconStrokeEmphasis: CGFloat = w200
        public lazy var iconStrokeSubtle: CGFloat = w120
        public lazy var lightElevation1: BoxShadow = BoxShadow(x: 0, y: 1, blur: 3, spread: 0, color: UIColor(hex: 0x0000001f))
        public lazy var lightElevation2: BoxShadow = BoxShadow(x: 0, y: 2, blur: 6, spread: 0, color: UIColor(hex: 0x00000024))
        public lazy var lightElevation3: BoxShadow = BoxShadow(x: 0, y: 4, blur: 12, spread: 0, color: UIColor(hex: 0x00000029))
        public lazy var lightElevation4: BoxShadow = BoxShadow(x: 0, y: 8, blur: 24, spread: 0, color: UIColor(hex: 0x00000033))
        public lazy var messageBubbleRadiusAttachment: CGFloat = radiusLg
        public lazy var messageBubbleRadiusAttachmentInline: CGFloat = radiusMd
        public lazy var messageBubbleRadiusGroupBottom: CGFloat = radius2xl
        public lazy var messageBubbleRadiusGroupMiddle: CGFloat = radius2xl
        public lazy var messageBubbleRadiusGroupTop: CGFloat = radius2xl
        public lazy var messageBubbleRadiusTail: CGFloat = radiusNone
        public lazy var radius2xl: CGFloat = radius20
        public lazy var radius3xl: CGFloat = radius24
        public lazy var radius4xl: CGFloat = radius32
        public lazy var radiusLg: CGFloat = radius12
        public lazy var radiusMax: CGFloat = radiusFull
        public lazy var radiusMd: CGFloat = radius8
        public lazy var radiusNone: CGFloat = radius0
        public lazy var radiusSm: CGFloat = radius6
        public lazy var radiusXl: CGFloat = radius16
        public lazy var radiusXs: CGFloat = radius4
        public lazy var radiusXxs: CGFloat = radius2
        public lazy var spacing2xl: CGFloat = space32
        public lazy var spacing3xl: CGFloat = space40
        public lazy var spacingLg: CGFloat = space20
        public lazy var spacingMd: CGFloat = space16
        public lazy var spacingNone: CGFloat = space0
        public lazy var spacingSm: CGFloat = space12
        public lazy var spacingXl: CGFloat = space24
        public lazy var spacingXs: CGFloat = space8
        public lazy var spacingXxs: CGFloat = space4
        public lazy var spacingXxxs: CGFloat = space2

        // MARK: Foundations

        let lineHeightLineHeight10: CGFloat = 10
        let lineHeightLineHeight12: CGFloat = 12
        let lineHeightLineHeight13: CGFloat = 13
        let lineHeightLineHeight14: CGFloat = 14
        let lineHeightLineHeight15: CGFloat = 15
        let lineHeightLineHeight16: CGFloat = 16
        let lineHeightLineHeight17: CGFloat = 17
        let lineHeightLineHeight18: CGFloat = 18
        let lineHeightLineHeight20: CGFloat = 20
        let lineHeightLineHeight24: CGFloat = 24
        let lineHeightLineHeight28: CGFloat = 28
        let lineHeightLineHeight32: CGFloat = 32
        let lineHeightLineHeight40: CGFloat = 40
        let lineHeightLineHeight48: CGFloat = 48
        let lineHeightLineHeight8: CGFloat = 8
        let radius0: CGFloat = 0
        let radius12: CGFloat = 12
        let radius16: CGFloat = 16
        let radius2: CGFloat = 2
        let radius20: CGFloat = 20
        let radius24: CGFloat = 24
        let radius32: CGFloat = 32
        let radius4: CGFloat = 4
        let radius6: CGFloat = 6
        let radius8: CGFloat = 8
        let radiusFull: CGFloat = 9999
        let size12: CGFloat = 12
        let size128: CGFloat = 128
        let size144: CGFloat = 144
        let size16: CGFloat = 16
        let size2: CGFloat = 2
        let size20: CGFloat = 20
        let size208: CGFloat = 208
        let size24: CGFloat = 24
        let size240: CGFloat = 240
        let size28: CGFloat = 28
        let size32: CGFloat = 32
        let size320: CGFloat = 320
        let size4: CGFloat = 4
        let size40: CGFloat = 40
        let size48: CGFloat = 48
        let size480: CGFloat = 480
        let size56: CGFloat = 56
        let size560: CGFloat = 560
        let size6: CGFloat = 6
        let size64: CGFloat = 64
        let size640: CGFloat = 640
        let size760: CGFloat = 760
        let size8: CGFloat = 8
        let size80: CGFloat = 80
        let space0: CGFloat = 0
        let space12: CGFloat = 12
        let space16: CGFloat = 16
        let space2: CGFloat = 2
        let space20: CGFloat = 20
        let space24: CGFloat = 24
        let space32: CGFloat = 32
        let space4: CGFloat = 4
        let space40: CGFloat = 40
        let space48: CGFloat = 48
        let space64: CGFloat = 64
        let space8: CGFloat = 8
        let space80: CGFloat = 80
        let w100: CGFloat = 1
        let w120: CGFloat = 1.2
        let w150: CGFloat = 1.5
        let w200: CGFloat = 2
        let w300: CGFloat = 3
        let w400: CGFloat = 4

        public init() {}
    }
}

public struct BoxShadow {
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
    public let spread: CGFloat
    public let color: UIColor
    
    public init(x: CGFloat, y: CGFloat, blur: CGFloat, spread: CGFloat, color: UIColor) {
        self.x = x
        self.y = y
        self.blur = blur
        self.spread = spread
        self.color = color
    }
}
