//
//  AvatarView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 29/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import SnapKit
import Nuke

public final class AvatarView: UIImageView, Reusable {
    
    private var imageTask: ImageTask?
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.isHidden = true
        label.preferredMaxLayoutWidth = 2 * layer.cornerRadius
        return label
    }()
    
    public init(cornerRadius: CGFloat = .messageAvatarRadius) {
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
        snp.makeConstraints { $0.width.height.equalTo(2 * cornerRadius).priority(999) }
        avatarLabel.font = .avatarFont(size: cornerRadius * 0.7)
        avatarLabel.makeEdgesEqualToSuperview(superview: self)
    }
    
    func reset() {
        image = nil
        backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        imageTask?.cancel()
    }
    
    public func update(with url: URL?, name: String?, baseColor: UIColor?) {
        isHidden = false
        let baseColor = baseColor ?? UIColor.white
        
        guard let url = url else {
            showAvatarLabel(with: name ?? "?", baseColor)
            return
        }
        
        let imageSize = 2 * layer.cornerRadius * UIScreen.main.scale
        let request = ImageRequest(url: url, targetSize: CGSize(width: imageSize, height: imageSize), contentMode: .aspectFill)
        
        imageTask = ImagePipeline.shared.loadImage(with: request) { [weak self] response, error in
            self?.image = response?.image
        }
    }
    
    private func showAvatarLabel(with name: String, _ baseColor: UIColor) {
        if name.contains(" ") {
            let words = name.split(separator: " ")
            
            if let a = String(describing: words[0]).first, let b = String(describing: words[1]).first {
                avatarLabel.text = String(a).appending(String(b)).uppercased()
            }
        } else {
            avatarLabel.text = name.first?.uppercased()
        }
        
        let nameColor = UIColor.color(by: name, isDark: baseColor.isDark)
        backgroundColor = baseColor.blendAlpha(coverColor: nameColor)
        avatarLabel.textColor = nameColor.withAlphaComponent(0.8)
        avatarLabel.isHidden = false
        image = nil
    }
}
