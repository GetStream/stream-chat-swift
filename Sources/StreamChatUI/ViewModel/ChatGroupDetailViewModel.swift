//
//  ChatGroupDetailViewModel.swift
//  StreamChatUI
//
//  Created by Ajay Ghodadra on 30/03/22.
//  Copyright © 2022 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChat

class ChatGroupDetailViewModel: NSObject {

    // MARK: - Variable
    var channelController: ChatChannelController?
    var screenType: ScreenType = .channelDetail

    // MARK: - Enums
    enum ScreenType {
        case channelDetail
        case userdetail
    }

    // MARK: - Initialisers
    override init() {
        super.init()
    }

    init(controller: ChatChannelController, screenType: ScreenType) {
        super.init()
        channelController = controller
        self.screenType = screenType
    }
}
