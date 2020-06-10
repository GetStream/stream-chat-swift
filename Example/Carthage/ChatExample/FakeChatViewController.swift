//
//  FakeChatViewController.swift
//  ChatExample
//
//  Created by Alexey Bukhtin on 10/06/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import StreamChatCore
import StreamChatClient
@testable import StreamChat

final class FakeChatViewController: ChatViewController {

    @IBOutlet weak var slider: UISlider!
    
    var isUpdating = false
    var allItems = [PresenterItem]()
    
    var messageUser: User = {
        var user = User.anonymous
        user.name = "C U"
        return user
    }()
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Client.configureShared(.init(apiKey: "test"))
        let channel = Client.shared.channel(type: .messaging, id: "test")
        presenter = ChannelPresenter(channel: channel)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = nil
        setupComposerView()
    }
    
    @IBAction func changeUser(_ sender: UIBarButtonItem) {
        if messageUser == .anonymous {
            messageUser = User(id: "1john")
            messageUser.name = "John Doe"
            sender.tintColor = .systemGreen
        } else {
            messageUser = .anonymous
            messageUser.name = "A B"
            sender.tintColor = .systemBlue
        }
    }
    
    @IBAction func removeMessage(_ sender: Any) {
        slider.value = max(0, slider.value - 1)
        sliderDidChange(slider)
    }
    
    @IBAction func addMessage(_ sender: Any) {
        slider.value += 1
        sliderDidChange(slider)
    }
    
    @IBAction func sliderDidChange(_ sender: UISlider) {
        let messageCount = Int(sender.value)
        
        guard messageCount != items.count, !isUpdating else {
            return
        }
        
        isUpdating = true
        
        if items.count < messageCount {
            let range = items.count..<messageCount
            let newItems = generateMoreMessages(count: messageCount)
            let reloadRows = items.count > 0 ? (items.count - 1) : nil
            updateTableView(with: .itemsAdded(Array(range), reloadRows, false, newItems))
        } else {
            let items = self.items.prefix(messageCount)
            updateTableView(with: .reloaded(items.count - 1, Array(items)))
        }
        
        isUpdating = false
    }
    
    @IBAction func generateMessages(_ sender: UIBarButtonItem) {
        let items = generateMoreMessages(count: self.items.count + 30, append: false)
        updateTableView(with: .reloaded(items.count - 1, Array(items)))
        changeUser(sender)
    }
    
    func generateMoreMessages(count: Int, append: Bool = true) -> [PresenterItem] {
        var items = self.items
        let range = items.count..<count
        
        for _ in range {
            var randoms = [Int]()
            
            for _ in 0..<Int.random(in: 1...10) {
                randoms.append(.random(in: 1...99999))
            }
            
            let text = randoms.map(String.init).joined(separator: " ")
            var message = Message(text: text)
            message.user = messageUser
            
            if append {
                items.append(.message(message, []))
            } else {
                items.insert(.message(message, []), at: 0)
            }
        }
        
        return items
    }
}
