//
//  YTInputChatMessageView.swift
//  YouTubeClone
//
//  Created by Sagar Dagdu on 01/07/21.
//  Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat
import StreamChatUI

/// Custom input message view
final class YTInputChatMessageView: InputChatMessageView {
    override func setUpAppearance() {
        super.setUpAppearance()
        
        // Remove the border from the container
        container.layer.cornerRadius = 0
        container.layer.borderWidth = 0
    }
}
