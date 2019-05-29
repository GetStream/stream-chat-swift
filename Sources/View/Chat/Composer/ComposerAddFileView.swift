//
//  ComposerAddFileView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/05/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class ComposerAddFileView: UIView {
    typealias Action = (_ sourceType: SourceType) -> Void
    
    private let iconImageView: UIImageView
    private let titleLabel: UILabel
    let sourceType: SourceType
    let action: Action
    
    override var backgroundColor: UIColor? {
        didSet {
            titleLabel.textColor = backgroundColor?.oppositeBlackAndWhite ?? .black
            iconImageView.tintColor = titleLabel.textColor
            iconImageView.backgroundColor = titleLabel.textColor.withAlphaComponent(0.1)
        }
    }
    
    init(icon: UIImage, title: String, sourceType: SourceType, action: @escaping Action) {
        iconImageView = UIImageView(image: icon)
        iconImageView.contentMode = .center
        iconImageView.layer.cornerRadius = .composerHelperIconCornerRadius
        titleLabel = UILabel(frame: .zero)
        titleLabel.font = .chatMedium
        titleLabel.text = title
        self.sourceType = sourceType
        self.action = action
        super.init(frame: .zero)
        addSubview(iconImageView)
        addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.top.equalToSuperview().offset(CGFloat.messageSpacing).priority(999)
            make.bottom.equalToSuperview().offset(-CGFloat.messageSpacing).priority(999)
            make.width.height.equalTo(CGFloat.composerHelperIconSize)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(CGFloat.composerHelperButtonEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.centerY.equalTo(iconImageView.snp.centerY)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        iconImageView = UIImageView(frame: .zero)
        titleLabel = UILabel(frame: .zero)
        sourceType = .file
        action = { _ in }
        super.init(coder: aDecoder)
    }
}

extension ComposerAddFileView {
    enum SourceType {
        case photo(_ sourceType: UIImagePickerController.SourceType)
        case file
    }
}
