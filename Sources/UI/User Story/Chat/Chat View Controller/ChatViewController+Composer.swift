//
//  ChatViewController+Composer.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import Photos.PHPhotoLibrary
import SnapKit
import RxSwift
import RxCocoa

// MARK: - Composer

public extension ChatViewController {
    enum ComposerAddFileType {
        case photo
        case camera
        case file
        case custom(icon: UIImage?, title: String, ComposerAddFileView.SourceType, ComposerAddFileView.Action)
    }
}

extension ChatViewController {
    
    func createComposerView() -> ComposerView {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }
    
    func setupComposerView() {
        composerView.attachmentButton.isHidden = composerAddFileContainerView == nil
        composerView.addToSuperview(view)
        
        if let composerAddFileContainerView = composerAddFileContainerView {
            composerAddFileContainerView.add(to: composerView)
            
            composerView.attachmentButton.rx.tap
                .subscribe(onNext: { [weak self] in self?.showAddFileView() })
                .disposed(by: disposeBag)
        }

        composerView.textView.rx.text
            .skip(1)
            .unwrap()
            .do(onNext: { [weak self] in self?.dispatchCommands(in: $0) })
            .filter { [weak self] in !$0.isBlank && (self?.channelPresenter?.channel.config.typingEventsEnabled ?? false) }
            .flatMap { [weak self] text in self?.channelPresenter?.sendEvent(isTyping: true) ?? .empty() }
            .debounce(.seconds(3), scheduler: MainScheduler.instance)
            .flatMap { [weak self] text in self?.channelPresenter?.sendEvent(isTyping: false) ?? .empty() }
            .subscribe()
            .disposed(by: disposeBag)
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .skip(1)
            .drive(onNext: { [weak self] in self?.updateTableViewContentInsetForKeyboardHeight($0) })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
            .drive(onNext: { [weak self] in self?.updateTableViewContentOffsetForKeyboardHeight($0) })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.isHidden
            .skip(1)
            .filter { $0 }
            .drive(onNext: { [weak self] _ in self?.showCommands(show: false) })
            .disposed(by: disposeBag)
    }
    
    private func updateTableViewContentInsetForKeyboardHeight(_ height: CGFloat) {
        height > 0 ? tableView.saveContentInsetState() : tableView.resetContentInsetState()
        let bottom = .messagesToComposerPadding + max(0, height - (height > 0 ? tableView.oldAdjustedContentInset.bottom : 0))
        tableView.contentInset.bottom = bottom
    }
    
    private func updateTableViewContentOffsetForKeyboardHeight(_ height: CGFloat) {
        var contentOffset = tableView.contentOffset
        contentOffset.y += height - view.safeAreaBottomOffset - (height > 0 ? .messagesToComposerPadding : 0)
        tableView.contentOffset = contentOffset
    }
    
    private func dispatchCommands(in text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        showCommandsIfNeeded(for: trimmedText)
        
        // Send command by <Return> key.
        if composerCommandsContainerView.shouldBeShown, text.contains("\n"), trimmedText.contains(" ") {
            composerView.textView.text = trimmedText
            send()
        }
    }
    
    /// Send a message.
    public func send() {
        let text = composerView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isMessageEditing = channelPresenter?.editMessage != nil
        
        if findCommand(in: text) != nil || isMessageEditing {
            view.endEditing(true)
        }
        
        if isMessageEditing {
            composerEditingContainerView.animate(show: false)
        }
        
        composerView.isEnabled = false
        
        channelPresenter?.send(text: text)
            .subscribe(onNext: { [weak self] _ in self?.composerView.reset() },
                       onError: { [weak self] in
                        self?.composerView.reset()
                        self?.show(error: $0)
            })
            .disposed(by: disposeBag)
    }
    
    private func findCommand(in text: String) -> String? {
        guard text.count > 1, text.hasPrefix("/") else {
            return nil
        }
        
        var command: String
        
        if let spaceIndex = text.firstIndex(of: " ") {
            command = String(text.prefix(upTo: spaceIndex))
        } else {
            command = text
        }
        
        command = command.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .init(charactersIn: "/"))
        
        return command.isBlank ? nil : command
    }
    
    public func createComposerHelperContainerView(title: String,
                                                  closeButtonIsHidden: Bool = false) -> ComposerHelperContainerView {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.composer.helperContainerBackgroundColor
        container.titleLabel.text = title
        container.add(to: composerView)
        container.isHidden = true
        container.closeButton.isHidden = closeButtonIsHidden
        return container
    }
}

// MARK: - Composer Edit

extension ChatViewController {
    func createComposerEditingContainerView() -> ComposerHelperContainerView {
        let container = createComposerHelperContainerView(title: "Edit message")
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    self.channelPresenter?.editMessage = nil
                    self.composerView.reset()
                    self.hideAddFileView()
                    self.composerEditingContainerView.animate(show: false)
                    
                    if self.composerView.textView.isFirstResponder {
                        self.composerView.textView.resignFirstResponder()
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return container
    }
}

// MARK: - Composer Commands

extension ChatViewController {
    
    func createComposerCommandsContainerView() -> ComposerHelperContainerView {
        let container = createComposerHelperContainerView(title: "Commands", closeButtonIsHidden: true)
        container.isEnabled = !(channelPresenter?.channel.config.commands.isEmpty ?? true)
        
        if container.isEnabled, let channelConfig = channelPresenter?.channel.config {
            channelConfig.commands.forEach { command in
                let view = ComposerCommandView(frame: .zero)
                view.backgroundColor = container.backgroundColor
                view.update(command: command.name, args: command.args, description: command.description)
                container.containerView.addArrangedSubview(view)
                
                view.rx.tapGesture().when(.recognized)
                    .subscribe(onNext: { [weak self] _ in self?.addCommandToComposer(command: command.name) })
                    .disposed(by: self.disposeBag)
            }
        }
        
        return container
    }
    
    private func showCommandsIfNeeded(for text: String) {
        guard composerCommandsContainerView.isEnabled else {
            return
        }
        
        // Show composer helper container.
        if text.count == 1, let first = text.first, first == "/" {
            hideAddFileView()
            showCommands()
            return
        }
        
        if textHasCommand(text) {
            hideAddFileView()
            showCommands()
        } else {
            showCommands(show: false)
        }
    }
    
    func textHasCommand(_ text: String) -> Bool {
        guard !text.isBlank, text.first == "/" else {
            return false
        }
        
        guard let command = findCommand(in: text) else {
            composerCommandsContainerView.containerView.arrangedSubviews.forEach { $0.isHidden = false }
            return false
        }
        
        var visible = false
        let hasSpace = text.contains(" ")
        
        composerCommandsContainerView.containerView.arrangedSubviews.forEach {
            if let commandView = $0 as? ComposerCommandView {
                commandView.isHidden = hasSpace ? commandView.command != command : !commandView.command.hasPrefix(command)
                visible = visible || !commandView.isHidden
            }
        }
        
        return visible
    }
    
    private func showCommands(show: Bool = true) {
        composerCommandsContainerView.animate(show: show)
        composerView.textView.autocorrectionType = show ? .no : .default
        
        if composerEditingContainerView.isHidden == false {
            composerEditingContainerView.moveContainerViewPosition(aboveView: show ? composerCommandsContainerView : nil)
        }
    }
    
    func addCommandToComposer(command: String) {
        let trimmedText = composerView.textView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedText.contains(" ") else {
            composerView.textView.text = "/\(command) "
            return
        }
    }
}

// MARK: - Composer Attachments

extension ChatViewController {
    
    /// Creates a add files container view for the composer view when the add button ⊕ is tapped.
    ///
    /// - Returns: a container helper view.
    open func createComposerAddFileContainerView(title: String) -> ComposerHelperContainerView? {
        guard !composerAddFileTypes.isEmpty else {
            return nil
        }
        
        let container = createComposerHelperContainerView(title: title)
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.hideAddFileView() })
            .disposed(by: disposeBag)
        
        composerAddFileTypes.forEach { type in
            switch type {
            case .photo:
                if UIImagePickerController.hasPermissionDescription(for: .savedPhotosAlbum),
                    UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
                    addButtonToAddFileView(container,
                                           icon: UIImage.Icons.images,
                                           title: "Upload a photo or video",
                                           sourceType: .photo(.savedPhotosAlbum)) { [weak self] in
                                            self?.showImagePicker(composerAddFileViewSourceType: $0)
                    }
                    
                    composerView.imagesAddAction = { [weak self] _ in
                        self?.showImagePicker(composerAddFileViewSourceType: .photo(.savedPhotosAlbum))
                    }
                }
            case .camera:
                if UIImagePickerController.hasPermissionDescription(for: .camera),
                    UIImagePickerController.isSourceTypeAvailable(.camera) {
                    addButtonToAddFileView(container,
                                           icon: UIImage.Icons.camera,
                                           title: "Upload from a camera",
                                           sourceType: .photo(.camera)) { [weak self] in
                                            self?.showImagePicker(composerAddFileViewSourceType: $0)
                    }
                }
            case .file:
                addButtonToAddFileView(container,
                                       icon: UIImage.Icons.file,
                                       title: "Upload a file",
                                       sourceType: .file) { [weak self] _ in
                                        self?.showDocumentPicker()
                }
            case let .custom(icon, title, sourceType, action):
                addButtonToAddFileView(container,
                                       icon: icon,
                                       title: title,
                                       sourceType: sourceType,
                                       action: action)
            }
        }
        
        return container
    }
    
    private func addButtonToAddFileView(_ container: ComposerHelperContainerView,
                                        icon: UIImage?,
                                        title: String,
                                        sourceType: ComposerAddFileView.SourceType,
                                        action: @escaping ComposerAddFileView.Action) {
        let view = ComposerAddFileView(icon: icon, title: title, sourceType: sourceType, action: action)
        view.backgroundColor = container.backgroundColor
        container.containerView.addArrangedSubview(view)
    }
    
    private func showAddFileView() {
        guard let composerAddFileContainerView = composerAddFileContainerView,
            !composerAddFileContainerView.containerView.arrangedSubviews.isEmpty else {
            return
        }
        
        showCommands(show: false)
        
        composerAddFileContainerView.containerView.arrangedSubviews.forEach { subview in
            if let addFileView = subview as? ComposerAddFileView {
                if case .file = addFileView.sourceType {
                    addFileView.isHidden = !composerView.imageUploaderItems.isEmpty
                } else {
                    addFileView.isHidden = !composerView.isUploaderFilesEmpty
                }
            }
        }
        
        let subviews = composerAddFileContainerView.containerView.arrangedSubviews.filter { $0.isHidden == false }
        
        if subviews.count == 1, let first = subviews.first as? ComposerAddFileView {
            first.tap()
        } else {
            composerAddFileContainerView.animate(show: true)
            
            if composerEditingContainerView.isHidden == false {
                composerEditingContainerView.moveContainerViewPosition(aboveView: composerAddFileContainerView)
            }
        }
    }
    
    /// Hide add file view.
    public func hideAddFileView() {
        guard let composerAddFileContainerView = composerAddFileContainerView else {
            return
        }
        
        composerAddFileContainerView.animate(show: false)
        composerCommandsContainerView.containerView.arrangedSubviews.forEach { $0.isHidden = false }
        
        if composerEditingContainerView.isHidden == false {
            composerEditingContainerView.moveContainerViewPosition()
        }
    }
    
    private func showImagePicker(composerAddFileViewSourceType sourceType: ComposerAddFileView.SourceType) {
        guard case .photo(let pickerSourceType) = sourceType else {
            return
        }
        
        showImagePicker(sourceType: pickerSourceType) { [weak self] pickedImage, status in
            guard status == .authorized else {
                self?.showImpagePickerAuthorizationStatusAlert(status)
                return
            }
            
            guard let channel = self?.channelPresenter?.channel else {
                return
            }
            
            if let pickedImage = pickedImage, let uploaderItem = UploaderItem(channel: channel, pickedImage: pickedImage) {
                self?.composerView.addImageUploaderItem(uploaderItem)
            }
        }
        
        hideAddFileView()
    }
    
    private func showDocumentPicker() {
        let documentPickerViewController = UIDocumentPickerViewController(documentTypes: [.anyFileType], in: .import)
        documentPickerViewController.allowsMultipleSelection = true
        
        documentPickerViewController.rx.didPickDocumentsAt
            .takeUntil(documentPickerViewController.rx.deallocated)
            .subscribe(onNext: { [weak self] in
                if let self = self, let channel = self.channelPresenter?.channel {
                    $0.forEach { url in self.composerView.addFileUploaderItem(UploaderItem(channel: channel, url: url)) }
                }
            })
            .disposed(by: disposeBag)
        
        present(documentPickerViewController, animated: true)
        hideAddFileView()
    }
}

// MARK: Ephemeral Message Action

extension ChatViewController {
    func sendActionForEphemeral(message: Message, button: UIButton) {
        let buttonText = button.title(for: .normal)
        
        guard let attachment = message.attachments.first,
            let action = attachment.actions.first(where: { $0.text == buttonText }) else {
                return
        }
        
        channelPresenter?.dispatch(action: action, message: message).subscribe().disposed(by: disposeBag)
    }
}
