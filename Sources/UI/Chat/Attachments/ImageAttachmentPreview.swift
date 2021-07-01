//
//  MessageAttachmentPreviewView.swift
//  StreamChat
//
//  Created by Alexey Bukhtin on 09/04/2019.
//  Copyright © 2019 Stream.io Inc. All rights reserved.
//

import UIKit
import StreamChatClient
import StreamChatCore
import RxSwift
import RxCocoa
import SnapKit
import Nuke
import SwiftyGif

final class ImageAttachmentPreview: UIView, AttachmentPreview {
    
    private var defaultHeight: CGFloat = .attachmentPreviewMaxHeight
    
    private var heightConstraint: Constraint?
    private var widthConstraint: Constraint?
    private var imageViewBottomConstraint: Constraint?
    private var linkStackViewTopConstraint: Constraint?
    private var imageTask: ImageTask?
    private var imageMask: UIImage?
    private var calculatedSize = CGSize.zero
    private var style: MessageViewStyle?
    private(set) var isGifImage = false
    var index = 0
    let disposeBag = DisposeBag()
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.Icons.image)
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().priority(999)
            imageViewBottomConstraint = $0.bottom.equalToSuperview().priority(999).constraint
            $0.left.right.equalToSuperview().priority(999)
        }
        
        imageView.setContentHuggingPriority(.required - 3, for: .vertical)
        
        return imageView
    }()
    
    private lazy var linkStackView: UIStackView = {
        imageViewBottomConstraint?.deactivate()
        let stackView = UIStackView(arrangedSubviews: [])
        stackView.axis = .vertical
        stackView.spacing = .messageInnerPadding
        stackView.alignment = .top
        addSubview(stackView)
        
        stackView.snp.makeConstraints { make in
            linkStackViewTopConstraint = make.top.equalToSuperview().priority(999).constraint
            make.bottom.equalToSuperview().offset(-CGFloat.messageCornerRadius).priority(999)
            make.left.right.equalToSuperview()
        }
        
        return stackView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 2
        label.font = .chatMediumBold
        label.textColor = .chatBlue
        let container = UIView(frame: .zero)
        linkStackView.addArrangedSubview(container)
        container.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.messageCornerRadius)
            make.right.equalToSuperview().offset(-CGFloat.messageCornerRadius)
        }
        
        label.setContentCompressionResistancePriority(.required - 1, for: .vertical)
        
        return label
    }()
    
    private lazy var textLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 4
        label.font = .chatSmall
        label.textColor = .chatGray
        let container = UIView(frame: .zero)
        linkStackView.addArrangedSubview(container)
        container.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(CGFloat.messageCornerRadius)
            make.right.equalToSuperview().offset(-CGFloat.messageCornerRadius)
        }
        
        label.setContentCompressionResistancePriority(.required - 2, for: .vertical)
        
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
        let view: UIActivityIndicatorView
        
        if #available(iOS 13, *) {
            view = UIActivityIndicatorView(style: .medium)
        } else {
            view = UIActivityIndicatorView(style: (style?.textColor.isDark ?? true) ? .gray : .white )
        }
        
        imageView.addSubview(view)
        imageView.image = nil
        view.makeCenterEqualToSuperview()
        return view
    }()
    
    var maxWidth = CGFloat.attachmentPreviewMaxWidth
    var forceToReload: () -> Void = {}
    
    var attachment: Attachment? {
        didSet {
            if let attachment = attachment {
                hasActions = !attachment.actions.isEmpty
                isLink = !attachment.isImage
                defaultHeight = attachment.isImage && !hasActions ? .attachmentPreviewHeight : .attachmentPreviewMaxHeight
            }
        }
    }
    
    private var hasActions = false
    private var isLink = false
    
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
    
    func setup(attachment: Attachment, style: MessageViewStyle) {
        self.attachment = attachment
        self.style = style
        backgroundColor = style.textColor.withAlphaComponent(0.05)
        tintColor = style.textColor
        layer.cornerRadius = style.cornerRadius
    }
    
    func apply(imageMask: UIImage?) {
        guard let imageMask = imageMask, calculatedSize != .zero else {
            return
        }
        
        layer.cornerRadius = 0
        
        let maskView = UIImageView(frame: CGRect(origin: .zero, size: calculatedSize))
        maskView.image = imageMask
        mask = maskView
    }
    
    func update(_ completion: AttachmentPreview.Completion? = nil) {
        guard let attachment = attachment else {
            return
        }
        
        if !hasActions, attachment.type == .giphy {
            showLogo(image: UIImage.Logo.giphy)
        }
        
        if hasActions {
            widthConstraint?.update(offset: maxWidth)
            attachment.actions.forEach { actionsStackView.addArrangedSubview(createActionButton(title: $0.text, style: $0.style)) }
            backgroundColor = .clear
        } else if isLink {
            widthConstraint?.update(offset: maxWidth)
            imageViewBottomConstraint?.deactivate()
            imageViewBottomConstraint = nil
            linkStackView.addArrangedSubview(imageView)
            imageView.backgroundColor = backgroundColor
            titleLabel.text = attachment.title
            textLabel.text = attachment.text ?? attachment.url?.host
        }
        
        guard let imageURL = attachment.imageURL else {
            imageView.isHidden = true
            heightConstraint?.deactivate()
            
            if isLink {
                linkStackViewTopConstraint?.update(offset: CGFloat.messageCornerRadius)
            }
            
            completion?(self, nil)
            return
        }
        
        ImagePipeline.Configuration.isAnimatedImageDataEnabled = true
        let targetSize = CGSize(width: UIScreen.main.scale * maxWidth, height: UIScreen.main.scale * .attachmentPreviewHeight)
        let processors = [ImageProcessor.Resize(size: targetSize)]
        let urlRequest = Client.config.attachmentImageURLRequestPrepare(imageURL)
        let imageRequest = ImageRequest(urlRequest: urlRequest, processors: processors)
        
        if let imageResponse = Nuke.ImageCache.shared.cachedResponse(for: imageRequest) {
            imageView.contentMode = .scaleAspectFit
            imageView.image = imageResponse.image
            parse(imageResult: .success(imageResponse), cached: true, completion)
        } else {
            if hasActions {
                activityIndicatorView.startAnimating()
            }
            
            let modes = ImageLoadingOptions.ContentModes(success: .scaleAspectFit, failure: .center, placeholder: .center)
            
            let options = ImageLoadingOptions(placeholder: hasActions ? nil : UIImage.Icons.image,
                                              failureImage: UIImage.Icons.close,
                                              contentModes: modes)

            imageTask = Nuke.loadImage(with: imageRequest, options: options, into: imageView) { [weak self] in
                self?.parse(imageResult: $0, cached: false, completion)
            }
        }
    }
    
    private func parse(imageResult: Result<ImageResponse, ImagePipeline.Error>,
                       cached: Bool,
                       _ completion: Completion?) {
        guard let attachment = attachment, let image = try? imageResult.get().image else {
            if isLink {
                imageView.isHidden = true
                linkStackViewTopConstraint?.update(offset: CGFloat.messageCornerRadius)
                linkStackView.addArrangedSubview(UIView(frame: .zero))
                heightConstraint?.deactivate()
            }
            
            completion?(self, imageResult.error)
            return
        }
        
        if hasActions {
            DispatchQueue.main.async { [weak self] in self?.activityIndicatorView.stopAnimating() }
        }
        
        var width = attachment.isImage && !hasActions ? defaultHeight : maxWidth
        var height = defaultHeight
        
        if image.size.height > 0 {
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
        }
        
        if isLink {
            imageView.contentMode = .scaleAspectFill
        } else {
            showGif()
        }
        
        calculatedSize = CGSize(width: width, height: height)
        
        completion?(self, nil)
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
        
        if let style = self.style {
            button.setTitleColor(style.textColor, for: .normal)
            button.setTitleColor(style.replyColor, for: .highlighted)
            button.setTitleColor(style.infoColor, for: .disabled)
        }
        
        return button
    }
}
