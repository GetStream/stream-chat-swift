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
        
        if (navigationController?.viewControllers.count ?? 1) > 1 {
            navigationItem.rightBarButtonItem = membersCountButton
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
        
        membersCountButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showMembers() })
            .disposed(by: disposeBag)
    }
    
    func touchMembersCount() {
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        membersCountButton.title = channelPresenter.channel.members.isEmpty
            ? "🤷🏻‍♀️0"
            : "🙋🏻‍♀️\(channelPresenter.channel.members.count)"
    }
    
    func createMember(_ title: String, _ add: @escaping (Member) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alert.addTextField { textField in textField.placeholder = "user id" }
        alert.addTextField { textField in textField.placeholder = "user name (optional)" }
        
        alert.addAction(.init(title: "Add", style: .default, handler: { [unowned alert] _ in
            if let id = alert.textFields?[0].text, !id.isBlank, let name = alert.textFields?[1].text {
                add(User(id: id, name: name.isBlank ? id : name).asMember)
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func selectMember(_ select: @escaping (_ member: Member) -> Void) {
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        let alert = UIAlertController(title: "Select a member", message: nil, preferredStyle: .actionSheet)
        
        for (index, member) in channelPresenter.channel.members.enumerated() {
            if index > 5 {
                break
            }
            
            if let currentUser = User.current, member.user.id == currentUser.id {
                continue
            }
            
            alert.addAction(.init(title: "\(member.user.name) (\(member.user.id))", style: .default, handler: { _ in
                select(member)
            }))
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func removeMember() {
        selectMember { [unowned self] member in
            self.channelPresenter?.channel
                .remove(member)
                .subscribe(onNext: { _ in
                    Banners.shared.show("\(member.user.name) removed from the channel")
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    func showMembers() {
        guard let channelPresenter = channelPresenter else {
            return
        }
        
        let onlyYou = channelPresenter.channel.members.count == 1
            && channelPresenter.channel.members.first!.user.id == User.current!.id
        
        let members = channelPresenter.channel.members.isEmpty
            ? "No members"
            : (onlyYou
                ? "Only you"
                : channelPresenter.channel.members
                    .map({ "\($0.user.name) (\($0.user.id))" })
                    .joined(separator: "\n"))
        
        let alert = UIAlertController(title: "Members", message: members, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [unowned self] _ in
            self.createMember("Add a member") { member in
                channelPresenter.channel
                    .add(member)
                    .subscribe(onNext: { _ in
                        Banners.shared.show("\(member.user.name) added to the channel")
                    })
                    .disposed(by: self.disposeBag)
            }
        }))
        
        alert.addAction(.init(title: "Invite a member", style: .default, handler: { [unowned self] _ in
            self.createMember("Invite a member") { member in
                channelPresenter.channel
                    .invite(member)
                    .subscribe(onNext: { _ in
                        Banners.shared.show("Invite for \(member.user.name) was send")
                    })
                    .disposed(by: self.disposeBag)
            }
        }))
        
        if !channelPresenter.channel.members.isEmpty && !onlyYou {
            alert.addAction(.init(title: "Remove a member", style: .destructive, handler: { [unowned self] _ in
                self.removeMember()
            }))
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
}
