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

    /// Provider for custom localization which is dependent on App Bundle.
    ///
    /// The default implementation looks up the key in `Bundle.streamChatCommonUI` first; if
    /// the key is not found there it falls back to `Appearance.bundle` (when set) and finally
    /// to `Bundle.main`. This lets each UI module ship its own `Localizable.strings` and
    /// register its bundle via `Appearance.bundle` while CommonUI keeps owning the keys it
    /// itself references.
    public var localizationProvider: @Sendable (_ key: String, _ table: String) -> String = { key, table in
        let commonBundle = Bundle.streamChatCommonUI
        let value = commonBundle.localizedString(forKey: key, value: nil, table: table)
        // `localizedString(forKey:value:table:)` returns the key itself when the lookup misses.
        if value != key { return value }
        let fallback = Appearance.bundle ?? .main
        return fallback.localizedString(forKey: key, value: nil, table: table)
    }

    public init() {
        // Public init.
    }
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}
