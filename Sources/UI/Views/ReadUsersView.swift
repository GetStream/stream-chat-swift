//
//  ReadUsersView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 21/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import SnapKit

final class ReadUsersView: UIView {
    
    private let rightAvatarView = AvatarView(cornerRadius: .messageReadUsersAvatarCornerRadius)
    private let leftAvatarView = AvatarView(cornerRadius: .messageReadUsersAvatarCornerRadius)
    let countLabel = UILabel(frame: .zero)
    
    override var backgroundColor: UIColor? {
        didSet {
            updateAvatarsBorderColors()
            countLabel.backgroundColor = backgroundColor
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(rightAvatarView)
        addSubview(leftAvatarView)
        addSubview(countLabel)
        rightAvatarView.isHidden = true
        leftAvatarView.isHidden = true
        
        rightAvatarView.layer.borderWidth = .messageReadUsersAvatarBorderWidth
        leftAvatarView.layer.borderWidth = .messageReadUsersAvatarBorderWidth
        
        rightAvatarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalTo(CGFloat.messageReadUsersSize / 2)
        }
        
        leftAvatarView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
            make.left.equalTo(1.5 * CGFloat.messageReadUsersSize)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        updateAvatarsBorderColors()
    }

    func reset() {
        isHidden = true
        rightAvatarView.reset()
        leftAvatarView.reset()
        rightAvatarView.isHidden = true
        leftAvatarView.isHidden = true
        countLabel.text = nil
    }
    
    func update(readUsers: [User]) {
        guard !readUsers.isEmpty else {
            return
        }
        
        isHidden = false
        
        if let user = readUsers.last {
            rightAvatarView.isHidden = false
            rightAvatarView.update(with: user.avatarURL, name: user.name, baseColor: backgroundColor)
        }
        
        if readUsers.count > 1, readUsers.count < 100 {
            let user = readUsers[readUsers.count - 2]
            rightAvatarView.isHidden = false
            leftAvatarView.update(with: user.avatarURL, name: user.name, baseColor: backgroundColor)
        }
        
        if readUsers.count > 2 {
            countLabel.text = String(readUsers.count)
        }
    }
    
    private func updateAvatarsBorderColors() {
        rightAvatarView.layer.borderColor = backgroundColor?.cgColor
        leftAvatarView.layer.borderColor = backgroundColor?.cgColor
    }
}
