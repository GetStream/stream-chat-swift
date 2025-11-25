//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import SwiftUI
import UIKit

class UserProfileViewController: UITableViewController, CurrentChatUserControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    private let imageView = UIImageView()
    private let updateButton = UIButton()
    private let loadingSpinner = UIActivityIndicatorView(style: .medium)

    var name: String?
    let properties = UserProperty.allCases

    enum UserProperty: CaseIterable {
        case name
        case role
        case typingIndicatorsEnabled
        case readReceiptsEnabled
        case deliveryReceiptsEnabled
        case pushPreferences
        case detailedUnreadCounts
        case avgResponseTime
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

        [imageView, updateButton, loadingSpinner].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        tableView.tableHeaderView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableHeaderView?.addSubview(imageView)
        tableView.tableHeaderView?.addSubview(loadingSpinner)
        tableView.tableFooterView = UIView(frame: .init(origin: .zero, size: .init(width: .zero, height: 80)))
        tableView.tableFooterView?.addSubview(updateButton)

        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.isUserInteractionEnabled = true
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapImageView))
        imageView.addGestureRecognizer(tapGesture)
        
        updateButton.setTitle("Update", for: .normal)
        updateButton.layer.cornerRadius = 4
        updateButton.backgroundColor = .systemBlue
        updateButton.contentEdgeInsets = UIEdgeInsets(top: 0.0, left: 15, bottom: 0.0, right: 15)
        updateButton.addTarget(self, action: #selector(didTapUpdateButton), for: .touchUpInside)
        
        loadingSpinner.hidesWhenStopped = true
        loadingSpinner.color = .systemGray

        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 60),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor),
            imageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingSpinner.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            loadingSpinner.centerYAnchor.constraint(equalTo: imageView.centerYAnchor),
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
            let button = UIButton(type: .detailDisclosure, primaryAction: UIAction(handler: { [weak self] _ in
                self?.presentAlert(title: "Name", textFieldPlaceholder: self?.currentUserController.currentUser?.name) { newValue in
                    self?.name = newValue
                    self?.updateUserData()
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
        case .deliveryReceiptsEnabled:
            cell.textLabel?.text = "Delivery Receipts Enabled"
            cell.accessoryView = makeSwitchButton(UserConfig.shared.deliveryReceiptsEnabled ?? true) { newValue in
                UserConfig.shared.deliveryReceiptsEnabled = newValue
            }
        case .pushPreferences:
            cell.textLabel?.text = "Push Preferences"
            cell.detailTextLabel?.text = "Configure notification settings"
            cell.accessoryView = makeButton(title: "Configure", action: { [weak self] in
                self?.showPushPreferences()
            })
        case .detailedUnreadCounts:
            cell.textLabel?.text = "Detailed Unread Counts"
            cell.accessoryView = makeButton(title: "View Details", action: { [weak self] in
                self?.showDetailedUnreads()
            })
        case .avgResponseTime:
            cell.textLabel?.text = "Average Response Time"
            let responseTime = currentUserController.currentUser?.avgResponseTime ?? 0
            let text = "\(responseTime) seconds"
            cell.accessoryView = makeLabel(text)
        }
        return cell
    }

    private func synchronizeAndUpdateData() {
        currentUserController.synchronize()
        updateUserData()
    }

    private func updateUserData() {
        Components.default
            .imageLoader
            .loadImage(
                into: imageView,
                from: currentUserController.currentUser?.imageURL
            )

        if let typingIndicatorsEnabled = currentUserController.currentUser?.privacySettings.typingIndicators?.enabled {
            UserConfig.shared.typingIndicatorsEnabled = typingIndicatorsEnabled
        }
        if let readReceiptsEnabled = currentUserController.currentUser?.privacySettings.readReceipts?.enabled {
            UserConfig.shared.readReceiptsEnabled = readReceiptsEnabled
        }
        if let deliveryReceiptsEnabled = currentUserController.currentUser?.privacySettings.deliveryReceipts?.enabled {
            UserConfig.shared.deliveryReceiptsEnabled = deliveryReceiptsEnabled
        }

        tableView.reloadData()
    }

    private func showDetailedUnreads() {
        let unreadDetailsView = UnreadDetailsView(
            onLoadData: { [weak self] (completion: @escaping (Result<CurrentUserUnreads, Error>) -> Void) in
                self?.currentUserController.loadAllUnreads { result in
                    DispatchQueue.main.async {
                        completion(result)
                    }
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            }
        )
        let hostingController = UIHostingController(rootView: unreadDetailsView)
        hostingController.title = "Unread Details"
        
        present(hostingController, animated: true)
    }
    
    private func showPushPreferences() {
        let pushPreferencesView = PushPreferencesView(
            onSetPreferences: { [weak self] level, completion in
                self?.currentUserController.setPushPreference(level: level) {
                    completion($0.map(\.level))
                }
            },
            onDisableNotifications: { [weak self] date, completion in
                self?.currentUserController.snoozePushNotifications(until: date) {
                    completion($0.map(\.level))
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            },
            initialPreference: currentUserController.currentUser?.pushPreference
        )
        let hostingController = UIHostingController(rootView: pushPreferencesView)
        hostingController.title = "Push Preferences"
        present(hostingController, animated: true)
    }

    @objc private func didTapUpdateButton() {
        currentUserController.updateUserData(
            name: name,
            privacySettings: .init(
                typingIndicators: UserConfig.shared.typingIndicatorsEnabled.map { .init(enabled: $0) },
                readReceipts: UserConfig.shared.readReceiptsEnabled.map { .init(enabled: $0) },
                deliveryReceipts: UserConfig.shared.deliveryReceiptsEnabled.map { .init(enabled: $0) }
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
    
    private func makeLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 1
        label.sizeToFit()
        return label
    }
    
    // MARK: - Avatar Change
    
    @objc private func didTapImageView() {
        let alertController = UIAlertController(title: "Change Avatar", message: nil, preferredStyle: .actionSheet)
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            alertController.addAction(UIAlertAction(title: "Take Photo", style: .default) { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Choose from Library", style: .default) { [weak self] _ in
            self?.presentImagePicker(sourceType: .photoLibrary)
        })
        
        if currentUserController.currentUser?.imageURL != nil {
            alertController.addAction(UIAlertAction(title: "Delete Avatar", style: .destructive) { [weak self] _ in
                self?.deleteAvatar()
            })
        }
        
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = imageView
            popover.sourceRect = imageView.bounds
        }
        
        present(alertController, animated: true)
    }
    
    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        
        guard let selectedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage) else {
            return
        }
        
        loadingSpinner.startAnimating()
        
        uploadImageAndUpdateProfile(selectedImage) { [weak self] error in
            self?.loadingSpinner.stopAnimating()
            if let error = error {
                self?.showError(error)
            } else {
                self?.showSuccess()
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    private func uploadImageAndUpdateProfile(_ image: UIImage, completion: @escaping (Error?) -> Void) {
        guard let imageData = image.pngData() else {
            completion(NSError(domain: "UserProfile", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to PNG data"]))
            return
        }
        
        // Create temporary file
        let imageURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("avatar_\(UUID().uuidString).png")
        
        do {
            try imageData.write(to: imageURL)
        } catch {
            completion(error)
            return
        }
        
        let uploadingState = AttachmentUploadingState(
            localFileURL: imageURL,
            state: .pendingUpload,
            file: .init(type: .png, size: Int64(imageData.count), mimeType: "image/png")
        )
        
        let attachment = StreamAttachment(
            type: .image,
            payload: imageData,
            downloadingState: nil,
            uploadingState: uploadingState
        )
        
        // Upload the image
        currentUserController.client.upload(attachment, progress: { progress in
            print("Upload progress: \(progress)")
        }, completion: { [weak self] result in
            // Clean up temporary file
            try? FileManager.default.removeItem(at: imageURL)
            
            switch result {
            case .success(let file):
                // Update user profile with new image URL
                self?.currentUserController.updateUserData(imageURL: file.fileURL) { error in
                    completion(error)
                }
            case .failure(let error):
                completion(error)
            }
        })
    }
    
    private func deleteAvatar() {
        guard let imageURL = currentUserController.currentUser?.imageURL else {
            return
        }
        
        loadingSpinner.startAnimating()
        
        // Delete the attachment from CDN
        currentUserController.client.deleteAttachment(remoteUrl: imageURL, attachmentType: .image) { [weak self] error in
            if let error = error {
                self?.loadingSpinner.stopAnimating()
                self?.showError(error)
            } else {
                // Only update user data if deletion was successful
                self?.currentUserController.updateUserData(unsetProperties: ["image"]) { updateError in
                    self?.loadingSpinner.stopAnimating()
                    
                    if let updateError = updateError {
                        self?.showError(updateError)
                    } else {
                        self?.updateUserData()
                        let alert = UIAlertController(
                            title: "Success",
                            message: "Avatar deleted successfully!",
                            preferredStyle: .alert
                        )
                        alert.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(alert, animated: true)
                    }
                }
            }
        }
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Upload Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func showSuccess() {
        let alert = UIAlertController(
            title: "Success",
            message: "Avatar updated successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
