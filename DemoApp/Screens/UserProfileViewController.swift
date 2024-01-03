//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

class UserProfileViewController: UIViewController, CurrentChatUserControllerDelegate {
    private let imageView = UIImageView()
    private let nameTextField = UITextField()
    private let updateButton = UIButton()

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

        view.backgroundColor = .systemBackground

        [imageView, nameTextField, updateButton].forEach {
            view.addSubview($0)
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

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
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            nameTextField.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            nameTextField.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            updateButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            updateButton.topAnchor.constraint(equalTo: nameTextField.bottomAnchor, constant: 20),
            updateButton.heightAnchor.constraint(equalToConstant: 35)
        ])

        currentUserController.delegate = self
        synchronizeAndUpdateData()
    }

    private func synchronizeAndUpdateData() {
        currentUserController.synchronize { [weak self] _ in
            self?.updateUserData()
        }
    }

    private func updateUserData() {
        nameTextField.text = currentUserController.currentUser?.name ?? "Unknown"

        guard let imageURL = currentUserController.currentUser?.imageURL else { return }

        DispatchQueue.global().async { [weak self] in
            guard let data = try? Data(contentsOf: imageURL), let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.imageView.image = image
            }
        }
    }

    @objc private func didTapUpdateButton() {
        guard let newName = nameTextField.text, newName != currentUserController.currentUser?.name else { return }
        currentUserController.updateUserData(name: newName) { [weak self] _ in
            self?.synchronizeAndUpdateData()
        }
    }

    func currentUserController(_ controller: CurrentChatUserController, didChangeCurrentUser: EntityChange<CurrentChatUser>) {
        updateUserData()
    }
}
