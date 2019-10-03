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
    
    override var defaultStyle: ChatViewStyle {
        return .dark
    }
    
    @IBOutlet weak var logoutButton: UIBarButtonItem!
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        deleteChannelBySwipe = true
        title = "My channels"
        setupPresenter()
    }
    
    func setupPresenter() {
        if let currentUser = User.current {
            channelsPresenter = ChannelsPresenter(channelType: .messaging, filter: .key("members", .in([currentUser.id])))
        }
    }
    
    @IBAction func addChannel(_ sender: Any) {
        let number = Int.random(in: 100...999)
        let channel = Channel(type: .messaging, id: "new_channel_\(number)", name: "Channel \(number)")
        
        channel.create()
            .flatMapLatest({ channelResponse in
                channelResponse.channel.send(message: Message(text: "A new channel created"))
            })
            .subscribe(onNext: {
                print($0)
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func logout(_ sender: Any) {
        if logoutButton.title == "Logout" {
            Client.shared.disconnect()
            logoutButton.title = "Login"
        } else if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.setupUser()
            setupPresenter()
            logoutButton.title = "Logout"
        }
    }
}
