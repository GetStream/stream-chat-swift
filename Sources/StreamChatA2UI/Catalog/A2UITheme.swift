//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The look of a reply's A2UI: the colors, fonts and corners the basic catalog's components use.
///
/// ``A2UIRenderer`` makes it from the app's `AIAppearance`, so A2UI looks like the rest of the
/// conversation. Give the renderer a theme to change only A2UI, such as its buttons:
///
/// ```swift
/// var theme = A2UITheme(appearance: .shared)
/// theme.accent = .orange
/// A2UIRenderer(theme: theme)
/// ```
@available(iOS 15.0, macOS 12.0, *)
public struct A2UITheme: Sendable {
    /// The color of primary buttons, selected options and the controls' active parts.
    public var accent: Color
    /// The color of text on ``accent``, such as a primary button's title.
    public var onAccent: Color
    /// The color of text.
    public var text: Color
    /// The color of labels, captions and other quieter text.
    public var secondaryText: Color
    /// The background of cards.
    public var surface: Color
    /// The background of buttons, fields and options, and of images while they load.
    public var subtleSurface: Color
    /// The color of dividers.
    public var border: Color
    /// The color of a field's error, and of its messages.
    public var error: Color
    /// The color of a field's warnings.
    public var warning: Color

    /// The font of text.
    public var body: Font
    /// The font of captions and validation messages.
    public var caption: Font
    /// The font of fields' labels and of options.
    public var label: Font
    /// The fonts of headings, from level 1 down. Deeper levels use the last.
    public var headings: [Font]

    /// The corner radius of cards.
    public var cornerRadius: CGFloat
    /// The corner radius of buttons.
    public var buttonCornerRadius: CGFloat
    /// The corner radius of fields, images and players.
    public var controlCornerRadius: CGFloat

    /// A theme with the system's colors and fonts.
    public init(
        accent: Color = .accentColor,
        onAccent: Color = .white,
        text: Color = .primary,
        secondaryText: Color = .secondary,
        surface: Color = A2UITheme.systemSurface,
        subtleSurface: Color = Color.gray.opacity(0.12),
        border: Color = Color.secondary.opacity(0.3),
        error: Color = .red,
        warning: Color = .orange,
        body: Font = .body,
        caption: Font = .caption,
        label: Font = .subheadline.weight(.medium),
        headings: [Font] = [
            .largeTitle.weight(.bold),
            .title.weight(.bold),
            .title2.weight(.semibold),
            .title3.weight(.semibold),
            .headline,
            .subheadline.weight(.semibold)
        ],
        cornerRadius: CGFloat = 12,
        buttonCornerRadius: CGFloat = 10,
        controlCornerRadius: CGFloat = 8
    ) {
        self.accent = accent
        self.onAccent = onAccent
        self.text = text
        self.secondaryText = secondaryText
        self.surface = surface
        self.subtleSurface = subtleSurface
        self.border = border
        self.error = error
        self.warning = warning
        self.body = body
        self.caption = caption
        self.label = label
        self.headings = headings
        self.cornerRadius = cornerRadius
        self.buttonCornerRadius = buttonCornerRadius
        self.controlCornerRadius = controlCornerRadius
    }

    /// The font of a heading level, from 1.
    public func heading(_ level: Int) -> Font {
        guard !headings.isEmpty else { return body }
        return headings[min(max(level, 1), headings.count) - 1]
    }

    /// The system's background for grouped content.
    public static var systemSurface: Color {
        #if canImport(UIKit) && !os(watchOS)
        Color(UIColor.secondarySystemBackground)
        #elseif canImport(AppKit)
        Color(NSColor.controlBackgroundColor)
        #else
        Color.gray.opacity(0.12)
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct A2UIThemeKey: EnvironmentKey {
    static let defaultValue = A2UITheme()
}

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
    var a2uiTheme: A2UITheme {
        get { self[A2UIThemeKey.self] }
        set { self[A2UIThemeKey.self] = newValue }
    }
}
