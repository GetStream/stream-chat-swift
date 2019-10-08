//
//  DarkChannelsViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 27/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxGesture
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
        
        let channel = Channel(type: .messaging,
                              id: "new_channel_\(number)",
                              name: "Channel \(number)",
                              members: [User.user1.asMember,
                                        User.user2.asMember,
                                        User.user3.asMember])
        
        channel.create()
            .flatMapLatest({ channelResponse in
                channelResponse.channel.send(message: Message(text: "A new channel #\(number) created"))
            })
            .subscribe(onNext: {
                print($0)
            })
            .disposed(by: disposeBag)
    }
    
    override func channelCell(at indexPath: IndexPath, channelPresenter: ChannelPresenter) -> UITableViewCell {
        let cell = super.channelCell(at: indexPath, channelPresenter: channelPresenter)
        
        if let cell = cell as? ChannelTableViewCell {
            cell.nameLabel.text = "\(cell.nameLabel.text ?? "") (\(channelPresenter.channel.members.count))"
            
            cell.rx.longPressGesture().when(.began)
                .subscribe(onNext: { [weak self, weak channelPresenter] _ in
                    if let self = self, let channelPresenter = channelPresenter {
                        self.showMenu(for: channelPresenter)
                    }
                })
                .disposed(by: cell.disposeBag)
        }
        
        return cell
    }
    
    @IBAction func logout(_ sender: Any) {
        if logoutButton.title == "Logout" {
            Client.shared.disconnect()
            logoutButton.title = "Login"
        } else if let delegate = UIApplication.shared.delegate as? AppDelegate,
            let navigationController = delegate.window?.rootViewController as? UINavigationController,
            let loginViewController = navigationController.viewControllers.first as? LoginViewController {
            loginViewController.login()
            setupPresenter()
            logoutButton.title = "Logout"
        }
    }
    
    func showMenu(for channelPresenter: ChannelPresenter) {
        let alertController = UIAlertController(title: channelPresenter.channel.name, message: nil, preferredStyle: .actionSheet)
        alertController.addAction(.init(title: "Cancel", style: .cancel, handler: { _ in }))
        
        alertController.addAction(.init(title: "Hide", style: .default, handler: { [weak self] _ in
            if let self = self {
                self.channelsPresenter.hide(channelPresenter).drive().disposed(by: self.disposeBag)
            }
        }))
        
        present(alertController, animated: true)
    }
    
    @IBAction func showGeneral(_ sender: UIBarButtonItem) {
        let channel = Channel(type: .messaging, id: "general")
        sender.isEnabled = false
        
        channel.show()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                sender.isEnabled = true
                self?.channelsPresenter.reload()
            })
            .disposed(by: disposeBag)
    }
}
