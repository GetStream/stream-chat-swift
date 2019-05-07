//
//  ChatViewController+Reactions.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 06/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

extension ChatViewController {
    
    func update(cell: MessageTableViewCell, forReactionsIn message: Message) {
        guard let reactionCounts = message.reactionCounts, !reactionCounts.counts.isEmpty else {
            return
        }
        
        cell.update(reactions: reactionCounts.string) { [weak self] cell in
            self?.showReactions(from: cell, in: message)
        }
    }
    
    private func showReactions(from cell: MessageTableViewCell, in message: Message) {
        let rect = tableView.convert(cell.frame, to: view)
        
        let reactionsView = ReactionsView(frame: .zero)
        reactionsView.backgroundColor = style.backgroundColor.withAlphaComponent(0.4)
        reactionsView.reactionsView.backgroundColor = style.incomingMessage.reactionViewStyle.backgroundColor
        view.addSubview(reactionsView)
        reactionsView.snp.makeConstraints { $0.edges.equalToSuperview() }
        reactionsView.show(at: rect.origin.y, for: message) { [weak self] in self?.reactionsView = nil }
        self.reactionsView = reactionsView
    }
}
