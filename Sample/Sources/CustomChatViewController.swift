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
import StreamChatClient
import StreamChat

class CustomChatViewController: ChatViewController {
    
    @IBOutlet weak var closeBarButton: UIBarButtonItem!
    let membersCountButton = UIBarButtonItem(title: "🤷🏻‍♀️0", style: .plain, target: nil, action: nil)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let channel = Client.shared.channel(type: .messaging, id: "general")
        presenter = ChannelPresenter(channel: channel)
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
        
        guard let presenter = presenter else {
            return
        }
        
        title = presenter.channel.name

        presenter.messagePreparationCallback = {
            var message = $0
            
            if message.text.lowercased() == "unicorn" {
                message.text = "*neighs* 🦄"
            }
            
            return message
        }
        
        presenter.rx.channelDidUpdate
            .drive(onNext: { [weak self] channel in
                self?.title = presenter.channel.name
                self?.touchMembersCount()
            })
            .disposed(by: disposeBag)
        
        membersCountButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showMembers() })
            .disposed(by: disposeBag)
    }
    
    override func createThreadChatViewController(with channelPresenter: ChannelPresenter) -> ChatViewController {
        let controller = super.createThreadChatViewController(with: channelPresenter)
        
        if let message = channelPresenter.parentMessage {
            controller.style.composer.placeholderText = "Reply to \(message.user.name)"
        }
        
        return controller
    }
    
    func touchMembersCount() {
        if let membersCount = presenter?.channel.members.count {
            membersCountButton.title = (membersCount > 0 ? "🙋🏻‍♀️" : "🤷🏻‍♀️") + String(membersCount)
        }
    }
    
    func createMember(_ title: String, _ add: @escaping (Member) -> Void) {
        let alert = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        
        alert.addTextField { [unowned self] textField in
            textField.placeholder = "user id"
            
            // Add the current user id as default value if it not a member of the channel.
            if self.presenter?.channel.members.contains(.current) == false {
                textField.text = User.current.id
            }
        }
        
        alert.addTextField { textField in textField.placeholder = "user name (optional)" }
        
        alert.addAction(.init(title: "Add", style: .default, handler: { [unowned alert] _ in
            if let id = alert.textFields?[0].text, !id.isBlank, let name = alert.textFields?[1].text {
                var user = User(id: id)
                
                if !name.isBlank {
                    user.name = name
                }
                
                add(user.asMember)
            }
        }))
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
    
    func selectMember(_ select: @escaping (_ member: Member) -> Void) {
        guard let members = presenter?.channel.members else {
            return
        }
        
        let alert = UIAlertController(title: "Select a member", message: nil, preferredStyle: .actionSheet)
        
        for (index, member) in members.enumerated() {
            if index > 5 {
                break
            }
            
            if member.user.id == User.current.id {
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
            self.presenter?.channel.rx
                .remove(member: member)
                .subscribe(onNext: { _ in
                    Banners.shared.show("\(member.user.name) removed from the channel")
                })
                .disposed(by: self.disposeBag)
        }
    }
    
    func showMembers() {
        guard let channel = presenter?.channel else {
            return
        }
        
        let onlyYou = channel.members.count == 1 && channel.members.first!.user.id == User.current.id
        
        let members = channel.members.isEmpty
            ? "No members"
            : (onlyYou
                ? "Only you"
                : channel.members
                    .map({ "\($0.user.name) (\($0.user.id))" })
                    .joined(separator: "\n"))
        
        let alert = UIAlertController(title: "Members", message: members, preferredStyle: .actionSheet)
        
        alert.addAction(.init(title: "Add a member", style: .default, handler: { [unowned self] _ in
            self.createMember("Add a member") { member in
                channel.rx
                    .add(member: member)
                    .subscribe(onNext: { _ in
                        Banners.shared.show("\(member.user.name) added to the channel")
                    })
                    .disposed(by: self.disposeBag)
            }
        }))
        
        alert.addAction(.init(title: "Invite a member", style: .default, handler: { [unowned self] _ in
            self.createMember("Invite a member") { member in
                channel.rx
                    .invite(member: member)
                    .subscribe(onNext: { _ in
                        Banners.shared.show("Invite for \(member.user.name) was send")
                    })
                    .disposed(by: self.disposeBag)
            }
        }))
        
        if !channel.members.isEmpty && !onlyYou {
            alert.addAction(.init(title: "Remove a member", style: .destructive, handler: { [unowned self] _ in
                self.removeMember()
            }))
        }
        
        alert.addAction(.init(title: "Cancel", style: .cancel, handler: nil))
        
        present(alert, animated: true)
    }
}
