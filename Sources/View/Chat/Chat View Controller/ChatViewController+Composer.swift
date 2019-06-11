//
//  ChatViewController+Composer.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import Photos.PHPhotoLibrary
import SnapKit
import RxSwift
import RxCocoa
import RxKeyboard

// MARK: - Composer

extension ChatViewController {
    
    func createComposerView() -> ComposerView {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }
    
    func setupComposerView() {
        composerView.addToSuperview(view)
        
        composerView.textView.rx.text
            .skip(1)
            .do(onNext: { [weak self] text in self?.dispatchCommands(in: text ?? "") })
            .filter { [weak self] _ in (self?.channelPresenter?.channel.config.typingEventsEnabled ?? false) }
            .do(onNext: { [weak self] text in self?.channelPresenter?.sendEvent(isTyping: true) })
            .debounce(3, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.channelPresenter?.sendEvent(isTyping: false) })
            .disposed(by: disposeBag)
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        composerView.attachmentButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showAddFileView() })
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
            .drive(onNext: { [weak self] _ in self?.composerCommandsView.animate(show: false) })
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
        if composerCommandsView.shouldBeShown, text.contains("\n"), trimmedText.contains(" ") {
            composerView.textView.text = trimmedText
            send()
        }
    }
    
    private func send() {
        let text = composerView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let isMessageEditing = channelPresenter?.editMessage != nil
        
        if command(in: text) != nil || isMessageEditing {
            view.endEditing(true)
        }
        
        if isMessageEditing {
            composerEditingHelperView.animate(show: false)
        }
        
        channelPresenter?.send(text: text) { [weak composerView] in composerView?.reset() }
    }
    
    private func command(in text: String) -> String? {
        guard text.count > 1, text.hasPrefix("/") else {
            return nil
        }
        
        let command: String
        
        if let spaceIndex = text.firstIndex(of: " ") {
            command = String(text.prefix(upTo: spaceIndex))
        } else {
            command = text
        }
        
        return command.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: .init(charactersIn: "/"))
    }
    
    private func createComposerHelperContainerView(title: String, closeButtonIsHidden: Bool = false) -> ComposerHelperContainerView {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.incomingMessage.chatBackgroundColor.isDark ? .chatDarkGray : .white
        container.titleLabel.text = title
        container.add(for: composerView)
        container.isHidden = true
        container.closeButton.isHidden = closeButtonIsHidden
        return container
    }
}

// MARK: - Composer Edit

extension ChatViewController {
    func createComposerEditingHelperView() -> ComposerHelperContainerView {
        let container = createComposerHelperContainerView(title: "Edit message")
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    self.channelPresenter?.editMessage = nil
                    self.composerView.reset()
                    self.composerEditingHelperView.animate(show: false)
                    
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
    
    func createComposerCommandsView() -> ComposerHelperContainerView {
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
        guard composerCommandsView.isEnabled else {
            return
        }
        
        let hide = filterCommands(with: text)
        
        // Show composer helper container.
        if text.count == 1, let first = text.first, first == "/" {
            composerCommandsView.animate(show: true, resetForcedHidden: true)
            hideAddFileView()
            return
        }
        
        if hide || text.first != "/" {
            composerCommandsView.animate(show: false)
        } else {
            composerCommandsView.animate(show: true)
            hideAddFileView()
        }
    }
    
    func filterCommands(with text: String) -> Bool {
        guard let command = command(in: text) else {
            composerCommandsView.containerView.arrangedSubviews.forEach { $0.isHidden = false }
            return false
        }
        
        var visible = false
        let hasSpace = text.contains(" ")
        
        composerCommandsView.containerView.arrangedSubviews.forEach {
            if let commandView = $0 as? ComposerCommandView {
                commandView.isHidden = hasSpace ? commandView.command != command : !commandView.command.hasPrefix(command)
                visible = visible || !commandView.isHidden
            }
        }
        
        return !visible
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
    
    func createComposerAddFileView() -> ComposerHelperContainerView {
        let container = createComposerHelperContainerView(title: "Add a file")
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in self?.hideAddFileView() })
            .disposed(by: disposeBag)
        
        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
            addButtonsToAddFileView(container,
                                    icon: UIImage.Icons.images,
                                    title: "Upload a photo or video",
                                    sourceType: .photo(.savedPhotosAlbum)) { [weak self] in
                                        self?.showImagePicker(composerAddFileViewSourceType: $0)
            }
            
            composerView.imagesAddAction = { [weak self] _ in
                self?.showImagePicker(composerAddFileViewSourceType: .photo(.savedPhotosAlbum))
            }
        }
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            addButtonsToAddFileView(container,
                                    icon: UIImage.Icons.camera,
                                    title: "Upload from a camera",
                                    sourceType: .photo(.camera)) { [weak self] in
                                        self?.showImagePicker(composerAddFileViewSourceType: $0)
            }
        }
        
        addButtonsToAddFileView(container, icon: UIImage.Icons.file, title: "Upload a file", sourceType: .file) { [weak self] _ in
            self?.showDocumentPicker()
        }
        
        return container
    }
    
    private func addButtonsToAddFileView(_ container: ComposerHelperContainerView,
                                         icon: UIImage,
                                         title: String,
                                         sourceType: ComposerAddFileView.SourceType,
                                         action: @escaping ComposerAddFileView.Action) {
        let view = ComposerAddFileView(icon: icon, title: title, sourceType: sourceType, action: action)
        view.backgroundColor = container.backgroundColor
        container.containerView.addArrangedSubview(view)
        
        view.rx.tapGesture().when(.recognized)
            .subscribe(onNext: { [weak view] _ in
                if let view = view {
                    view.action(view.sourceType)
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func showAddFileView() {
        guard !composerAddFileView.containerView.arrangedSubviews.isEmpty else {
            return
        }
        
        composerCommandsView.animate(show: false)
        
        composerAddFileView.containerView.arrangedSubviews.forEach { subview in
            if let addFileView = subview as? ComposerAddFileView {
                if case .file = addFileView.sourceType {
                    addFileView.isHidden = !composerView.isUploaderImagesEmpty
                } else {
                    addFileView.isHidden = !composerView.isUploaderFilesEmpty
                }
            }
        }
        
        let subviews = composerAddFileView.containerView.arrangedSubviews.filter { $0.isHidden == false }
        
        if subviews.count == 1, let first = subviews.first as? ComposerAddFileView {
            first.action(first.sourceType)
        } else {
            composerAddFileView.animate(show: true)
        }
    }
    
    private func hideAddFileView() {
        composerAddFileView.animate(show: false)
        composerCommandsView.containerView.arrangedSubviews.forEach { $0.isHidden = false }
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
            
            if let pickedImage = pickedImage {
                self?.composerView.addImage(UploaderItem(pickedImage: pickedImage))
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
                if let self = self {
                    $0.forEach { url in self.composerView.addFile(UploaderItem(url: url)) }
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
        
        channelPresenter?.dispatch(action: action, message: message)
    }
}
