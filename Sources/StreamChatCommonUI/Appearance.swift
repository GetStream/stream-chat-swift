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
    
    /// Override bundle used when resolving localized resources.
    ///
    /// Storage lives on a non-`@MainActor` holder (see ``AppearanceBundleOverride``)
    /// so the property can be read from non-main contexts such as the
    /// ``localizationProvider`` closure without requiring a main-actor hop.
    public nonisolated static var bundle: Bundle? {
        get { AppearanceBundleOverride.value }
        set { AppearanceBundleOverride.value = newValue }
    }

    /// Provider for custom localization which is dependent on App Bundle.
    public var localizationProvider: @Sendable (_ key: String, _ table: String) -> String = { key, table in
        let bundle = Appearance.bundle ?? Bundle.streamChatCommonUI
        return bundle.localizedString(forKey: key, value: nil, table: table)
    }

    public init() {
        // Public init.
    }
}

// MARK: - Bundle Override Storage

/// Non-`@MainActor` storage for ``Appearance/bundle``.
///
/// Keeping the `nonisolated(unsafe)` static outside of the main-actor-isolated
/// ``Appearance`` class avoids combining `@MainActor` and `nonisolated(unsafe)`
/// on the same declaration, which trips known Swift 6.0.x diagnostics when the
/// type is re-exported across module boundaries.
public enum AppearanceBundleOverride {
    /// The override bundle, or `nil` to fall back to the SDK's own bundle.
    public nonisolated(unsafe) static var value: Bundle?
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}
