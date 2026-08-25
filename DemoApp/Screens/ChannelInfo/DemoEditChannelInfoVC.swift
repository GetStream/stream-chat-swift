//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

/// The screen used to change the name and the picture of a group channel.
final class DemoEditChannelInfoVC: UIViewController,
    ThemeProvider,
    UITextFieldDelegate,
    UIImagePickerControllerDelegate,
    UINavigationControllerDelegate {
    private let channelController: ChatChannelController
    private let channel: ChatChannel

    private var pickedImage: UIImage?

    private lazy var avatarView = DemoChannelInfoAvatarView()

    private lazy var uploadButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Upload"
        configuration.baseForegroundColor = appearance.colorPalette.buttonSecondaryText

        let button = UIButton(type: .system)
        button.configuration = configuration
        button.addTarget(self, action: #selector(uploadTapped), for: .touchUpInside)
        return button
    }()

    private lazy var nameTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Group name"
        label.font = appearance.fonts.footnote
        label.textColor = appearance.colorPalette.textSecondary
        label.adjustsFontForContentSizeCategory = true
        return label
    }()

    private lazy var nameTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Add a group name"
        textField.font = appearance.fonts.body
        textField.textColor = appearance.colorPalette.textPrimary
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        textField.addTarget(self, action: #selector(nameChanged), for: .editingChanged)
        return textField
    }()

    private lazy var loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private lazy var saveButton = UIBarButtonItem(
        title: "Save",
        style: .done,
        target: self,
        action: #selector(saveTapped)
    )

    private lazy var cancelButton = UIBarButtonItem(
        title: "Cancel",
        style: .plain,
        target: self,
        action: #selector(cancelTapped)
    )

    init(channelController: ChatChannelController, channel: ChatChannel) {
        self.channelController = channelController
        self.channel = channel
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Group"
        view.backgroundColor = appearance.colorPalette.backgroundCoreApp
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton

        setUpLayout()

        avatarView.content = (channel, channelController.client.currentUserId)
        nameTextField.text = channel.name
        updateSaveButton()
    }

    private func setUpLayout() {
        let avatarContainer = UIView()
        avatarContainer.addSubview(avatarView)
        avatarContainer.addSubview(loadingIndicator)
        avatarView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: avatarContainer.topAnchor),
            avatarView.bottomAnchor.constraint(equalTo: avatarContainer.bottomAnchor),
            avatarView.centerXAnchor.constraint(equalTo: avatarContainer.centerXAnchor),
            avatarView.widthAnchor.constraint(equalToConstant: DemoChannelInfoAvatarView.size),
            avatarView.heightAnchor.constraint(equalToConstant: DemoChannelInfoAvatarView.size),
            loadingIndicator.centerXAnchor.constraint(equalTo: avatarView.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])

        let container = VContainer(spacing: appearance.tokens.spacingMd) {
            avatarContainer
            uploadButton
            VContainer(spacing: appearance.tokens.spacingXxs) {
                nameTitleLabel
                nameTextField
            }
            Spacer()
        }
        view.addSubview(container)
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.topAnchor,
                constant: appearance.tokens.spacingXl
            ),
            container.leadingAnchor.constraint(
                equalTo: view.leadingAnchor,
                constant: appearance.tokens.spacingMd
            ),
            container.trailingAnchor.constraint(
                equalTo: view.trailingAnchor,
                constant: -appearance.tokens.spacingMd
            ),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    private func updateSaveButton() {
        let name = nameTextField.text ?? ""
        saveButton.isEnabled = !name.isEmpty && (name != channel.name || pickedImage != nil)
    }

    private func setLoading(_ isLoading: Bool) {
        isLoading ? loadingIndicator.startAnimating() : loadingIndicator.stopAnimating()
        saveButton.isEnabled = !isLoading
        avatarView.alpha = isLoading ? 0.5 : 1
    }

    @objc private func nameChanged() {
        updateSaveButton()
    }

    @objc private func cancelTapped() {
        dismiss(animated: true)
    }

    @objc private func uploadTapped() {
        var actions: [UIAlertAction] = [
            .init(title: "Choose Image", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(sourceType: .photoLibrary)
            })
        ]
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            actions.append(.init(title: "Take Photo", style: .default, handler: { [weak self] _ in
                self?.presentImagePicker(sourceType: .camera)
            }))
        }

        presentAlert(
            title: "Edit Group Picture",
            actions: actions,
            preferredStyle: .actionSheet,
            sourceView: uploadButton
        )
    }

    private func presentImagePicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        present(picker, animated: true)
    }

    @objc private func saveTapped() {
        let name = nameTextField.text ?? ""

        guard let pickedImage, let localURL = try? saveToTemporaryURL(pickedImage) else {
            updateChannel(name: name, imageURL: channel.imageURL)
            return
        }

        setLoading(true)
        channelController.client.uploadAttachment(localUrl: localURL, progress: nil) { [weak self] result in
            let uploadedURL = try? result.get().fileURL
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                setLoading(false)
                updateChannel(name: name, imageURL: uploadedURL ?? channel.imageURL)
            }
        }
    }

    private func updateChannel(name: String, imageURL: URL?) {
        channelController.updateChannel(
            name: name,
            imageURL: imageURL,
            team: channel.team,
            extraData: channel.extraData
        ) { [weak self] error in
            guard let self else { return }
            if error != nil {
                presentAlert(title: "Something went wrong.")
            } else {
                dismiss(animated: true)
            }
        }
    }

    private func saveToTemporaryURL(_ image: UIImage) throws -> URL {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw ClientError.Unexpected("Failed to encode the picked image.")
        }
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("jpg")
        try data.write(to: url)
        return url
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    // MARK: - UIImagePickerControllerDelegate

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)

        guard let image = info[.originalImage] as? UIImage else { return }
        pickedImage = image
        avatarView.presenceAvatarView.avatarView.imageView.image = image
        updateSaveButton()
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
