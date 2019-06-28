//
//  CustomChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 28/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

class CustomChatViewController: ChatViewController {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let channel = Channel(id: "general", name: "General")
        channelPresenter = ChannelPresenter(channel: channel)
    }
}
