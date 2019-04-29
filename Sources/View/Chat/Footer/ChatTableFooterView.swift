//
//  ChatTableFooterView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class ChatTableFooterView: UIView {
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        addSubview(stackView)
        stackView.snp.makeConstraints { $0.edges.equalToSuperview() }
        return stackView
    }()
    
    var isEmpty: Bool {
        return stackView.arrangedSubviews.isEmpty
    }
    
    func add(messageFooterView: MessageFooterView) {
        stackView.addArrangedSubview(messageFooterView)
    }
    
    func add(messageFooterView: MessageFooterView, timeout: TimeInterval, completion: @escaping () -> Void) {
        stackView.addArrangedSubview(messageFooterView)
        
        messageFooterView.hide(after: timeout) { [weak self, weak messageFooterView] in
            if let self = self, let messageFooterView = messageFooterView {
                self.remove(messageFooterView: messageFooterView)
                completion()
            }
        }
    }
    
    func messageFooterView(by tag: Int) -> MessageFooterView? {
        return stackView.findArrangedSubview(typeOf: MessageFooterView.self, tag: tag)
    }
    
    func remove(messageFooterView: MessageFooterView) {
        stackView.removeArrangedSubview(messageFooterView)
        messageFooterView.removeFromSuperview()
    }
    
    func removeMessageFooterView(by tag: Int) {
        stackView.removeArrangedSubview(typeOf: MessageFooterView.self, tag: tag)
    }
}
