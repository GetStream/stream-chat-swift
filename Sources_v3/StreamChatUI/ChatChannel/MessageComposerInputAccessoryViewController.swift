//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

open class MessageComposerInputAccessoryViewController<ExtraData: UIExtraDataTypes>: UIInputViewController,
    UIConfigProvider,
    UITextViewDelegate,
    UIImagePickerControllerDelegate,
    UIDocumentPickerDelegate,
    UINavigationControllerDelegate {
    // MARK: - Properties
    
    var controller: _ChatChannelController<ExtraData>!
    
    // MARK: - Subviews
        
    public private(set) lazy var composerView: ChatChannelMessageComposerView<ExtraData> = {
        ChatChannelMessageComposerView<ExtraData>(uiConfig: uiConfig).withoutAutoresizingMaskConstraints
    }()
    
    public private(set) lazy var suggestionsViewController: MessageComposerSuggestionsViewController<ExtraData> = {
        .init(uiConfig: uiConfig)
    }()
    
    public private(set) lazy var imagePicker: UIImagePickerController = {
        let picker = UIImagePickerController()
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.sourceType = .photoLibrary
        picker.delegate = self
        return picker
    }()
    
    // MARK: Setup
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        setupInputView()
        setUpLayout()
    }
    
    func setupInputView() {
        inputView = composerView
        
        composerView.messageInputView.textView.delegate = self
        composerView.attachmentButton.addTarget(self, action: #selector(showImagePicker), for: .touchUpInside)
        composerView.sendButton.addTarget(self, action: #selector(sendMessage), for: .touchUpInside)
        composerView.messageInputView.rightAccessoryButton.addTarget(
            self,
            action: #selector(dismissSlashCommand),
            for: .touchUpInside
        )
        
        composerView.attachmentsView.didTapRemoveItemButton = { [weak self] index in self?.imageAttachments.remove(at: index) }
    }
    
    public func setUpLayout() {
        guard let inputView = inputView else { return }
        
        composerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        composerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        composerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        composerView.topAnchor.constraint(equalTo: inputView.topAnchor).isActive = true
    }
    
    // MARK: Button actions
    
    @objc func sendMessage() {
        guard let text = composerView.messageInputView.textView.text,
            !text.replacingOccurrences(of: " ", with: "").isEmpty
        else { return }
        
        controller?.createNewMessage(text: text)
        composerView.messageInputView.textView.text = ""
    }
    
    @objc func showImagePicker() {
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func dismissSlashCommand() {
        composerView.messageInputView.rightAccessoryButton.isHidden = true
        composerView.messageInputView.container.leftStackView.isHidden = true
    }
    
    // MARK: Suggestions
    
    func showSuggestionsViewController() {
        addChild(suggestionsViewController)
        view.addSubview(suggestionsViewController.view)
        suggestionsViewController.didMove(toParent: self)
    }
    
    func dismissSuggestionsViewController() {
        suggestionsViewController.removeFromParent()
        suggestionsViewController.view.removeFromSuperview()
    }
    
    // MARK: Attachments
    
    var imageAttachments: [UIImage] = [] {
        didSet {
            didUpdateImageAttachments()
        }
    }
    
    func didUpdateImageAttachments() {
        composerView.attachmentsView.previews = imageAttachments
        composerView.attachmentsView.isHidden = imageAttachments.isEmpty
        composerView.invalidateIntrinsicContentSize()
    }
    
    // MARK: UITextView
    
    func promptSuggestionIfNeeded(for textView: UITextView) {
        if textView.text == "\\" {
            showSuggestionsViewController()
        }
    }
    
    func replaceTextWithSlashCommandViewIfNeeded(for textView: UITextView) {
        if textView.text == "\\giphy" {
            textView.text = ""
            composerView.messageInputView.slashCommandView.command = .giphy
            composerView.messageInputView.container.leftStackView.isHidden = false
            composerView.messageInputView.rightAccessoryButton.isHidden = false
            dismissSuggestionsViewController()
        }
    }
    
    // MARK: - UITextViewDelegate
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = view
        return true
    }

    public func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
        composerView.messageInputView.textView.inputAccessoryView = nil
        return true
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        promptSuggestionIfNeeded(for: textView)
        replaceTextWithSlashCommandViewIfNeeded(for: textView)
    }

    // MARK: - UIImagePickerControllerDelegate
    
    public func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let selectedImage = info[.originalImage] as? UIImage else { return }
        
        imageAttachments.append(selectedImage)
        picker.dismiss(animated: true, completion: nil)
    }
}
