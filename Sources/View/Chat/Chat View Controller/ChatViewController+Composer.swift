//
//  ChatViewController+Composer.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
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
            .debounce(1, scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in self?.channelPresenter?.sendEvent(isTyping: false) })
            .disposed(by: disposeBag)
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        composerView.attachmentButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.showAttachmentPickerList() })
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
        
        composerView.reset()
        
        if isMessageEditing {
            composerEditingHelperView.animate(show: false)
        }
        
        channelPresenter?.send(text: text)
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
}

// MARK: - Composer Edit

extension ChatViewController {
    func createComposerEditingHelperView() -> ComposerHelperContainerView {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.incomingMessage.chatBackgroundColor.isDark ? .chatDarkGray : .white
        container.titleLabel.text = "Edit message"
        container.add(for: composerView)
        container.isHidden = true
        
        container.closeButton.rx.tap
            .subscribe(onNext: { [weak self] _ in
                if let self = self {
                    self.channelPresenter?.editMessage = nil
                    self.composerView.reset()
                    self.composerEditingHelperView.animate(show: false)
                }
            })
            .disposed(by: disposeBag)
        
        return container
    }
}

// MARK: - Composer Commands

extension ChatViewController {
    
    func createComposerCommandsView() -> ComposerHelperContainerView {
        let container = ComposerHelperContainerView()
        container.backgroundColor = style.incomingMessage.chatBackgroundColor.isDark ? .chatDarkGray : .white
        container.titleLabel.text = "Commands"
        container.add(for: composerView)
        container.isHidden = true
        container.closeButton.isHidden = true
        
        if let channelConfig = channelPresenter?.channel.config {
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
        let hide = filterCommands(with: text)
        
        // Show composer helper container.
        if text.count == 1, let first = text.first, first == "/" {
            composerCommandsView.animate(show: true, resetForcedHidden: true)
            return
        }
        
        if hide || text.first != "/" {
            composerCommandsView.animate(show: false)
        } else {
            composerCommandsView.animate(show: true)
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
    private func showAttachmentPickerList() {
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
