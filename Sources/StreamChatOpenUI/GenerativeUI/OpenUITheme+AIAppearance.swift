//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

@available(iOS 17.0, macOS 14.0, *)
public extension OpenUITheme {
    /// The theme of StreamChatAI's `appearance`, so a reply's OpenUI looks like the rest of its
    /// conversation: its accent, text, surface and status colors, its fonts, spacing and corners.
    @MainActor
    init(appearance: AIAppearance) {
        self.init()
        let tokens = appearance.tokens.colors
        colors.accent = Color(tokens.accentPrimary)
        colors.onAccent = Color(tokens.textOnAccent)
        colors.textPrimary = Color(tokens.textPrimary)
        colors.textSecondary = Color(tokens.textSecondary)
        colors.textTertiary = Color(tokens.textTertiary)
        colors.surface = Color(tokens.backgroundCoreSurfaceCard)
        colors.sunkenSurface = Color(tokens.backgroundCoreSurfaceDefault)
        colors.subtleFill = Color(tokens.backgroundCoreSurfaceSubtle)
        colors.border = Color(tokens.borderCoreDefault)
        colors.success = Color(tokens.accentSuccess)
        colors.warning = Color(tokens.accentWarning)
        colors.danger = Color(tokens.accentError)
        colors.info = Color(tokens.accentPrimary)
        colors.neutral = Color(tokens.accentNeutral)

        let font = appearance.tokens.fonts
        fonts.title = font.title3.weight(.semibold)
        fonts.heading = font.headline
        fonts.body = font.body
        fonts.bodyLarge = font.title3
        fonts.bodySmall = font.subheadline
        fonts.caption = font.caption1

        let layout = appearance.tokens.layout
        spacing.xs = layout.spacingXxs
        spacing.s = layout.spacingXs
        spacing.m = layout.spacingSm
        spacing.l = layout.spacingMd
        spacing.xl = layout.spacingXl
        spacing.xxl = layout.spacing2xl
        radius.small = layout.radiusMd
        radius.medium = layout.radiusLg
        radius.large = layout.radiusXl
        radius.pill = layout.radiusMax
    }
}
