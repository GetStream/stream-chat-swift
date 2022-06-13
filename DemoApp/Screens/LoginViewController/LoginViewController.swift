//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

class LoginViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var onUserSelection: ((DemoUserType) -> Void)!
    
    let users: [DemoUserType] = UserCredentials.builtInUsers.map { DemoUserType.credentials($0) } + [.guest("guest"), .anonymous]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
                
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
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
        present(navController, animated: true, completion: nil)
    }
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(with: UserCredentialsCell.self, for: indexPath)
        
        let user = users[indexPath.row]
        
        switch user {
        case let .credentials(userCredentials):
            Nuke.loadImage(with: userCredentials.avatarURL, into: cell.avatarView)
            cell.avatarView.backgroundColor = .clear
            cell.nameLabel.text = userCredentials.name
            cell.descriptionLabel.text = "Stream test user"
        case .guest:
            cell.nameLabel.text = "Guest user"
            cell.descriptionLabel.text = "user id: guest"
            cell.avatarView.image = UIImage(systemName: "person.fill")
            cell.avatarView.backgroundColor = .clear
        case .anonymous:
            cell.nameLabel.text = "Anonymous user"
            cell.descriptionLabel.text = ""
            cell.avatarView.image = UIImage(systemName: "person")
            cell.avatarView.backgroundColor = .clear
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        
        switch user {
        case .credentials, .anonymous:
            onUserSelection(user)
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
