//
//  MessageFooterView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class MessageFooterView: UIView {
    typealias TimerCompletion = () -> Void
    
    private var timerWorker: DispatchWorkItem?
    private var timerCompletion: TimerCompletion?
    private var timeout: TimeInterval = 0
    
    private(set) lazy var avatarView: AvatarView = {
        let avatarView = AvatarView(cornerRadius: .messageAvatarRadius)
        addSubview(avatarView)
        
        avatarView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(CGFloat.messageBottomPadding).priority(999)
            make.bottom.equalToSuperview().offset(-CGFloat.messageBottomPadding).priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
        }

        return avatarView
    }()
    
    private(set) lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.chatMedium
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.centerY.equalTo(avatarView.snp.centerY)
            make.left.equalTo(avatarView.snp.right).offset(CGFloat.messageInnerPadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
        }
        
        return label
    }()
    
    deinit {
        timerWorker?.cancel()
    }
    
    func hide(after timeout: TimeInterval, completion: @escaping TimerCompletion) {
        self.timeout = timeout
        timerCompletion = completion
        restartHidingTimer()
    }
    
    func restartHidingTimer() {
        timerWorker?.cancel()
        
        if timeout > 0, let completion = timerCompletion {
            let timerWorker = DispatchWorkItem(block: completion)
            self.timerWorker = timerWorker
            DispatchQueue.main.asyncAfter(deadline: .now() + timeout, execute: timerWorker)
        }
    }
}
