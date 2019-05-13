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
            .do(onNext: { [weak self] text in
                if let self = self {
                    self.channelPresenter?.sendEvent(isTyping: true)
                    self.dispatchCommands(in: text ?? "")
                }
            })
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
                
                let bottom = height
                    + .messagesToComposerPadding
                    - (height > 0 ? tableView.adjustedContentInset.bottom - .messagesToComposerPadding : 0)
                
                tableView.contentInset = UIEdgeInsets(top: tableView.contentInset.top,
                                                      left: tableView.contentInset.left,
                                                      bottom: bottom,
                                                      right: tableView.contentInset.right)
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
            .skip(1)
            .drive(onNext: { [weak self] height in
                if let self = self {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += height - self.view.safeAreaBottomOffset
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
        showComposerHelperWithCommands(for: text, trimmedText)
        
        // Send command.
        if text.contains("\n"),
            trimmedText.contains(" ") {
            self.composerView.textView.text = trimmedText.replacingOccurrences(of: "\n", with: "")
            self.composerView.textView.resignFirstResponder()
            self.send()
        }
    }
    
    private func send() {
        let text = composerView.text
        composerView.reset()
        channelPresenter?.send(text: text)
    }
}

// MARK: - Composer Helper

extension ChatViewController {
    private func showComposerHelperWithCommands(for text: String, _ trimmedText: String) {
        let hide = filterCommands(with: text, trimmedText)
        
        // Show composer helper container.
        if trimmedText.count == 1, let first = trimmedText.first, first == "/" {
            composerCommands.animate(show: true, resetForcedHidden: true)
            return
        }
        
        if hide || trimmedText.first != "/" {
            composerCommands.animate(show: false)
        } else {
            composerCommands.animate(show: true)
        }
    }
    
    func filterCommands(with text: String, _ trimmedText: String) -> Bool {
        guard trimmedText.count > 1 else {
            composerCommands.containerView.arrangedSubviews.forEach { $0.isHidden = false }
            return false
        }
        
        let prefix = trimmedText.trimmingCharacters(in: .init(charactersIn: "/"))
        var firstWord: String? = nil
        
        if let spaceIndex = text.firstIndex(of: " ") {
            firstWord = String(text.prefix(upTo: spaceIndex))
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: .init(charactersIn: "/"))
        }
        
        var visible = false
        
        composerCommands.containerView.arrangedSubviews.forEach {
            if let commandView = $0 as? ComposerCommandView {
                if let firstWord = firstWord {
                    commandView.isHidden = commandView.command != firstWord
                } else {
                    commandView.isHidden = !commandView.command.hasPrefix(prefix)
                }
                
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
