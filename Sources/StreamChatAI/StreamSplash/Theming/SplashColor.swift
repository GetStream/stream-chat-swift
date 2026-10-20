/**
 *  Splash
 *  Copyright (c) John Sundell 2018
 *  MIT license - see LICENSE.md
 */

#if os(iOS)
import UIKit
typealias SplashColor = UIColor
#elseif os(macOS)
import Cocoa
typealias SplashColor = NSColor
#endif

#if !os(Linux)
internal extension SplashColor {
    convenience init(red: CGFloat, green: CGFloat, blue: CGFloat) {
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
#endif
