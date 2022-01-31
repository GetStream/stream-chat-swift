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
        let addMenu = appearance.images.addMenu
        setImage(addMenu, for: .normal)
    }

    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -20, dy: -20).contains(point)
    }
}
