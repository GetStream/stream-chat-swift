//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

class LoginViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    @IBOutlet var configurationButton: UIButton!
    @IBOutlet var tableView: UITableView!
    var onUserSelection: ((DemoUserType) -> Void)!

    var users: [DemoUserType] {
        UserCredentials.builtInUsers.map { DemoUserType.credentials($0) }
            + [.guest("guest"), .anonymous, .custom(nil)]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self

        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
        if #available(iOS 15.0, *) {
            configurationButton.configuration = .filled()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        navigationController?.isNavigationBarHidden = true
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }

    @IBAction func didTapConfigurationButton(_ sender: Any) {
        let configViewController = AppConfigViewController()
        let navController = UINavigationController(rootViewController: configViewController)
        navController.presentationController?.delegate = self
        present(navController, animated: true, completion: nil)
    }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        tableView.reloadData()
    }
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UserCredentialsCell", for: indexPath) as? UserCredentialsCell else { return UITableViewCell() }
        cell.avatarView.contentMode = .scaleAspectFill

        let user = users[indexPath.row]

        switch user {
        case let .credentials(userCredentials):
            Nuke.loadImage(with: userCredentials.avatarURL, into: cell.avatarView)
            cell.avatarView.backgroundColor = .clear
            cell.nameLabel.text = userCredentials.name
            cell.descriptionLabel.text = "Stream test user"
        case .guest:
            cell.nameLabel.text = "Guest user"
            cell.descriptionLabel.text = "Login as guest"
            cell.avatarView.image = UIImage(systemName: "person.fill")
            cell.avatarView.backgroundColor = .clear
        case .anonymous:
            cell.nameLabel.text = "Anonymous user"
            cell.descriptionLabel.text = ""
            cell.avatarView.image = UIImage(systemName: "person")
            cell.avatarView.backgroundColor = .clear
        case .custom:
            cell.nameLabel.text = "Custom app authentication"
            cell.descriptionLabel.text = "Provide a custom app key and user"
            cell.avatarView.image = UIImage(systemName: "lock")
            cell.avatarView.contentMode = .scaleAspectFill
            cell.avatarView.backgroundColor = .clear
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]

        switch user {
        case .credentials, .anonymous:
            onUserSelection(user)
        case .custom:
            let alert = UIAlertController(
                title: "Custom app authentication",
                message: "Provide your app key and user info",
                preferredStyle: .alert
            )
            alert.addTextField { textField in
                textField.placeholder = "App Key"
                textField.text = apiKeyString
            }
            alert.addTextField { textField in
                textField.placeholder = "User ID"
            }
            alert.addTextField { textField in
                textField.placeholder = "User Token"
            }
            alert.addTextField { textField in
                textField.placeholder = "User Name"
            }
            alert.addTextField { textField in
                textField.placeholder = "User Avatar URL (Optional)"
            }
            alert.addAction(.init(title: "OK", style: .default, handler: { _ in
                let apiKey = alert.textFields?.first?.text
                let userId = alert.textFields?[1].text ?? ""
                let userToken = alert.textFields?[2].text ?? ""
                let userName = alert.textFields?[3].text ?? ""
                let userAvatarURL = alert.textFields?[4].text ?? ""
                let token = (try? Token(rawValue: userToken)) ?? Token.development(userId: userId)
                let userCredentials = UserCredentials(
                    id: userId,
                    name: userName,
                    avatarURL: URL(string: userAvatarURL) ?? URL(string: "https://i.pravatar.cc/300")!,
                    token: token,
                    birthLand: "",
                    customApiKey: apiKey
                )
                self.onUserSelection(.custom(userCredentials))
            }))
            alert.addAction(.init(title: "Cancel", style: .destructive))
            present(alert, animated: true, completion: nil)
        case .guest:
            presentAlert(title: "Input a user id", message: nil, textFieldPlaceholder: "guest") { [weak self] userId in
                if let userId = userId, !userId.isEmpty {
                    self?.onUserSelection(.guest(userId))
                } else {
                    self?.onUserSelection(.guest("guest"))
                }
            }
        }
    }
}
