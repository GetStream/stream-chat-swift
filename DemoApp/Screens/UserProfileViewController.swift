//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class UserProfileViewController: UITableViewController, CurrentChatUserControllerDelegate {
    private let imageView = UIImageView()
    private let updateButton = UIButton()

    var name: String?
    let properties = UserProperty.allCases

    enum UserProperty: CaseIterable {
        case name
        case role
        case typingIndicatorsEnabled
        case readReceiptsEnabled
    }

    let currentUserController: CurrentChatUserController

    init(currentUserController: CurrentChatUserController) {
        self.currentUserController = currentUserController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        view.backgroundColor = .systemBackground

        [imageView, updateButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        tableView.tableHeaderView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableHeaderView?.addSubview(imageView)
        tableView.tableFooterView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableFooterView?.addSubview(updateButton)

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        updateButton.setTitle("Update", for: .normal)
        updateButton.layer.cornerRadius = 4
        updateButton.backgroundColor = .systemBlue
        updateButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15, bottom: 0.0, right: 15)
        updateButton.addTarget(self, action: #selector(didTapUpdateButton), for: .touchUpInside)
        updateButton.isHidden = !StreamRuntimeCheck.isStreamInternalConfiguration

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.heightAnchor.constraint(equalToConstant: 35),
            updateButton.centerYAnchor.constraint(equalTo: updateButton.superview!.centerYAnchor)
        ])

        currentUserController.delegate = self
        synchronizeAndUpdateData()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        properties.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        switch properties[indexPath.row] {
        case .name:
            cell.textLabel?.text = "Name"
            cell.detailTextLabel?.text = name ?? currentUserController.currentUser?.name
            let button = UIButton(type: .detailDisclosure, primaryAction: UIAction(handler: { _ in
                self.presentAlert(title: "Name", textFieldPlaceholder: self.currentUserController.currentUser?.name) { newValue in
                    self.name = newValue
                    self.updateUserData()
                }
            }))
            button.setImage(.init(systemName: "pencil"), for: .normal)
            cell.accessoryView = button
        case .role:
            let role = currentUserController.currentUser?.userRole
            let isAdmin = role == UserRole.admin
            cell.textLabel?.text = "User Role"
            cell.detailTextLabel?.text = role?.rawValue ?? "<unknown>"
            cell.accessoryView = makeButton(title: isAdmin ? "Downgrade" : "Upgrade", action: { [weak currentUserController] in
                currentUserController?.updateUserData(role: isAdmin ? .user : .admin)
            })
        case .readReceiptsEnabled:
            cell.textLabel?.text = "Read Receipts Enabled"
            cell.accessoryView = makeSwitchButton(UserConfig.shared.readReceiptsEnabled ?? true) { newValue in
                UserConfig.shared.readReceiptsEnabled = newValue
            }
        case .typingIndicatorsEnabled:
            cell.textLabel?.text = "Typing Indicators Enabled"
            cell.accessoryView = makeSwitchButton(UserConfig.shared.typingIndicatorsEnabled ?? true) { newValue in
                UserConfig.shared.typingIndicatorsEnabled = newValue
            }
        }
        return cell
    }

    private func synchronizeAndUpdateData() {
        currentUserController.synchronize()
        updateUserData()
    }

    private func updateUserData() {
        guard let imageURL = currentUserController.currentUser?.imageURL else { return }
        DispatchQueue.global().async { [weak self] in
            guard let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }

        if let typingIndicatorsEnabled = currentUserController.currentUser?.privacySettings.typingIndicators?.enabled {
            UserConfig.shared.typingIndicatorsEnabled = typingIndicatorsEnabled
        }
        if let readReceiptsEnabled = currentUserController.currentUser?.privacySettings.readReceipts?.enabled {
            UserConfig.shared.readReceiptsEnabled = readReceiptsEnabled
        }

        tableView.reloadData()
    }

    @objc private func didTapUpdateButton() {
        currentUserController.updateUserData(
            name: name,
            privacySettings: .init(
                typingIndicators: UserConfig.shared.typingIndicatorsEnabled.map { .init(enabled: $0) },
                readReceipts: UserConfig.shared.readReceiptsEnabled.map { .init(enabled: $0) }
            )
        )
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {
        name = controller.currentUser?.name
        updateUserData()
    }

    private func makeSwitchButton(_ initialValue: Bool, _ didChangeValue: @escaping (Bool) -> Void) -> SwitchButton {
        let switchButton = SwitchButton()
        switchButton.isOn = initialValue
        switchButton.didChangeValue = didChangeValue
        return switchButton
    }

    private func makeButton(title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addAction(UIAction(handler: { _ in action() }), for: .touchUpInside)
        button.sizeToFit()
        return button
    }
}
