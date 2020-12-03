//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat) {
        self.init(
            red: r / 255,
            green: g / 255,
            blue: b / 255,
            alpha: 1
        )
    }

    convenience init(red: Int, green: Int, blue: Int) {
        self.init(
            r: CGFloat(red),
            g: CGFloat(green),
            b: CGFloat(blue)
        )
    }

    convenience init(rgb: Int) {
        self.init(
            red: (rgb >> 16) & 0xff,
            green: (rgb >> 8) & 0xff,
            blue: rgb & 0xff
        )
    }
}

extension UIColor {
    static let outgoingMessageBubbleBackground = UIColor(rgb: 0xe5e5e5)
    static let outgoingMessageBubbleBorder = outgoingMessageBubbleBackground
    static let incomingMessageBubbleBackground = white
    static let incomingMessageBubbleBorder = UIColor(red: 20, green: 20, blue: 20)
    static let chatBackground = UIColor(rgb: 0xfcfcfc)
    static let messageTimestamp = UIColor.lightGray
}
