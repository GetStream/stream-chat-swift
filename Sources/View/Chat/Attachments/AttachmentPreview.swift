//
//  MessageAttachmentPreviewView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 09/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit
import Nuke
import SwiftyGif

final class AttachmentPreview: UIView, AttachmentPreviewProtocol {
    
    private var defaultHeight: CGFloat = .attachmentPreviewMaxHeight
    
    private var heightConstraint: Constraint?
    private var widthConstraint: Constraint?
    private var imageViewTopConstraint: Constraint?
    private var imageViewBottomConstraint: Constraint?
    private var imageTask: ImageTask?
    private(set) var isGifImage = false
    let disposeBag = DisposeBag()
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.Icons.image)
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        imageView.snp.makeConstraints {
            imageViewTopConstraint = $0.top.equalToSuperview().priority(999).constraint
            imageViewBottomConstraint = $0.bottom.equalToSuperview().priority(999).constraint
            $0.left.right.equalToSuperview()
        }
        
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 2
        label.font = .chatMediumBold
        label.textColor = .chatBlue
        addSubview(label)
        imageViewBottomConstraint?.deactivate()
        
        label.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(CGFloat.messageEdgePadding).priority(999)
            make.top.equalToSuperview().offset(CGFloat.messageEdgePadding).priority(750)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
        }
        
        label.setContentCompressionResistancePriority(.defaultHigh + 20, for: .vertical)
        
        return label
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 4
        label.font = .chatSmall
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.bottom.equalToSuperview().offset(-CGFloat.messageEdgePadding).priority(999)
        }
        
        label.setContentCompressionResistancePriority(.defaultHigh + 10, for: .vertical)
        
        return label
    }()
    
    private(set) lazy var actionsStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.spacing = .messageSpacing
        addSubview(stackView)
        imageViewBottomConstraint?.deactivate()
        
        stackView.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(CGFloat.messageSpacing).priority(999)
            make.height.equalTo(CGFloat.attachmentPreviewActionButtonHeight)
            make.bottom.equalToSuperview().priority(999)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        
        return stackView
    }()
    
    private(set) lazy var activityIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: (backgroundColor?.isDark ?? false) ? .white : .gray)
        imageView.addSubview(view)
        imageView.image = nil
        view.makeCenterEqualToSuperview()
        return view
    }()
    
    public var maxWidth: CGFloat = 0
    var forceToReload: () -> Void = {}
    
    public var attachment: Attachment? {
        didSet {
            if let attachment = attachment {
                hasActions = !attachment.actions.isEmpty
                defaultHeight = attachment.isImage && !hasActions ? .attachmentPreviewHeight : .attachmentPreviewMaxHeight
            }
        }
    }
    
    private var hasActions = false
    
    override var tintColor: UIColor! {
        didSet { imageView.tintColor = tintColor }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        
        NotificationCenter.default.rx.notification(UIApplication.didEnterBackgroundNotification)
            .subscribe(onNext: { [weak self] _ in
                if let self = self, self.isGifImage, self.imageView.isAnimatingGif() {
                    self.imageView.stopAnimatingGif()
                }
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { [weak self] _ in
                if let self = self, self.isGifImage {
                    self.imageView.startAnimatingGif()
                }
            })
            .disposed(by: disposeBag)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        imageTask?.cancel()
        imageTask = nil
    }
    
    override func didMoveToSuperview() {
        if superview != nil, widthConstraint == nil, let attachment = attachment {
            snp.makeConstraints {
                heightConstraint = $0.height.equalTo(defaultHeight).priority(999).constraint
                let width = attachment.isImage && !hasActions ? defaultHeight : maxWidth
                widthConstraint = $0.width.equalTo(width).constraint
            }
        }
    }
    
    func update(maskImage: UIImage?, _ completion: @escaping Competion) {
        guard let attachment = attachment else {
            return
        }
        
        if attachment.type == .giphy {
            showLogo(image: UIImage.Logo.giphy)
        }
        
        if hasActions {
            widthConstraint?.update(offset: maxWidth)
            
            attachment.actions.forEach { action in
                actionsStackView.addArrangedSubview(createActionButton(title: action.text, style: action.style))
            }
            
            backgroundColor = .clear
            
        } else if !attachment.isImage {
            titleLabel.text = attachment.title
            titleLabel.backgroundColor = backgroundColor
            textLabel.text = attachment.text ?? attachment.url?.host
            textLabel.backgroundColor = backgroundColor
            widthConstraint?.update(offset: maxWidth)
            imageViewTopConstraint?.update(offset: CGFloat.messageEdgePadding)
        }
        
        guard let imageURL = attachment.imageURL else {
            imageView.isHidden = true
            heightConstraint?.deactivate()
            return
        }
        
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        let targetSize = CGSize(width: UIScreen.main.scale * maxWidth, height: UIScreen.main.scale * .attachmentPreviewHeight)
        let imageRequest = ImageRequest(url: imageURL, targetSize: targetSize, contentMode: .aspectFit)
        let modes = ImageLoadingOptions.ContentModes(success: .scaleAspectFit, failure: .center, placeholder: .center)
        
        let options = ImageLoadingOptions(placeholder: hasActions ? nil : UIImage.Icons.image,
                                          failureImage: UIImage.Icons.close,
                                          contentModes: modes)
        
        if let imageResponse = Nuke.ImageCache.shared.cachedResponse(for: imageRequest) {
            imageView.contentMode = .scaleAspectFit
            imageView.image = imageResponse.image
            parse(imageResponse: imageResponse, error: nil, maskImage: maskImage, cached: true, completion)
        } else {
            if hasActions {
                activityIndicatorView.startAnimating()
            }
            
            imageTask = Nuke.loadImage(with: imageRequest, options: options, into: imageView) { [weak self] in
                self?.parse(imageResponse: $0, error: $1, maskImage: maskImage, cached: false, completion)
            }
        }
    }
    
    private func parse(imageResponse: ImageResponse?,
                       error: Error?,
                       maskImage: UIImage?,
                       cached: Bool,
                       _ completion: @escaping Competion) {
        guard let attachment = attachment, error == nil else {
            completion(self, error)
            return
        }
        
        if hasActions {
            DispatchQueue.main.async { [weak self] in self?.activityIndicatorView.stopAnimating() }
        }
        
        var width = attachment.isImage && !hasActions ? defaultHeight : maxWidth
        var height = defaultHeight
        
        if let image = imageResponse?.image, image.size.height > 0 {
            imageView.backgroundColor = backgroundColor
            
            if attachment.isImage, !hasActions {
                width = min(image.size.width / image.size.height * defaultHeight, maxWidth).rounded()
                widthConstraint?.update(offset: width)
            }
            
            if height == .attachmentPreviewHeight,
                width == maxWidth,
                let heightConstraint = heightConstraint,
                heightConstraint.isActive {
                height = (image.size.height / image.size.width * maxWidth).rounded()
                heightConstraint.update(offset: height)
                
                if !cached {
                    forceToReload()
                    return
                }
            }
        } else {
            if let error = error, let url = imageResponse?.urlResponse?.url {
                print("⚠️", url, error)
            }
        }
        
        showGif()
        addMaskImage(maskImage, size: CGSize(width: width, height: height))
        
        completion(self, nil)
    }
    
    private func showGif() {
        guard let animatedImageData = imageView.image?.animatedImageData,
            let animatedImage = try? UIImage(gifData: animatedImageData, levelOfIntegrity: 0.6) else {
            return
        }
        
        isGifImage = true
        imageView.image = nil
        imageView.setGifImage(animatedImage, manager: SwiftyGifManager(memoryLimit: 50))
    }
    
    private func addMaskImage(_ maskImage: UIImage?, size: CGSize) {
        if let maskImage = maskImage {
            let maskView = UIImageView(frame: CGRect(origin: .zero, size: size))
            maskView.image = maskImage
            mask = maskView
            layer.cornerRadius = 0
        }
    }
    
    func showLogo(image: UIImage) {
        let logoImageView = UIImageView(image: image)
        imageView.addSubview(logoImageView)
        logoImageView.snp.makeConstraints { $0.right.bottom.equalToSuperview().offset(CGFloat.messageCornerRadius / -2) }
    }
    
    private func createActionButton(title: String, style: Attachment.ActionStyle) -> UIButton {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = .messageCornerRadius
        button.titleLabel?.font = style == .primary ? .chatSmallBold : .chatSmall
        button.backgroundColor = backgroundColor
        button.setTitle(title, for: .normal)
        button.setTitleColor((backgroundColor?.isDark ?? false) ? .white : .black, for: .normal)
        button.setTitleColor(.chatBlue, for: .highlighted)
        button.setTitleColor(.chatGray, for: .disabled)
        
        return button
    }
}
