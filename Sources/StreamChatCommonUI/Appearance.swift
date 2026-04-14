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
    public var localizationProvider: @Sendable (_ key: String, _ table: String) -> String = { key, table in
        if let bundle = Appearance.bundle {
            let value = bundle.localizedString(forKey: key, value: nil, table: table)
            if value != key {
                return value
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
