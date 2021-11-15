//
//  ToolTipToggleButton.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 12/11/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class ToolTipToggleButton: _Button, AppearanceProvider {

    override open func setUpAppearance() {
        super.setUpAppearance()
        let moreImage = appearance.images.moreRounded
        setImage(moreImage, for: .normal)
    }
}
