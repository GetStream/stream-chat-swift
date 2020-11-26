//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import Nuke
import UIKit

struct UserCredentials {
    let id: String
    let name: String
    let description: String
    let token: String
}

extension UserCredentials {
    var avatarURL: URL {
        URL(
            string: "https://getstream.io/random_png/?name=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)"
        )!
    }
}

let builtInUsers: [UserCredentials] = [
    UserCredentials(
        id: "broken-waterfall-5",
        name: "Broken Waterfall",
        description: "Stream test user",
        // swiftlint:disable:next line_length
        token: "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1c2VyX2lkIjoiYnJva2VuLXdhdGVyZmFsbC01In0.d1xKTlD_D0G-VsBoDBNbaLjO-2XWNA8rlTm4ru4sMHg"
    ),
    
    UserCredentials(
        id: "suspicious-coyote-3",
        name: "Suspicious Coyote",
        description: "Stream test user",
        // swiftlint:disable:next line_length
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3VzcGljaW91cy1jb3lvdGUtMyJ9.xVaBHFTexlYPEymPmlgIYCM5M_iQVHrygaGS1QhkaEE"
    ),
    
    UserCredentials(
        id: "steep-moon-9",
        name: "Steep Moon",
        description: "Stream test user",
        // swiftlint:disable:next line_length
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoic3RlZXAtbW9vbi05In0.xwGjOwnTy3r4o2owevNTyzZLWMsMh_bK7e5s1OQ2zXU"
    )
]

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
}

class LoginViewController: UIViewController {
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.bounces = false
        
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
            cell.descriptionLabel.text = user.description
        }
                
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.row != builtInUsers.count else {
            // Advanced options
            performSegue(withIdentifier: "show_advanced_options", sender: self)
            return
        }
        
        presentChat(apiKey: "qk4nn7rpcn75", userCredentials: builtInUsers[indexPath.row])
    }
}
