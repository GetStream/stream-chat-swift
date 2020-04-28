//
//  AttachmentFilePreview.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import SnapKit
import RxSwift

final class FileAttachmentPreview: UIImageView, AttachmentPreview {
    
    var index = 0
    var attachment: Attachment?
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.messageInnerPadding)
            make.top.equalToSuperview().offset(CGFloat.attachmentFileIconTop)
            make.size.equalTo(CGSize(width: .attachmentFileIconWidth, height: .attachmentFileIconHeight))
        }
        
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMediumBold
        label.textColor = .chatBlue
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.bottom.equalTo(iconImageView.snp.centerY)
            make.left.equalTo(iconImageView.snp.right).offset(CGFloat.messageInnerPadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
        }
        
        return label
    }()
    
    private lazy var sizeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.centerY)
            make.left.equalTo(iconImageView.snp.right).offset(CGFloat.messageInnerPadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
        }
        
        return label
    }()
    
    /// Setup a message style.
    func setup(attachment: Attachment, style: MessageViewStyle) {
        self.attachment = attachment
        backgroundColor = style.chatBackgroundColor
        titleLabel.textColor = style.replyColor
        sizeLabel.textColor = style.infoColor
    }
    
    /// Update image mask.
    func apply(imageMask: UIImage?) {
        image = imageMask
    }
    
    /// Update attachment preview with a given attachment.
    func update(_ completion: Completion? = nil) {
        guard let attachment = attachment, let file = attachment.file else {
            return
        }
        
        iconImageView.image = file.type.icon
        titleLabel.text = attachment.title
        sizeLabel.text = file.sizeString
        completion?(self, nil)
    }
}
