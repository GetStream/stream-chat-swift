//
//  CustomChatViewController.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 28/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import StreamChatCore
import StreamChat

class CustomChatViewController: ChatViewController {
    
    @IBOutlet weak var closeBarButton: UIBarButtonItem!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let channel = Channel(type: .messaging, id: "general")
        channelPresenter = ChannelPresenter(channel: channel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if navigationController?.viewControllers.count ?? 1 > 1, let button = navigationItem.rightBarButtonItems?.last {
            navigationItem.rightBarButtonItems = [button]
        }
        
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        title = "\(channelPresenter.channel.name) (\(channelPresenter.channel.members.count))"
        
        channelPresenter.channelDidUpdate
            .drive(onNext: { [weak self] channel in
                self?.title = "\(channel.name) (\(channel.members.count))"
            })
            .disposed(by: disposeBag)
    }
    
    @IBAction func showMenu(_ sender: Any) {
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [unowned self] _ in
            self.addMember()
        }))
        
        if (channelPresenter?.channel.members.count ?? 0) > 1 {
            alert.addAction(.init(title: "Remove a member", style: .default, handler: { [unowned self] _ in
                self.removeMember()
            }))
        }

        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func addMember() {
        guard let channelPresenter = channelPresenter,
            let member = memberNotInList() else {
            return
        }
        
        let alert = UIAlertController(title: "Members", message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: "Add a member: \(member.user.name)", style: .default, handler: { [unowned self] _ in
            channelPresenter.channel
                .add(member)
                .subscribe(onNext: { _ in
                    Banners.shared.show("\(User.user3.name) added to the channel")
                })
                .disposed(by: self.disposeBag)
        }))
        
        alert.addAction(.init(title: "Invite a member: \(member.user.name)", style: .default, handler: { [unowned self] _ in
            channelPresenter.channel
                .invite(member)
                .subscribe(onNext: { _ in
                    Banners.shared.show("Invite for \(member.user.name) was send")
                })
                .disposed(by: self.disposeBag)
        }))

        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func removeMember() {
        if let member = notCurrentMemberInChannelMembers() {
            channelPresenter?.channel
                .remove(member)
                .subscribe(onNext: { _ in
                    Banners.shared.show("\(User.user3.name) removed from the channel")
                })
                .disposed(by: disposeBag)
        }
    }
    
    func memberNotInList() -> Member? {
        guard let membersSet = channelPresenter?.channel.members else {
            return nil
        }
        
        for user in [User.user1, .user2, .user3] where !user.isCurrent && !membersSet.contains(where: { $0.user == user }) {
            return user.asMember
        }
        
        return nil
    }
    
    func notCurrentMemberInChannelMembers() -> Member? {
        guard let membersSet = channelPresenter?.channel.members else {
            return nil
        }
        
        for member in membersSet where !member.user.isCurrent {
            return member
        }
        
        return nil
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
