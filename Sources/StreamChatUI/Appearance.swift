//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public struct Appearance {
    public var colorPalette = ColorPalette()
    public var fonts = Fonts()
    public var images = Images()
    
    public init() {}
}

// MARK: - Appearance + Default

public extension Appearance {
    static var `default`: Appearance = .init()
}
