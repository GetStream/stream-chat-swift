//
//  ComposerCommandView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 13/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class ComposerCommandView: UIView {
    
    private(set) var command: String = ""
    
    private lazy var commandLabel: UILabel = {
        let label = UILabel(frame: .zero)
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.composerHelperTitleEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.top.equalToSuperview().offset(CGFloat.messageSpacing).priority(999)
        }
        
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.composerHelperTitleEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.top.equalTo(commandLabel.snp.bottom).priority(999)
            make.bottom.equalToSuperview().offset(-CGFloat.messageSpacing).priority(999)
        }
        
        return label
    }()
    
    func update(command: String, args: String, description: String) {
        self.command = command
        let textColor = backgroundColor?.oppositeBlackAndWhite ?? .black
        
        let commandAttributedString = NSMutableAttributedString(string: "/\(command)", attributes: [.font: UIFont.chatMediumBold,
                                                                                                    .foregroundColor: textColor])
        
        commandAttributedString.append(.init(string: " \(args)", attributes: [.font: UIFont.chatMedium,
                                                                              .foregroundColor: textColor]))
        
        commandLabel.attributedText = commandAttributedString
        descriptionLabel.text = description
    }
}
