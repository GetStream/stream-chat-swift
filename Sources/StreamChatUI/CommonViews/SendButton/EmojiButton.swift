//
//  EmojiButton.swift
//  StreamChat
//
//  Created by Parth Kshatriya on 26/01/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit
import Stipop

open class EmojiButton: _Button, AppearanceProvider {
    public let stipopButton = SPUIButton(type: .system)
    public var didSelectEmoji: ((_ sticker: SPSticker) -> Void)?

    override open func setUpAppearance() {
        super.setUpAppearance()
        stipopButton.tintColor = UIColor(rgb: 0x737373)
        self.addSubview(stipopButton)
        stipopButton.translatesAutoresizingMaskIntoConstraints = false
        stipopButton.heightAnchor.constraint(equalToConstant: 25).isActive = true
        stipopButton.widthAnchor.constraint(equalToConstant: 25).isActive = true

        let user = SPUser(userID: ChatClient.shared.currentUserId?.string ?? "")
        stipopButton.setUser(user, viewType: .picker)
        stipopButton.delegate = self
    }
}

extension EmojiButton: SPUIDelegate {
    public func spViewDidSelectSticker(_ view: SPUIView, sticker: SPSticker) {
        didSelectEmoji?(sticker)
    }

    public func spViewWillAppear(_ view: SPUIView) {
        let keyboardImage = appearance.images.menuKeyboard
        stipopButton.setImage(keyboardImage, for: .normal)
    }

    public func spViewDidDisappear(_ view: SPUIView) {
        let normalStateImage = appearance.images.emojiIcon
        stipopButton.setImage(normalStateImage, for: .normal)
    }
}
