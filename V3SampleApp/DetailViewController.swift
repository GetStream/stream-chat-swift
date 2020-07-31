//
//  DetailViewController.swift
//  V3SampleApp
//
//  Created by Vojta on 28/05/2020.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient_v3

class DetailViewController: UIViewController {
    
    private let tableView = UITableView()
    
    private lazy var controller = chatClient.channelController(for: channelId)
    
    var messages: [Message] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var channelId: ChannelId!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leftAnchor.constraint(equalTo: view.leftAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.rightAnchor.constraint(equalTo: view.rightAnchor),
        ])
        
        controller.delegate = self
        controller.startUpdating()
        
        tableView.reloadData()
    }

}

extension DetailViewController: ChannelControllerDelegate {
    func channelController(_ channelController: ChannelController, didUpdateChannel channel: Channel) {
        messages = channel.latestMessages
    }
}

extension DetailViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell!
        if let _cell = tableView.dequeueReusableCell(withIdentifier: "MessageCell") {
            cell = _cell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MessageCell")
        }
        
        let message = messages[indexPath.row]
        cell.textLabel?.text = "\(message.author.id): \(message.text)"
        
        return cell
    }
}

