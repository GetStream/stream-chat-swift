//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// An object containing visual configuration for whole application.
@MainActor public final class Appearance {
    /// A color palette to provide basic set of colors for the Views.
    ///
    /// By providing different object or changing individual colors, you can change the look of the views.
    public var colorPalette = ColorPalette()

    /// A set of fonts to be used in the Views.
    ///
    /// By providing different object or changing individual fonts, you can change the look of the views.
    public var fonts = Fonts()
    
    /// SwiftUI representation of the fonts.
    public var fontsSwiftUI = FontsSwiftUI()

    /// A set of images to be used.
    ///
    /// By providing different object or changing individual images, you can change the look of the views.
    public var images = Images()

    /// A set of formatters to be used
    ///
    /// By providing different object or changing individual formatters,
    /// you can change how data is formatted to textual representation.
    public var formatters = Formatters()
    
    /// A set of tokens defining the rules for layout.
    public var tokens = DesignSystemTokens()
    
    public nonisolated(unsafe) static var bundle: Bundle?

    /// Provider for custom localization.
    ///
    /// The default implementation resolves each key by walking a fallback chain:
    /// 1. The app's `Bundle.main` — so any key the integrating app overrides in its own
    ///    `Localizable.strings` / `Localizable.stringsdict` automatically wins, without the
    ///    app having to install a custom provider.
    /// 2. `Appearance.bundle`, when set by a UI SDK (e.g. `StreamChatSwiftUI` points it at
    ///    its own framework bundle so SwiftUI-specific keys are resolved there).
    /// 3. `StreamChatCommonUI`'s own bundle, which ships the SDK's default translations.
    ///
    /// Replace this provider only if you need a more advanced setup; for simple
    /// per-key overrides or adding new translations, just ship the keys you want to
    /// customize in your app's `Localizable.strings` / `Localizable.stringsdict`.
    public var localizationProvider: @Sendable (_ key: String, _ table: String) -> String = { key, table in
        let mainLocalizedString = Bundle.main.localizedString(forKey: key, value: nil, table: table)
        if mainLocalizedString != key {
            return mainLocalizedString
        }

        if let bundle = Appearance.bundle {
            let bundleLocalizedString = bundle.localizedString(forKey: key, value: nil, table: table)
            if bundleLocalizedString != key {
                return bundleLocalizedString
            }
        }

        return Bundle.streamChatCommonUI.localizedString(forKey: key, value: nil, table: table)
    }

    public init() {
        // Public init.
    }
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}
