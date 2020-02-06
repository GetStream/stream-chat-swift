//
//  AttachmentFilePreview.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 12/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift

final class AttachmentFilePreview: UIImageView, AttachmentPreviewProtocol {
    
    let disposeBag = DisposeBag()
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
            make.left.equalTo(iconImageView.snp.right).offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
        }
        
        return label
    }()
    
    func update(maskImage: UIImage?, _ completion: @escaping Completion) {
        guard let attachment = attachment, let file = attachment.file else {
            return
        }
        
        iconImageView.image = file.type.icon
        titleLabel.text = attachment.title
        sizeLabel.text = file.sizeString
        image = maskImage
    }
}
