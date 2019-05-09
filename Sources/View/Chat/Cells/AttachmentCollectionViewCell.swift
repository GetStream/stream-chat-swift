//
//  AttachmentCollectionViewCell.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 10/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit

final class AttachmentCollectionViewCell: UICollectionViewCell, Reusable {
    
    public let imageView = UIImageView(frame: .zero)
    
    public let removeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.Icons.close, for: .normal)
        button.tintColor = .black
        button.backgroundColor = UIColor.chatGray.withAlphaComponent(0.5)
        button.contentEdgeInsets = .all(2)
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
        reset()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
        reset()
    }
    
    override func prepareForReuse() {
        reset()
        super.prepareForReuse()
    }
    
    private func setup() {
        imageView.contentMode = .scaleAspectFill
        imageView.makeEdgesEqualToSuperview(superview: contentView)
        
        contentView.addSubview(removeButton)
        
        removeButton.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(2)
            make.right.equalToSuperview().offset(-2)
        }
    }
    
    func reset() {
        imageView.image = nil
    }
}
