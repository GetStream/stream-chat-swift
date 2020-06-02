//
//  ChatViewController+Composer.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import Photos.PHPhotoLibrary
import SnapKit
import RxSwift
import RxCocoa

// MARK: Setup Keyboard Events
extension Reactive where Base: ChatViewController {
    var keyboard: Binder<KeyboardNotification> {
        Binder<KeyboardNotification>(base) { chatViewController, keyboardNotification in
            guard chatViewController.isVisible else {
                return
            }
            
            var bottom: CGFloat = 0
            
            if keyboardNotification.isVisible {
                var alsoSendToChannelButtonHeight: CGFloat = 0
                
                if chatViewController.composerView.alsoSendToChannelButton.superview != nil,
                    let replyInChannelViewStyle = chatViewController.composerView.style?.replyInChannelViewStyle {
                    chatViewController.composerView.alsoSendToChannelButton.isHidden = false
                    
                    alsoSendToChannelButtonHeight = replyInChannelViewStyle.height
                        + replyInChannelViewStyle.edgeInsets.top
                        + replyInChannelViewStyle.edgeInsets.bottom
                }
                
                bottom = keyboardNotification.height
                    - chatViewController.composerView.toolBar.frame.height
                    + alsoSendToChannelButtonHeight
                    - chatViewController.initialSafeAreaBottom
            } else {
                chatViewController.composerView.textView.resignFirstResponder()
                chatViewController.composerView.alsoSendToChannelButton.isHidden = true
            }
            
            var contentOffset = CGPoint.zero
            
            let contentHeight = chatViewController.tableView.contentSize.height
                + chatViewController.tableView.contentInset.top
                + chatViewController.tableView.contentInset.bottom
            
            let tableHeight = chatViewController.tableView.bounds.height - keyboardNotification.height
            
            if keyboardNotification.animation != nil,
                keyboardNotification.isVisible,
                !chatViewController.keyboardIsVisible,
                tableHeight < contentHeight {
                contentOffset = chatViewController.tableView.contentOffset
                contentOffset.y += min(bottom, contentHeight - tableHeight)
            }
            
            func animations() {
                chatViewController.view.removeAllAnimations()
                chatViewController.additionalSafeAreaInsets = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
                
                if keyboardNotification.animation != nil {
                    if keyboardNotification.isVisible {
                        if contentOffset != .zero {
                            chatViewController.tableView.setContentOffset(contentOffset, animated: false)
                            chatViewController.keyboardIsVisible = true
                        }
                    } else {
                        chatViewController.keyboardIsVisible = false
                    }
                    
                    chatViewController.view.layoutIfNeeded()
                }
            }
            
            if let animation = keyboardNotification.animation {
                UIView.animate(withDuration: animation.duration,
                               delay: 0,
                               options: [animation.curve, .beginFromCurrentState],
                               animations: animations)
            } else {
                animations()
            }
            
            DispatchQueue.main.async { chatViewController.composerView.updateStyleState() }
        }
    }
}

// MARK: - Composer

public extension ChatViewController {
    enum ComposerAddFileType {
        case photo
        case camera
        case file
        case custom(icon: UIImage?, title: String, ComposerAddFileView.SourceType, ComposerAddFileView.Action)
    }
}

// MARK: Setup

extension ChatViewController {
    func createComposerView() -> ComposerView {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }
    
    func setupComposerView() {
        guard composerView.superview == nil, let presenter = presenter else {
            return
        }
        
        composerView.attachmentButton.isHidden = composerAddFileContainerView == nil
        composerView.addToSuperview(view, showAlsoSendToChannelButton: presenter.isThread)
        
        if let composerAddFileContainerView = composerAddFileContainerView {
            composerAddFileContainerView.add(to: composerView)
            
            composerView.attachmentButton.rx.tap
                .subscribe(onNext: { [weak self] in self?.showAddFileView() })
                .disposed(by: disposeBag)
        }
        
        let textViewEvents = composerView.textView.rx.text.skip(1).compactMap({ $0 }).share()
        
        // Dispatch commands from text view.
        textViewEvents.subscribe(onNext: { [weak self] in self?.dispatchCommands(in: $0) }).disposed(by: disposeBag)
        
        // Send typing events.
        if presenter.isTypingEventsEnabled {
            textViewEvents
                .filter({ !$0.isEmpty })
                .flatMapLatest({ [weak self] _ in self?.presenter?.channel.rx.keystroke() ?? .empty() })
                .subscribe()
                .disposed(by: disposeBag)
        }
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        keyboard.notification
            .filter { $0.isHidden }
            .subscribe(onNext: { [weak self] _ in self?.showCommands(show: false) })
            .disposed(by: disposeBag)
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
    
    // MARK: Send Message
    
    /// Send a message.
    public func send() {
        let text = composerView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isMessageEditing = presenter?.editMessage != nil
        
        if findCommand(in: text) != nil || isMessageEditing {
            view.endEditing(true)
        }
        
        if isMessageEditing {
            composerEditingContainerView.animate(show: false)
        }
        
        // We don't want users to send the same message multiple times
        // in case their internet is slow and message isn't sent immediately
        composerView.sendButton.isEnabled = false
        
        presenter?.rx.send(text: text, showReplyInChannel: composerView.alsoSendToChannelButton.isSelected)
            .subscribe(
                onNext: { [weak self] messageResponse in
                    if messageResponse.message.type == .error {
                        self?.show(error: ClientError.errorMessage(messageResponse.message))
                    }
                },
                onError: { [weak self] in
                    self?.composerView.reset()
                    self?.show(error: $0)
                },
                onCompleted: { [weak self] in self?.composerView.reset() })
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
                    self.presenter?.editMessage = nil
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
        container.isEnabled = !(presenter?.channel.config.commands.isEmpty ?? true)
        
        if container.isEnabled, let channelConfig = presenter?.channel.config {
            channelConfig.commands.forEach { command in
                let view = ComposerCommandView(frame: .zero)
                view.backgroundColor = container.backgroundColor
                view.update(command: command.name, args: command.args, description: command.description)
                container.containerView.addArrangedSubview(view)
                
                view.rx.tapGesture()
                    .when(.recognized)
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
        guard let presenter = presenter, presenter.channel.config.uploadsEnabled, !composerAddFileTypes.isEmpty else {
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
                                           title: "Upload from camera",
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
            if let addFileView = subview as? ComposerAddFileView, let uploadManager = composerView.uploadManager {
                if case .file = addFileView.sourceType {
                    addFileView.isHidden = !uploadManager.images.isEmpty
                } else {
                    addFileView.isHidden = !uploadManager.files.isEmpty
                }
            }
        }
        
        let subviews = composerAddFileContainerView.containerView.arrangedSubviews.filter { $0.isHidden == false }
        
        if subviews.count == 1, let first = subviews.first as? ComposerAddFileView {
            first.tap()
        } else {
            if composerView.textView.frame.height > (.composerMaxHeight / 2)
                || (UIDevice.isPhone && UIDevice.current.orientation.isLandscape) {
                composerView.textView.resignFirstResponder()
            }
            
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
        
        showImagePicker(sourceType: pickerSourceType) { [weak self] result in
            guard let self = self else {
                return
            }
            
            do {
                let pickedImage = try result.get()
                
                guard let presenter = self.presenter, let image = pickedImage.image else {
                    return
                }
                
                let extraData = presenter.imageAttachmentExtraDataCallback?(pickedImage.fileURL,
                                                                            image,
                                                                            pickedImage.isVideo,
                                                                            presenter.channel)
                
                let uploaderItem = try UploadingItem(channel: presenter.channel, pickedImage: pickedImage, extraData: extraData)
                
                guard let data = uploaderItem.data, data.count < 20 * 1024 * 1024 else {
                    self.show(errorMessage: "File size exceeds limit of 20MB")
                    return
                }
                
                if case .image = uploaderItem.type {
                    self.composerView.addImageUploaderItem(uploaderItem)
                } else {
                    self.composerView.addFileUploaderItem(uploaderItem)
                }
            } catch let error as ImagePickerError {
                self.showImagePickerAlert(for: error)
            } catch let error as ClientError {
                ClientLogger.log("🌄", level: .error, "Error when trying to create file for uploading: \(error)")
            } catch {
                ClientLogger.log("🌄", level: .error, "Unknown error: \(error)")
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
                if let self = self, let presenter = self.presenter {
                    $0.forEach { url in
                        do {
                            let extraData = presenter.fileAttachmentExtraDataCallback?(url, presenter.channel)
                            let uploaderItem = try UploadingItem(channel: presenter.channel, url: url, extraData: extraData)
                            
                            guard let data = uploaderItem.data, data.count < 20 * 1024 * 1024 else {
                                self.show(errorMessage: "File size exceeds limit of 20MB")
                                return
                            }
                            
                            self.composerView.addFileUploaderItem(uploaderItem)
                        } catch {
                            ClientLogger.log("📁",
                                             level: .error,
                                             "Error occurred when trying to add file in url: \(url), error: \(error)")
                        }
                    }
                }
            })
            .disposed(by: disposeBag)
        
        present(documentPickerViewController, animated: true)
        hideAddFileView()
    }
}

// MARK: Ephemeral Message Action

extension ChatViewController {
    func sendActionForEphemeralMessage(_ message: Message, button: UIButton) {
        let buttonText = button.title(for: .normal)
        
        guard let attachment = message.attachments.first,
            let action = attachment.actions.first(where: { $0.text == buttonText }) else {
                return
        }
        
        presenter?.rx.dispatchEphemeralMessageAction(action, message: message)
            .subscribe()
            .disposed(by: disposeBag)
    }
} // swiftlint:disable:this file_length
