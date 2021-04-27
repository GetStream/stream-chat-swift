//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

@available(*, deprecated, message: "UIConfig has split into Appearance and Components")
public typealias UIConfig = Appearance

@available(*, deprecated, message: "UIConfig has split into Appearance and Components")
public extension UIConfig {
    @available(*, deprecated, renamed: "Fonts")
    typealias Font = Fonts
    
    @available(*, deprecated, renamed: "fonts")
    var font: Font {
        get { fonts }
        set { fonts = newValue }
    }
}

@available(
    *,
    deprecated,
    message: "UIConfigProvider has split into AppearanceProvider and ComponentsProvider. Use ThemeProvider if you need both."
)
public typealias UIConfigProvider = ThemeProvider

@available(
    *,
    deprecated,
    message: "UIConfigProvider has split into AppearanceProvider and ComponentsProvider. Use ThemeProvider if you need both."
)
public extension UIConfigProvider {
    @available(*, deprecated, message: "uiConfig has split into appearance and components")
    var uiConfig: UIConfig {
        get { appearance }
        set { appearance = newValue }
    }
}
