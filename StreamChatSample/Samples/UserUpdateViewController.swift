//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class UserUpdateViewController: UITableViewController {
    var currentUserController: CurrentChatUserController!
    
    var userName: String?
    var imageUrl: URL?
    
    var data: [PartialKeyPath<ChatUser>] = [
        \ChatUser.name,
        \ChatUser.imageURL
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = currentUserController.currentUser?.id
        userName = currentUserController.currentUser?.name
        imageUrl = currentUserController?.currentUser?.imageURL
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        "User Data"
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        
        var inputName: String?
        var inputValue: String?
        
        let keyPath = data[indexPath.row]
        switch keyPath {
        case \ChatUser.name:
            inputName = "Name"
            inputValue = userName
        case \ChatUser.imageURL:
            inputName = "Image URL"
            inputValue = imageUrl?.absoluteString
        default:
            break
        }
        
        cell.textLabel?.text = inputName
        cell.detailTextLabel?.text = inputValue
        cell.accessoryType = .disclosureIndicator

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let cell = tableView.cellForRow(at: indexPath)
        let keyPath = data[indexPath.row]
        let inputVC = InputViewController(
            title: cell?.textLabel?.text ?? "",
            initialValue: cell?.detailTextLabel?.text ?? ""
        )
        inputVC.onChange = { [weak self] newValue in
            guard let self = self else {
                log.warning("Callback called while self is nil")
                return
            }

            switch keyPath {
            case \ChatUser.name:
                self.userName = newValue
            case \ChatUser.imageURL:
                self.imageUrl = URL(string: newValue)
            default:
                break
            }
            tableView.reloadData()
        }
        
        navigationController?.pushViewController(inputVC, animated: true)
    }
    
    @IBAction func save(_ sender: Any) {
        currentUserController.updateUserData(name: userName, imageURL: imageUrl) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.alert(title: "Update failed!", message: error.localizedDescription)
                    return
                }
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}
