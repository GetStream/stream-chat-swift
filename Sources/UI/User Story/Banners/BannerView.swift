//
//  BannerView.swift
//  StreamChatCore
//
//  Created by Alexey Bukhtin on 06/08/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import StreamChatCore

final class BannerView: UIView {
    
    lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 3
        label.font = .chatMediumMedium
        label.textAlignment = .center
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.composerInnerPadding)
            make.right.equalToSuperview().offset(-CGFloat.composerInnerPadding)
        }
        
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = .bannerCornerRadius
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: .composerHelperShadowRadius / 4)
        layer.shadowRadius = .composerHelperShadowRadius
        layer.shadowOpacity = Float(CGFloat.composerHelperShadowOpacity)
        backgroundColor = .white
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func update(with bannerItem: Banners.BannerItem) {
        backgroundColor = bannerItem.backgroundColor
        label.textColor = bannerItem.backgroundColor.isDark ? .white : .black
        label.text = bannerItem.title
        
        if bannerItem.title.count > 100 {
            label.font = .chatSmallMedium
        }
        
        if let borderColor = bannerItem.borderColor {
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = 1
        }
    }
}
