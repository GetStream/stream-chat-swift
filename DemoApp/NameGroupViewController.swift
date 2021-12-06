//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat
import UIKit

class NameGroupViewController: UIViewController {
    class UserCell: UITableViewCell {
        static let reuseIdentifier = String(describing: self)
        
        let avatarView = AvatarView()
        let nameLabel = UILabel()
        let removeButton = UIButton()
        
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }
        
        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }
        
        func setupUI() {
            [avatarView, nameLabel, removeButton].forEach {
                $0.translatesAutoresizingMaskIntoConstraints = false
                contentView.addSubview($0)
            }
            
            removeButton.tintColor = .black
            removeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
            removeButton.imageView?.contentMode = .scaleAspectFit
            
            NSLayoutConstraint.activate([
                // AvatarView
                avatarView.leftAnchor.constraint(equalTo: contentView.leftAnchor, constant: 0),
                avatarView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: contentView.layoutMargins.top),
                avatarView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -contentView.layoutMargins.bottom),
                avatarView.heightAnchor.constraint(equalToConstant: 40),
                avatarView.widthAnchor.constraint(equalTo: avatarView.heightAnchor),
                
                // NameLabel
                nameLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: contentView.layoutMargins.left),
                nameLabel.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor),
                
                // removeButton
                removeButton.leftAnchor.constraint(equalTo: nameLabel.rightAnchor, constant: contentView.layoutMargins.left),
                removeButton.rightAnchor.constraint(equalTo: contentView.rightAnchor, constant: -contentView.layoutMargins.right),
                removeButton.widthAnchor.constraint(equalToConstant: 10),
                removeButton.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
            ])
        }
    }
    
    var client: ChatClient?
    
    let mainStackView = UIStackView()
    
    let searchStackView = UIStackView()
    let promptLabel = UILabel()
    let nameField = UITextField()
    let tableView = UITableView()
    
    lazy var doneButton: UIBarButtonItem = UIBarButtonItem(
        image: UIImage(systemName: "checkmark"),
        style: .done,
        target: self,
        action: #selector(doneTapped)
    )
    
    var selectedUsers: [ChatUser]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Name of Group Chat"
        
        navigationItem.rightBarButtonItem = doneButton
        
        promptLabel.text = "NAME"
        promptLabel.font = .systemFont(ofSize: 12, weight: .light)
        nameField.placeholder = "Choose a group chat name"
        
        searchStackView.axis = .horizontal
        searchStackView.distribution = .fillProportionally
        searchStackView.alignment = .fill
        searchStackView.spacing = 16
        searchStackView.addArrangedSubview(promptLabel)
        searchStackView.addArrangedSubview(nameField)
        
        view.addSubview(mainStackView)
        mainStackView.axis = .vertical
        mainStackView.addArrangedSubview(searchStackView)
        mainStackView.addArrangedSubview(tableView)
        mainStackView.isLayoutMarginsRelativeArrangement = true
        mainStackView.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.register(UserCell.self, forCellReuseIdentifier: UserCell.reuseIdentifier)
        tableView.dataSource = self
        tableView.bounces = false
        
        // An old trick to force the table view to hide empty lines
        tableView.tableFooterView = UIView()
        
        NSLayoutConstraint.activate([
            searchStackView.heightAnchor.constraint(equalToConstant: 56),
            
            mainStackView.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            mainStackView.leftAnchor.constraint(equalTo: view.layoutMarginsGuide.leftAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor),
            mainStackView.rightAnchor.constraint(equalTo: view.layoutMarginsGuide.rightAnchor)
        ])
        
        tableView.reloadData()
    }
    
    @objc func doneTapped() {
        guard let name = nameField.text, !name.isEmpty else {
            presentAlert(title: "Name cannot be empty")
            return
        }
        do {
            let channelController = try client?.channelController(
                createChannelWithId: .init(type: .messaging, id: String(UUID().uuidString.prefix(10))),
                name: name,
                members: Set(selectedUsers.map(\.id))
            )
            channelController?.synchronize { error in
                if let error = error {
                    self.presentAlert(title: "Error when creating the channel", message: error.localizedDescription)
                } else {
                    self.navigationController?.popToRootViewController(animated: true)
                }
            }
        } catch {
            presentAlert(title: "Error when creating the channel", message: error.localizedDescription)
        }
    }
}

extension NameGroupViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        selectedUsers.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier) as! UserCell
        let user = selectedUsers[indexPath.row]
        
        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }
        
        cell.nameLabel.text = user.name
        cell.removeButton.addAction(.init(handler: { [weak self] _ in
            guard let self = self else { return }
            if let index = self.selectedUsers.firstIndex(of: user) {
                self.selectedUsers.remove(at: index)
                
                if self.selectedUsers.isEmpty {
                    self.doneButton.isEnabled = false
                }
                
                tableView.performBatchUpdates {
                    tableView.deleteRows(at: [IndexPath(row: index, section: 0)], with: .automatic)
                }
            }
        }), for: .touchUpInside)
        
        return cell
    }
}
