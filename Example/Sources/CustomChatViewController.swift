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
    let membersCountButton = UIBarButtonItem(title: "🤷🏻‍♀️0", style: .plain, target: nil, action: nil)
    
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
        
        touchMembersCount()
        
        if (navigationItem.rightBarButtonItems?.count ?? 0) == 1 {
            navigationItem.rightBarButtonItems?.append(membersCountButton)
        } else {
            navigationItem.leftBarButtonItem = membersCountButton
        }
        
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        title = channelPresenter.channel.name
        
        channelPresenter.channelDidUpdate
            .drive(onNext: { [weak self] channel in
                self?.title = channelPresenter.channel.name
                self?.touchMembersCount()
            })
            .disposed(by: disposeBag)
    }
    
    func touchMembersCount() {
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        membersCountButton.title = channelPresenter.channel.members.count > 0
            ? "🙋🏻‍♀️\(channelPresenter.channel.members.count)"
            : "🤷🏻‍♀️0"
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
                    Banners.shared.show("\(member.user.name) added to the channel")
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
                    Banners.shared.show("\(member.user.name) removed from the channel")
                })
                .disposed(by: disposeBag)
        }
    }
    
    func memberNotInList() -> Member? {
        guard let membersSet = channelPresenter?.channel.members else {
            return nil
        }
        
        guard let window = UIApplication.shared.delegate?.window,
            let navigationController = window?.rootViewController as? UINavigationController,
            let loginViewController = navigationController.viewControllers.first as? LoginViewController,
            let secondUser = loginViewController.secondUser else {
            return nil
        }
        
        return membersSet.contains(where: { $0.user == secondUser }) ? nil : secondUser.asMember
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
}
