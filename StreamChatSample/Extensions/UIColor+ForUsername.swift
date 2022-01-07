//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import SwiftUI
import UIKit

extension UIColor {
    static var usernameColors: [UIColor] = [
        #colorLiteral(red: 0.1764705926, green: 0.4980392158, blue: 0.7568627596, alpha: 1),
        #colorLiteral(red: 0.1764705926, green: 0.01176470611, blue: 0.5607843399, alpha: 1),
        #colorLiteral(red: 0.5725490451, green: 0, blue: 0.2313725501, alpha: 1),
        #colorLiteral(red: 0.9254902005, green: 0.2352941185, blue: 0.1019607857, alpha: 1),
        #colorLiteral(red: 0.9529411793, green: 0.6862745285, blue: 0.1333333403, alpha: 1),
        #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
    ]
    static func forUsername(_ name: String) -> UIColor {
        usernameColors[abs(name.hashValue) % usernameColors.count]
    }
}

@available(iOS 13, *)
extension Color {
    static func forUsername(_ name: String) -> Color {
        Color(UIColor.forUsername(name))
    }
}
