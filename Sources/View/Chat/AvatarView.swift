//
//  AvatarView.swift
//  GetStreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import Nuke

final class AvatarView: UIImageView, Reusable {
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatAvatar
        label.textAlignment = .center
        label.isHidden = true
        label.preferredMaxLayoutWidth = 2 * layer.cornerRadius
        return label
    }()
    
    init(cornerRadius: CGFloat = .messageAvatarRadius) {
        super.init(frame: .zero)
        setup(cornerRadius: cornerRadius)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup(cornerRadius: frame.width / 2)
    }
    
    private func setup(cornerRadius: CGFloat) {
        layer.cornerRadius = cornerRadius
        clipsToBounds = true
        contentMode = .scaleAspectFill
        snp.makeConstraints { $0.width.height.equalTo(2 * cornerRadius) }
        addSubview(avatarLabel)
        avatarLabel.snp.makeConstraints { $0.edges.equalToSuperview() }
    }
    
    func reset() {
        image = nil
        backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
    }
    
    public func update(with url: URL?, name: String) {
        isHidden = false
        
        guard let url = url else {
            showAvatarLabel(with: name)
            return
        }
        
        let imageSize = 2 * layer.cornerRadius * UIScreen.main.scale
        let request = ImageRequest(url: url, targetSize: CGSize(width: imageSize, height: imageSize), contentMode: .aspectFill)
        
        ImagePipeline.shared.loadImage(with: request) { [weak self] response, error in
            self?.image = response?.image
        }
    }
    
    private func showAvatarLabel(with name: String) {
        if name.contains(" ") {
            let words = name.split(separator: " ")
            
            if let a = String(describing: words[0]).first, let b = String(describing: words[1]).first {
                avatarLabel.text = String(a).appending(String(b)).uppercased()
            }
        } else {
            avatarLabel.text = name.first?.uppercased()
        }
        
        backgroundColor = .color(by: name, isDark: backgroundColor?.isDark ?? false)
        avatarLabel.isHidden = false
        avatarLabel.textColor = backgroundColor?.withAlphaComponent(0.3)
    }
}
