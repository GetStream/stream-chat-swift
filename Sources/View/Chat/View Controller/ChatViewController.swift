//
//  ChatViewController.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 03/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import RxKeyboard
import Nuke

public final class ChatViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    public var style = ChatViewStyle()
    private let disposeBag = DisposeBag()
    var reactionsView: ReactionsView?
    
    var scrollEnabled: Bool {
        return reactionsView == nil
    }
    
    public private(set) lazy var composerView: ComposerView = {
        let composerView = ComposerView(frame: .zero)
        composerView.style = style.composer
        return composerView
    }()
    
    public private(set) lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.registerMessageCell(style: style.incomingMessage)
        tableView.registerMessageCell(style: style.outgoingMessage)
        tableView.register(cellType: StatusTableViewCell.self)
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: CGFloat.messagesToComposerPadding, right: 0)
        view.insertSubview(tableView, at: 0)
        
        let footerView = ChatFooterView(frame: CGRect(x: 0, y: 0, width: 0, height: .chatFooterHeight))
        footerView.backgroundColor = style.backgroundColor
        tableView.tableFooterView = footerView
        
        return tableView
    }()
    
    public var channelPresenter: ChannelPresenter? {
        didSet {
            if let channelPresenter = channelPresenter {
                Driver.merge(channelPresenter.changes, channelPresenter.loading)
                    .drive(onNext: { [weak self] in self?.updateTableView(with: $0) })
                    .disposed(by: disposeBag)
            }
        }
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupComposerView()
        setupTableView()
        channelPresenter?.load()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startGifsAnimations()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopGifsAnimations()
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle {
        return style.backgroundColor.isDark ? .lightContent : .default
    }
}

// MARK: - Composer

extension ChatViewController {
    
    private func setupComposerView() {
        composerView.addToSuperview(view)
        
        composerView.sendButton.rx.tap
            .subscribe(onNext: { [weak self] in self?.send() })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.visibleHeight
            .skip(1)
            .drive(onNext: { [weak self] height in
                guard let tableView = self?.tableView else {
                    return
                }
                
                let bottom: CGFloat = height + .messagesToComposerPadding - (height > 0
                    ? tableView.adjustedContentInset.bottom - .messagesToComposerPadding
                    : 0)
                
                tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottom, right: 0)
            })
            .disposed(by: disposeBag)
        
        RxKeyboard.instance.willShowVisibleHeight
            .drive(onNext: { [weak self] height in
                if let self = self {
                    var contentOffset = self.tableView.contentOffset
                    contentOffset.y += height - self.view.safeAreaBottomOffset
                    self.tableView.contentOffset = contentOffset
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func send() {
        let text = composerView.text
        composerView.reset()
        channelPresenter?.send(text: text)
    }
}

// MARK: - Table View

extension ChatViewController {
    
    private func setupTableView() {
        tableView.backgroundColor = style.backgroundColor
        tableView.makeEdgesEqualToSuperview()
    }
    
    private func updateTableView(with changes: ChannelChanges) {
        // Check if view is loaded nad visible.
        guard isVisible else {
            return
        }
        
        switch changes {
        case .none:
            return
        case let .updated(row, position):
            tableView.reloadData()
            
            if scrollEnabled {
                tableView.scrollToRow(at: IndexPath(row: row), at: position, animated: false)
            }
        case let .itemAdded(row, reloadRow, forceToScroll):
            let indexPath = IndexPath(row: row)
            let needsToScroll = tableView.bottomContentOffset < .chatBottomThreshold
            
            tableView.update {
                tableView.insertRows(at: [indexPath], with: .none)
                
                if let reloadRow = reloadRow {
                    tableView.reloadRows(at: [IndexPath(row: reloadRow)], with: .none)
                }
            }
            
            if scrollEnabled, (forceToScroll || needsToScroll) {
                tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
            }
        case let .itemUpdated(row, message):
            tableView.update {
                tableView.reloadRows(at: [IndexPath(row: row)], with: .none)
            }
            
            if let reactionsView = reactionsView {
                reactionsView.update(with: message)
            }
        case let .updateFooter(isUsersTyping):
            updateFooterView(isUsersTyping)
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return channelPresenter?.items.count ?? 0
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let presenter = channelPresenter, indexPath.row < presenter.items.count else {
            return .unused
        }
        
        switch presenter.items[indexPath.row] {
        case .loading:
            return loadingCell(at: indexPath)
        case let .status(title, subtitle):
            return statusCell(at: indexPath, title: title, subtitle: subtitle)
        case .message(let message):
            return messageCell(at: indexPath, message: message)
        case .error:
            return .unused
        }
    }
    
    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? MessageTableViewCell {
            cell.free()
        }
    }
    
    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }
}
