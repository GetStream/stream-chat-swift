//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit

final class ChatViewController: UIViewController {
    
    public let tableView = UITableView(frame: .zero, style: .plain)
    
    public var channelPresenter: ChannelPresenter?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
