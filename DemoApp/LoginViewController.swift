//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Nuke
import StreamChat
import UIKit

class AvatarView: UIImageView {
    override func updateConstraints() {
        super.updateConstraints()
        translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        clipsToBounds = true
        layer.cornerRadius = frame.width / 2.0
        contentMode = .scaleAspectFill
    }
}

class UserCredentialsCell: UITableViewCell {
    @IBOutlet var mainStackView: UIStackView! {
        didSet {
            mainStackView.isLayoutMarginsRelativeArrangement = true
        }
    }
    
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var descriptionLabel: UILabel!
    
    @IBOutlet var avatarView: AvatarView!
    @IBOutlet var accessoryImageView: UIImageView!
    
    var user: ChatUser?
}

class LoginViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    var didRequestChatPresentation: ((DemoUserType) -> Void)!
    
    let builtInUsers = UserCredentials.builtInUsers
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
                
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Disconnect the current client
        if ChatClient.shared != nil {
            ChatClient.shared = nil
        }
        
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
        builtInUsers.count + 3 // +1 for the last static cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserCredentialsCell
        
        if indexPath.row == builtInUsers.count {
            // Anonymous user
            cell.nameLabel.text = "Anonymous user"
            cell.descriptionLabel.text = ""
            cell.avatarView.image = UIImage(systemName: "person")
            cell.avatarView.backgroundColor = .clear
        } else if indexPath.row == builtInUsers.count + 1 {
            // Guest user
            cell.nameLabel.text = "Guest user"
            cell.descriptionLabel.text = "user id: guest"
            cell.avatarView.image = UIImage(systemName: "person.fill")
            cell.avatarView.backgroundColor = .clear
        } else if indexPath.row == builtInUsers.count + 2 {
            // Advanced options
            cell.nameLabel.text = "Advanced Options"
            cell.descriptionLabel.text = "Custom settings"
            cell.avatarView.image = UIImage(named: "advanced_settings")
            cell.avatarView.backgroundColor = .clear
        } else {
            // Normal cell
            let user = builtInUsers[indexPath.row]
            Nuke.loadImage(with: user.avatarURL, into: cell.avatarView)
            cell.avatarView.backgroundColor = .clear
            cell.nameLabel.text = user.name
            cell.descriptionLabel.text = "Stream test user"
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == builtInUsers.count {
            // Anonymous user
            didRequestChatPresentation(.anonymous)
        } else if indexPath.row == builtInUsers.count + 1 {
            // Guest user
            presentAlert(title: "Input a user id", message: nil, textFieldPlaceholder: "guest") { [weak self] userId in
                if let userId = userId, !userId.isEmpty {
                    self?.didRequestChatPresentation(.guest(userId))
                } else {
                    self?.didRequestChatPresentation(.guest("guest"))
                }
            }
        } else if indexPath.row == builtInUsers.count + 2 {
            // Advanced options
            performSegue(withIdentifier: "show_advanced_options", sender: self)
        } else {
            // Normal cell
            didRequestChatPresentation(.credentials(builtInUsers[indexPath.row]))
        }
    }
}
