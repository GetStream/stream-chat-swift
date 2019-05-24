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
        
        RxKeyboard.instance.visibleHeight
            .skip(1)
            .drive(onNext: { [weak self] height in
                guard let tableView = self?.tableView else {
                    return
                }
                
                if height > 0 {
                    tableView.saveContentInsetState()
                } else {
                    tableView.resetContentInsetState()
                }
                
                let bottom = height
                    + .messagesToComposerPadding
                    - (height > 0 ? tableView.oldAdjustedContentInset.bottom : 0)
                
                tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top,
                                                      left: tableView.contentInset.left,
                                                      bottom: bottom,
                                                      right: tableView.contentInset.right)
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
            .drive(onNext: { [weak self] height in
                if let self = self {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += height - self.view.safeAreaBottomOffset - (height > 0 ? .messagesToComposerPadding : 0)
                    self.tableView.contentOffset = contentOffset
                    
                }
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.isHidden
            .skip(1)
            .drive(onNext: { [weak self] isHidden in
                if isHidden {
                    self?.composerCommands.animate(show: false)
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func dispatchCommands(in text: String) {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        showCommandsIfNeeded(for: trimmedText)
        
        // Send command by <Return> key.
        if composerCommands.shouldBeShown, text.contains("\n"), trimmedText.contains(" ") {
            composerView.textView.text = trimmedText
            send()
        }
    }
    
    private func send() {
        let text = composerView.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if command(in: text) != nil {
            view.endEditing(true)
        }
        
        composerView.reset()
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

// MARK: - Composer Helper

extension ChatViewController {
    private func showCommandsIfNeeded(for text: String) {
        let hide = filterCommands(with: text)
        
        // Show composer helper container.
        if text.count == 1, let first = text.first, first == "/" {
            composerCommands.animate(show: true, resetForcedHidden: true)
            return
        }
        
        if hide || text.first != "/" {
            composerCommands.animate(show: false)
        } else {
            composerCommands.animate(show: true)
        }
    }
    
    func filterCommands(with text: String) -> Bool {
        guard let command = command(in: text) else {
            composerCommands.containerView.arrangedSubviews.forEach { $0.isHidden = false }
            return false
        }
        
        var visible = false
        let hasSpace = text.contains(" ")
        
        composerCommands.containerView.arrangedSubviews.forEach {
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
