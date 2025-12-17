//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import Nuke
import StreamChat
import StreamChatCommonUI
import StreamChatUI
import UIKit

class NameGroupViewController: UIViewController {
    class UserCell: UITableViewCell {
        static let reuseIdentifier = String(describing: NameGroupViewController.UserCell.self)

        let avatarView = AvatarView()
        let nameLabel = UILabel()
        let detailsLabel = UILabel()
        let removeButton = UIButton()
        let premiumImageView = UIImageView(image: .init(systemName: "crown.fill")!)

        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
            setupUI()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            setupUI()
        }

        func setupUI() {
            removeButton.tintColor = Appearance.default.colorPalette.text
            removeButton.setImage(UIImage(systemName: "xmark")!, for: .normal)
            removeButton.imageView?.contentMode = .scaleAspectFit
            removeButton.isUserInteractionEnabled = true
            premiumImageView.contentMode = .scaleAspectFill
            premiumImageView.tintColor = .systemBlue
            premiumImageView.isHidden = true
            detailsLabel.isHidden = true
            detailsLabel.font = .systemFont(ofSize: 14)

            HContainer(spacing: 8, alignment: .center) {
                avatarView
                    .width(30)
                    .height(30)
                VContainer(spacing: 0, alignment: .leading) {
                    nameLabel
                    detailsLabel
                }
                Spacer()
                premiumImageView
                    .width(20)
                    .height(20)
                removeButton
                    .width(30)
                    .height(30)
            }.embedToMargins(in: contentView)
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
        guard let cell = tableView.dequeueReusableCell(withIdentifier: UserCell.reuseIdentifier) as? UserCell else { return UITableViewCell() }
        let user = selectedUsers[indexPath.row]

        if let imageURL = user.imageURL {
            Nuke.loadImage(with: imageURL, into: cell.avatarView)
        }

        cell.nameLabel.text = user.name
        cell.premiumImageView.isHidden = true
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
