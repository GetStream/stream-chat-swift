//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat

/// An object containing visual configuration for whole application.
public struct Appearance {
    /// A color pallete to provide basic set of colors for the Views.
    ///
    /// By providing different object or changing individal colors, you can change the look of the views.
    public var colorPalette = ColorPalette()
    
    /// A set of fonts to be used in the Views.
    ///
    /// By providing different object or changing individal fonts, you can change the look of the views.
    public var fonts = Fonts()
    
    /// A set of images to be used.
    ///
    /// By providing different object or changing individal images, you can change the look of the views.
    public var images = Images()
    
    public init() {}
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}
