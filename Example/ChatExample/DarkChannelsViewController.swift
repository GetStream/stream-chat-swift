//
//  DarkChannelsViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 27/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import StreamChat

final class DarkChannelsViewController: ChannelsViewController {
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
//        Client.shared.set(user: .user1, token: .token1)
        style = .dark
    }
}
