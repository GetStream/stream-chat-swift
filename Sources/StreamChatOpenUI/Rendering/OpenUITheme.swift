//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Visual tokens used by the built-in components. Inject a customized theme with
/// `.openUITheme(_:)` to match your app's design system.
@available(iOS 17.0, macOS 14.0, *)
public struct OpenUITheme: Sendable {
    public var colors = Colors()
    public var spacing = Spacing()
    public var radius = Radius()
    public var fonts = Fonts()

    public init() {}

    public static let `default` = OpenUITheme()

    /// Returns the text for a key of a strings table. Replace it to change or translate the
    /// components' texts, such as button titles and validation messages.
    public static var localizationProvider: @Sendable (_ key: String, _ table: String) -> String {
        get { LocalizationProviderStorage.current }
        set { LocalizationProviderStorage.current = newValue }
    }

    public struct Colors: Sendable {
        public var accent: Color = .accentColor
        public var onAccent: Color = .white
        public var textPrimary: Color = .primary
        public var textSecondary: Color = .secondary
        public var textTertiary: Color = PlatformColors.tertiaryLabel
        /// Elevated card surfaces.
        public var surface: Color = PlatformColors.secondaryGroupedBackground
        /// Recessed ("sunk") surfaces and input backgrounds.
        public var sunkenSurface: Color = PlatformColors.tertiaryFill
        /// Subtle fills (chips, tags, table headers).
        public var subtleFill: Color = PlatformColors.quaternaryFill
        public var border: Color = PlatformColors.separator
        public var success: Color = Color(red: 0.13, green: 0.62, blue: 0.36)
        public var warning: Color = Color(red: 0.86, green: 0.55, blue: 0.08)
        public var danger: Color = Color(red: 0.86, green: 0.21, blue: 0.24)
        public var info: Color = Color(red: 0.16, green: 0.45, blue: 0.91)
        public var neutral: Color = .secondary
        /// Categorical chart colors.
        public var chartPalette: [Color] = Self.defaultChartPalette

        static let defaultChartPalette = [
            Color(red: 0.25, green: 0.47, blue: 0.96),
            Color(red: 0.11, green: 0.71, blue: 0.62),
            Color(red: 0.98, green: 0.62, blue: 0.16),
            Color(red: 0.88, green: 0.29, blue: 0.46),
            Color(red: 0.55, green: 0.38, blue: 0.93),
            Color(red: 0.16, green: 0.68, blue: 0.88),
            Color(red: 0.62, green: 0.72, blue: 0.20),
            Color(red: 0.93, green: 0.41, blue: 0.27)
        ]

        public init() {}

        /// The semantic color for a variant name (`success`, `warning`, `danger`/`error`, `info`, `neutral`).
        public func variant(_ name: String?) -> Color {
            switch name {
            case "success": return success
            case "warning": return warning
            case "danger", "error": return danger
            case "info": return info
            default: return neutral
            }
        }

        public func chartColor(_ index: Int) -> Color {
            let palette = chartPalette.isEmpty ? Self.defaultChartPalette : chartPalette
            return palette[((index % palette.count) + palette.count) % palette.count]
        }
    }

    /// OpenUI spacing scale (`none`, `xs`, `s`, `m`, `l`, `xl`, `2xl`).
    public struct Spacing: Sendable {
        public var xs: CGFloat = 4
        public var s: CGFloat = 8
        public var m: CGFloat = 12
        public var l: CGFloat = 16
        public var xl: CGFloat = 24
        public var xxl: CGFloat = 32

        public init() {}

        public func value(_ token: String?, default defaultValue: CGFloat? = nil) -> CGFloat {
            switch token {
            case "none": return 0
            case "xs": return xs
            case "s": return s
            case "m": return m
            case "l": return l
            case "xl": return xl
            case "2xl": return xxl
            default: return defaultValue ?? m
            }
        }
    }

    public struct Radius: Sendable {
        public var small: CGFloat = 8
        public var medium: CGFloat = 12
        public var large: CGFloat = 16
        public var pill: CGFloat = 999

        public init() {}
    }

    public struct Fonts: Sendable {
        public var title: Font = .title3.weight(.semibold)
        public var heading: Font = .headline
        public var body: Font = .body
        public var bodyLarge: Font = .title3
        public var bodySmall: Font = .subheadline
        public var caption: Font = .caption
        public var code: Font = .system(.footnote, design: .monospaced)
        public var metric: Font = .system(.title2, design: .rounded).weight(.semibold)

        public init() {}
    }
}

/// Platform system colors (UIKit/AppKit).
@available(iOS 17.0, macOS 14.0, *)
enum PlatformColors {
    #if canImport(UIKit)
    static let tertiaryLabel = Color(uiColor: .tertiaryLabel)
    static let secondaryGroupedBackground = Color(uiColor: .secondarySystemGroupedBackground)
    static let groupedBackground = Color(uiColor: .systemGroupedBackground)
    static let tertiaryFill = Color(uiColor: .tertiarySystemFill)
    static let quaternaryFill = Color(uiColor: .quaternarySystemFill)
    static let separator = Color(uiColor: .separator)
    static let background = Color(uiColor: .systemBackground)
    #else
    static let tertiaryLabel = Color(nsColor: .tertiaryLabelColor)
    static let secondaryGroupedBackground = Color(nsColor: .controlBackgroundColor)
    static let groupedBackground = Color(nsColor: .windowBackgroundColor)
    static let tertiaryFill = Color(nsColor: .quaternaryLabelColor).opacity(0.5)
    static let quaternaryFill = Color(nsColor: .quaternaryLabelColor).opacity(0.3)
    static let separator = Color(nsColor: .separatorColor)
    static let background = Color(nsColor: .textBackgroundColor)
    #endif
}

@available(iOS 17.0, macOS 14.0, *)
private struct OpenUIThemeKey: EnvironmentKey {
    static let defaultValue = OpenUITheme.default
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    var openUITheme: OpenUITheme {
        get { self[OpenUIThemeKey.self] }
        set { self[OpenUIThemeKey.self] = newValue }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    /// Applies a theme to OpenUI components rendered inside this view.
    func openUITheme(_ theme: OpenUITheme) -> some View {
        environment(\.openUITheme, theme)
    }
}
