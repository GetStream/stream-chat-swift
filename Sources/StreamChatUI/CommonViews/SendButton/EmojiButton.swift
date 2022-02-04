//
//  EmojiButton.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 26/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class EmojiButton: _Button, AppearanceProvider {

    override open func setUpAppearance() {
        super.setUpAppearance()
        let normalStateImage = appearance.images.emojiIcon
        setImage(normalStateImage, for: .normal)
    }
}
