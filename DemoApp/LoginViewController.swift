//
// Copyright © 2021 Stream.io Inc. All rights reserved.
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
    var didRequestChatPresentation: ((UserCredentials) -> Void)!
    
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
        
        navigationController?.isNavigationBarHidden = true
        if let selectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: selectedRow, animated: true)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
            if let error = error {
                log.error("Error when enabling notifications: \(error)")
            }
        }
    }
}

extension LoginViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        builtInUsers.count + 1 // +1 for the last static cell
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! UserCredentialsCell
        
        if indexPath.row == builtInUsers.count {
            // Last cell
            cell.nameLabel.text = "Advanced Options"
            cell.descriptionLabel.text = "Custom settings"
            cell.avatarView.image = UIImage(named: "advanced_settings")
            cell.avatarView.backgroundColor = .systemGray
            
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
        guard indexPath.row != builtInUsers.count else {
            // Advanced options
            performSegue(withIdentifier: "show_advanced_options", sender: self)
            return
        }
        
        didRequestChatPresentation(builtInUsers[indexPath.row])
    }
}
