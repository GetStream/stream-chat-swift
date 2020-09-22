//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChatClient
import SwiftUI
import UIKit
import UserNotifications

class SettingsViewController: UITableViewController {
    @IBOutlet var logoutCell: UITableViewCell!
    @IBOutlet var clearLocalDatabaseCell: UITableViewCell!
    @IBOutlet var enablePushNotificationsSwitch: UISwitch!
    @IBOutlet var webSocketsConnectionSwitch: UISwitch!
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userSecondaryLabel: UILabel!
    
    var currentUserController: CurrentChatUserController! {
        didSet {
            currentUserController.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateUserCell(with: currentUserController.currentUser)
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch tableView.cellForRow(at: indexPath) {
        case logoutCell:
            logout()
        case clearLocalDatabaseCell:
            clearLocalDatabase()
        default:
            break
        }
    }
}

// MARK: - Current User

extension SettingsViewController {
    func updateUserCell(with user: CurrentChatUser?) {
        if let user = user {
            userNameLabel.text = user.name ?? ""
            userNameLabel.text! += " (\(user.id))"
            
            let unreadCount = user.unreadCount
            userSecondaryLabel.text = "Unread messages: \(unreadCount.messages) - Unread channels: \(unreadCount.channels)"
        }
    }
    
    func logout() {
        currentUserController.disconnect()
        moveToStoryboard(.main, options: .transitionFlipFromRight)
    }
}

// MARK: - Switches

extension SettingsViewController {
    @IBAction
    func pushNotificationsSwitchValueChanged(_ sender: Any) {
        // TODO: Enable/Disable push notifications
    }
    
    @IBAction
    func webSocketsConnectionSwitchValueChanged(_ sender: Any) {
        if webSocketsConnectionSwitch.isOn {
            webSocketsConnectionSwitch.isEnabled = false
            currentUserController.connect { [weak self] error in
                DispatchQueue.main.async {
                    self?.webSocketsConnectionSwitch.isEnabled = true
                    self?.webSocketsConnectionSwitch.setOn(error == nil, animated: true)
                }
            }
        } else {
            currentUserController.disconnect()
        }
    }
}

// MARK: - Tools

extension SettingsViewController {
    func clearLocalDatabase() {
        // TODO: Clear local database
    }
}

// MARK: - CurrentUserControllerDelegate

extension SettingsViewController: CurrentChatUserControllerDelegate {
    func currentUserController(
        _ controller: CurrentChatUserController,
        didChangeCurrentUser change: EntityChange<CurrentChatUser>
    ) {
        updateUserCell(with: change.item)
    }
}

@available(iOS 13.0, *)
struct SettingsView: UIViewControllerRepresentable {
    typealias UIViewControllerType = SettingsViewController
    let currentUserController: CurrentChatUserController
    
    func makeUIViewController(context: Context) -> SettingsViewController {
        let navigationViewController = UIStoryboard.settings.instantiateInitialViewController()!
        let settingsViewController = navigationViewController.children.first as! SettingsViewController
        
        settingsViewController.currentUserController = currentUserController
        
        return settingsViewController
    }
    
    func updateUIViewController(_ uiViewController: SettingsViewController, context: Context) {}
}
