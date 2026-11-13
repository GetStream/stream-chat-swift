//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChatAI
import SwiftUI

@available(iOS 15.0, macOS 12.0, *)
public extension A2UITheme {
    /// The theme of StreamChatAI's `appearance`, so a reply's A2UI looks like the rest of its
    /// conversation: its accent, text and surface colors, its fonts and its corners.
    @MainActor
    init(appearance: AIAppearance) {
        let colors = appearance.tokens.colors
        let fonts = appearance.tokens.fonts
        let layout = appearance.tokens.layout
        self.init(
            accent: Color(colors.accentPrimary),
            onAccent: Color(colors.textOnAccent),
            text: Color(colors.textPrimary),
            secondaryText: Color(colors.textSecondary),
            surface: Color(colors.backgroundCoreSurfaceCard),
            subtleSurface: Color(colors.backgroundCoreSurfaceDefault),
            border: Color(colors.borderCoreDefault),
            error: Color(colors.accentError),
            warning: Color(colors.accentWarning),
            body: fonts.body,
            caption: fonts.caption1,
            label: fonts.subheadline,
            headings: [
                fonts.title.weight(.bold),
                fonts.title2.weight(.bold),
                fonts.title3.weight(.semibold),
                fonts.headlineBold,
                fonts.headline,
                fonts.subheadlineBold
            ],
            cornerRadius: layout.radiusXl,
            buttonCornerRadius: layout.buttonRadiusMd,
            controlCornerRadius: layout.inputRadiusTextInput
        )
    }
}
