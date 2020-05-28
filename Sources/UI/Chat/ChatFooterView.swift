//
//  ChatFooterView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

public final class ChatFooterView: UIView {
    typealias TimerCompletion = () -> Void
    
    private var timerWorker: DispatchWorkItem?
    private var timerCompletion: TimerCompletion?
    private var timeout: TimeInterval = 0
    
    public private(set) lazy var avatarView: AvatarView = {
        let avatarView = AvatarView(style: .init(radius: .chatFooterAvatarRadius))
        addSubview(avatarView)
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageSpacing).priority(999)
            make.bottom.equalToSuperview().offset(-CGFloat.messageSpacing).priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding).priority(999)
        }
        
        return avatarView
    }()
    
    public private(set) lazy var activityIndicatorView: UIActivityIndicatorView = {
        let style: UIActivityIndicatorView.Style = (backgroundColor?.isDark ?? false) ? .white : .gray
        let activityIndicator = UIActivityIndicatorView(style: style)
        activityIndicator.stopAnimating()
        addSubview(activityIndicator)
        activityIndicator.snp.makeConstraints { $0.center.equalTo(avatarView.snp.center) }
        return activityIndicator
    }()
    
    public private(set) lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.chatMedium
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.left.equalTo(avatarView.snp.right).offset(CGFloat.messageInnerPadding).priority(999)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding).priority(999)
        }
        
        avatarView.backgroundColor = backgroundColor
        
        return label
    }()
    
    deinit {
        timerWorker?.cancel()
    }
    
    public func hide() {
        isHidden = true
        avatarView.reset()
        avatarView.backgroundColor = backgroundColor
        activityIndicatorView.stopAnimating()
        timerWorker?.cancel()
        timerWorker = nil
    }
    
    @available(*, deprecated, message: "It doesn't use anymore.")
    public func hide(after timeout: TimeInterval) {
        self.timeout = timeout
        restartHidingTimer()
    }
    
    private func restartHidingTimer() {
        timerWorker?.cancel()
        
        if timeout > 0 {
            let timerWorker = DispatchWorkItem { [weak self] in self?.hide() }
            self.timerWorker = timerWorker
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timerWorker)
        }
    }
}
