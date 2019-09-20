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

/// A view with a user avatar or user name intials.
public final class AvatarView: EscapeBridgingImageView<Void>, Reusable {
    
    private var imageTask: ImageTask?
    
    private lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.isHidden = true
        label.preferredMaxLayoutWidth = 2 * layer.cornerRadius
        return label
    }()
    
    /// Create a AvatarView with a given corner radius.
    public init(cornerRadius: CGFloat = .messageAvatarRadius) {
        super.init(frame: .zero)
        setup(cornerRadius: cornerRadius)
    }
    
    /// A decoder.
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
    
    /// Reset the AvatarView states for the reusing.
    public func reset() {
        image = nil
        backgroundColor = .white
        avatarLabel.text = nil
        avatarLabel.isHidden = true
        imageTask?.cancel()
    }
    
    /// Update the view with a given image url with user name.
    ///
    /// - Parameters:
    ///     - url: an avatar image url.
    ///     - name: a user name.
    ///     - baseColor: this should be a background color of the superview or it would be white by default.
    public func update(with url: URL?, name: String?, baseColor: UIColor?) {
        isHidden = false
        let baseColor = baseColor ?? UIColor.white
        
        guard let url = url else {
            showAvatarLabel(with: name ?? "?", baseColor)
            return
        }
        
        let imageSize = 2 * layer.cornerRadius * UIScreen.main.scale
        let processors = [ImageProcessor.Resize(size: CGSize(width: imageSize, height: imageSize))]
        let imageRequest = ImageRequest(url: url, processors: processors)
        
        imageTask = ImagePipeline.shared.loadImage(with: imageRequest) { [weak self] result in
            if let self = self {
                if let image = try? result.get().image {
                    self.image = image
                } else {
                    self.showAvatarLabel(with: name ?? "?", baseColor)
                }
            }
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
