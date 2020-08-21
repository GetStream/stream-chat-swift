//
//  SettingsViewController.swift
//  Sample
//
//  Created by Matheus Cardoso on 19/08/20.
//  Copyright © 2020 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import UserNotifications

class SettingsViewController: UITableViewController {
    @IBOutlet weak var logoutCell: UITableViewCell!
    @IBOutlet weak var enablePushNotificationsSwitch: UISwitch!
    @IBOutlet weak var webSocketsConnectionSwitch: UISwitch!
    
    @IBOutlet weak var userNameLabel: UILabel!
    @IBOutlet weak var userSecondaryLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let user = chatClient.currentUser {
            userNameLabel.text = user.name ?? ""
            userNameLabel.text! += " (\(user.id))"
            
            let unreadCount = user.unreadCount
            userSecondaryLabel.text = "Unread messages: \(unreadCount.messages)\n"
            userSecondaryLabel.text! += "Unread channels: \(unreadCount.channels)"
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch tableView.cellForRow(at: indexPath) {
        case logoutCell:
            logout()
        default:
            break
        }
    }
    @IBAction func pushNotificationsSwitchValueChanged(_ sender: Any) {
        // TODO: Enable/Disable push notifications
    }
    
    @IBAction func webSocketsConnectionSwitchValueChanged(_ sender: Any) {
        if webSocketsConnectionSwitch.isOn {
            webSocketsConnectionSwitch.isEnabled = false
            chatClient.connect { [weak self] error in
                DispatchQueue.main.async {
                    self?.webSocketsConnectionSwitch.isEnabled = true   
                    self?.webSocketsConnectionSwitch.setOn(error == nil, animated: true)
                }
            }
        } else {
            chatClient.disconnect()
        }
    }
}

// MARK: - Actions
extension SettingsViewController {
    func logout() {
        chatClient.disconnect()
        moveToStoryboard(.main, options: .transitionFlipFromRight)
    }
}
