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
import StreamChatClient

/// A view with a user avatar or user name intials.
public final class AvatarView: EscapeBridgingImageView<Void>, Reusable {
    
    private var imageTask: ImageTask?
    private var style = AvatarViewStyle()
    
    public private(set) lazy var avatarLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        label.isHidden = true
        label.preferredMaxLayoutWidth = 2 * style.radius
        return label
    }()
    
    /// Create a AvatarView with a given avatar view style.
    /// - Parameter style: an avatar style.
    public init(style: AvatarViewStyle?) {
        super.init(frame: .zero)
        setup(with: style ?? AvatarViewStyle())
    }
    
    /// A decoder.
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup(with: AvatarViewStyle(radius: frame.width / 2))
    }
    
    private func setup(with style: AvatarViewStyle) {
        self.style = style
        layer.cornerRadius = style.radius
        clipsToBounds = true
        contentMode = .scaleAspectFill
        snp.makeConstraints { $0.width.height.equalTo(2 * style.radius).priority(999) }
        isHidden = true
        
        avatarLabel.font = style.placeholderFont ?? .avatarFont(size: style.radius * 0.7)
        avatarLabel.makeEdgesEqualToSuperview(superview: self)
        avatarLabel.layer.cornerRadius = style.radius
        avatarLabel.clipsToBounds = true
        avatarLabel.isHidden = true
    }
    
    /// Reset the AvatarView states for the reusing.
    public func reset() {
        image = nil
        imageTask?.cancel()
        avatarLabel.text = nil
        isHidden = true
        avatarLabel.isHidden = true
    }
    
    /// Updates the avatar view with a given image url and name.
    /// - Parameters:
    ///     - url: an avatar image url.
    ///     - name: a user name.
    ///     - backgroundColor: this should be a background color of the superview or it would be white by default.
    public func update(with url: URL?, name: String?) {
        guard let url = url else {
            update(withName: name)
            return
        }
        
        update(with: url) { [weak self] in
            if $0.error != nil {
                self?.update(withName: name)
            }
        }
    }
    
    /// Updates the avatar view with a given image url.
    /// - Parameters:
    ///   - url: an image url.
    ///   - completion: a completion image downloading block.
    public func update(with url: URL, _ completion: ((Result<UIImage, Error>) -> Void)? = nil) {
        isHidden = false
        let imageSize = 2 * layer.cornerRadius * UIScreen.main.scale
        let processors = [ImageProcessor.Resize(size: CGSize(width: imageSize, height: imageSize))]
        let urlRequest = Client.config.avatarImageURLRequestPrepare(url)
        let imageRequest = ImageRequest(urlRequest: urlRequest, processors: processors)
        
        imageTask = ImagePipeline.shared.loadImage(with: imageRequest) { [weak self] result in
            do {
                let image = try result.get().image
                self?.image = image
                self?.avatarLabel.text = nil
                self?.avatarLabel.isHidden = true
                completion?(.success(image))
            } catch {
                completion?(.failure(error))
            }
        }
    }
    
    /// Updates the avatar view name with a given name and background color.
    /// - Parameters:
    ///   - name: a name.
    ///   - backgroundColor: this should be a background color of the superview or it would be white by default.
    public func update(withName name: String?) {
        isHidden = false
        avatarLabel.isHidden = false
        let unwrappedName = (name ?? "?")
        let name = unwrappedName.isEmpty ? "?" : unwrappedName
        
        switch style.placeholderTextStyle {
        case .initials:
            let words = name.split(separator: " ")
            
            if words.count == 2, let a = String(describing: words[0]).first, let b = String(describing: words[1]).first {
                avatarLabel.text = String(a).appending(String(b)).uppercased()
            } else {
                avatarLabel.text = (name.prefix(1) + name.suffix(1)).uppercased()
            }
        case .firstLetter:
            avatarLabel.text = name.prefix(1).uppercased()
        }
        
        if let textColor = style.placeholderTextColor {
            avatarLabel.textColor = textColor
        } else if let provider = style.placeholderTextColorProvider {
            avatarLabel.textColor = provider(name)
        } else if #available(iOS 13, *) {
            avatarLabel.textColor = UIColor(dynamicProvider: { trait -> UIColor in
                UIColor.color(by: name, isDark: trait.userInterfaceStyle == .dark).withAlphaComponent(0.8)
            })
        } else {
            avatarLabel.textColor = UIColor.color(by: name, isDark: backgroundColor?.isDark ?? false).withAlphaComponent(0.8)
        }
        
        if let backgroundColor = style.placeholderBackgroundColor {
            avatarLabel.backgroundColor = backgroundColor
        } else if let provider = style.placeholderBackgroundColorProvider {
            avatarLabel.backgroundColor = provider(name)
        } else if #available(iOS 13, *) {
            avatarLabel.backgroundColor = UIColor(dynamicProvider: { [weak self] trait -> UIColor in
                (self?.backgroundColor ?? .white)
                    .blendAlpha(coverColor: .color(by: name, isDark: trait.userInterfaceStyle == .dark))
            })
        } else {
            let nameColor = UIColor.color(by: name, isDark: backgroundColor?.isDark ?? false)
            avatarLabel.backgroundColor = (backgroundColor ?? .white).blendAlpha(coverColor: nameColor)
        }
        
        avatarLabel.isHidden = false
        image = nil
    }
}
