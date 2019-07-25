//
//  ComposerFileView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 04/06/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatCore
import SnapKit
import RxSwift

final class ComposerFileView: UIView {
    
    let disposeBag = DisposeBag()
    
    let iconView = UIImageView(image: UIImage.FileTypes.zip)
    
    lazy var fileNameLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatMediumBold
        return label
    }()
    
    private lazy var fileSizeLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmallBold
        label.textColor = .chatGray
        label.text = " "
        return label
    }()
    
    var fileSize: Int64 = 0 {
        didSet {
            fileSizeLabel.text = fileSize > 0 ? AttachmentFile.sizeFormatter.string(fromByteCount: fileSize) : nil
        }
    }
    
    let removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.close, for: .normal)
        button.layer.cornerRadius = UIImage.Icons.close.size.width / 2
        return button
    }()
    
    private(set) lazy var progressView = UIProgressView(progressViewStyle: .default)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(iconView)
        addSubview(fileNameLabel)
        addSubview(fileSizeLabel)
        addSubview(removeButton)
        addSubview(progressView)
        progressView.progress = 0.3
        
        iconView.snp.makeConstraints { make in
            make.left.top.equalToSuperview().offset(CGFloat.composerFilePadding)
            make.bottom.equalToSuperview().offset(-CGFloat.composerFilePadding)
            make.width.equalTo(CGFloat.composerFileIconWidth)
            make.height.equalTo(CGFloat.composerFileIconHeight)
        }
        
        fileNameLabel.snp.makeConstraints { make in
            make.bottom.equalTo(iconView.snp.centerY).offset(1)
            make.left.equalTo(iconView.snp.right).offset(CGFloat.composerFilePadding)
            make.right.equalTo(removeButton.snp.left).offset(-CGFloat.composerFilePadding)
        }
        
        fileSizeLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.centerY).offset(1)
            make.left.equalTo(iconView.snp.right).offset(CGFloat.composerFilePadding)
            make.right.equalTo(removeButton.snp.left).offset(-CGFloat.composerFilePadding)
        }
        
        removeButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-CGFloat.composerFilePadding)
            make.centerY.equalTo(fileNameLabel.snp.centerY)
        }
        
        removeButton.setContentHuggingPriority(.required, for: .horizontal)
        
        progressView.snp.makeConstraints { make in
            make.top.equalTo(fileSizeLabel.snp.centerY)
            make.left.equalTo(iconView.snp.right).offset(CGFloat.composerFilePadding)
            make.right.equalTo(removeButton.snp.left).offset(-CGFloat.composerFilePadding)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func updateRemoveButton(tintColor: UIColor?, action: @escaping () -> Void) {
        if let tintColor = tintColor {
            removeButton.tintColor = tintColor
            removeButton.backgroundColor = tintColor.oppositeBlackAndWhite.withAlphaComponent(0.5)
        }
        
        removeButton.rx.tap.subscribe(onNext: action).disposed(by: disposeBag)
    }
    
    func updateForProgress(_ progress: Float) {
        guard progress < 1 else {
            fileSizeLabel.isHidden = false
            progressView.isHidden = true
            return
        }
        
        fileSizeLabel.isHidden = true
        progressView.isHidden = false
        progressView.progress = progress
    }
    
    func updateForError(_ text: String) {
        progressView.isHidden = true
        fileSizeLabel.isHidden = false
        fileSizeLabel.text = text
        fileSizeLabel.textColor = UIColor.red.withAlphaComponent(0.7)
    }
}
