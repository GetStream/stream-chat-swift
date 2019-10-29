//
//  CustomChatViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 28/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import StreamChat

class CustomChatViewController: ChatViewController {
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let channel = Channel(type: .messaging, id: "general")
        channelPresenter = ChannelPresenter(channel: channel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        channelPresenter.channelDidUpdate
            .drive(onNext: { [weak self] channel in
                self?.title = "\(channel.name) (\(channel.members.count))"
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func addMember(_ sender: Any) {
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        let member: Member
        
        if !channelPresenter.channel.members.contains(User.current!.asMember) {
            member = User.current!.asMember
        } else if let user: User = [.user1, .user2, .user3].randomElement() {
            member = user.asMember
        } else {
            return
        }
        
        channelPresenter.channel
            .add(member)
            .subscribe(onNext: { _ in
                Banners.shared.show("\(User.user3.name) added to the channel")
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func removeMember(_ sender: Any) {
        guard let member = channelPresenter?.channel.members.first else {
            return
        }
        
        channelPresenter?.channel
            .remove(member)
            .subscribe(onNext: { _ in
                Banners.shared.show("\(User.user3.name) removed from the channel")
            })
            .disposed(by: disposeBag)
    }
    //    override func messageCell(at indexPath: IndexPath, message: Message, readUsers: [User]) -> UITableViewCell {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "message")
//            ?? UITableViewCell(style: .value2, reuseIdentifier: "message")
//
//        cell.textLabel?.text = message.user.name
//        cell.textLabel?.numberOfLines = 2
//        cell.textLabel?.font = .systemFont(ofSize: 12, weight: .bold)
//        cell.detailTextLabel?.text = message.text
//        cell.detailTextLabel?.numberOfLines = 0
//
//        return cell
//    }
//
//    override func loadingCell(at indexPath: IndexPath) -> UITableViewCell? {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "loading")
//            ?? UITableViewCell(style: .default, reuseIdentifier: "loading")
//
//        cell.textLabel?.textColor = .red
//        cell.textLabel?.text = "LOADING..."
//        cell.textLabel?.textAlignment = .center
//
//        return cell
//    }
//
//    override func statusCell(at indexPath: IndexPath,
//                             title: String,
//                             subtitle: String? = nil,
//                             highlighted: Bool) -> UITableViewCell? {
//        let cell = tableView.dequeueReusableCell(withIdentifier: "status")
//            ?? UITableViewCell(style: .default, reuseIdentifier: "status")
//
//        cell.textLabel?.textColor = .gray
//        cell.textLabel?.text = title
//        cell.textLabel?.textAlignment = .center
//
//        return cell
//    }
}
