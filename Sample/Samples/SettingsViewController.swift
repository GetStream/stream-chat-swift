//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
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
    
    lazy var connectionController: ChatConnectionController = {
        currentUserController.client.connectionController()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateUserCell(with: currentUserController.currentUser)
        currentUserController.synchronize()
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let userUpdateVC = segue.destination as? UserUpdateViewController {
            userUpdateVC.currentUserController = currentUserController
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
        connectionController.disconnect()
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
            connectionController.connect { [weak self] error in
                DispatchQueue.main.async {
                    self?.webSocketsConnectionSwitch.isEnabled = true
                    self?.webSocketsConnectionSwitch.setOn(error == nil, animated: true)
                }
            }
        } else {
            connectionController.disconnect()
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
        // We're not interested in details about the change so we can ignore the `change` value
        // and use the current version of `currentUser` from the controller.
        updateUserCell(with: controller.currentUser)
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
