//
//  MessageAttachmentPreviewView.swift
//  GetStreamChat
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
    
    private var widthConstraint: Constraint?
    private var imageViewBottomConstraint: Constraint?
    private var imageTask: ImageTask?
    private var isGifImage = false
    private let disposeBag = DisposeBag()
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView(image: UIImage.Icons.image)
        imageView.contentMode = .center
        imageView.clipsToBounds = true
        addSubview(imageView)
        
        imageView.snp.makeConstraints {
            $0.top.equalToSuperview().priority(999)
            $0.left.right.equalToSuperview()
            imageViewBottomConstraint = $0.bottom.equalToSuperview().priority(999).constraint
        }
        
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 3
        label.font = .chatBoldMedium
        label.textColor = .chatBlue
        addSubview(label)
        imageViewBottomConstraint?.deactivate()
        
        label.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(CGFloat.messageEdgePadding).priority(999)
            make.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            make.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            make.bottom.equalTo(urlLabel.snp.top).priority(999)
        }
        
        label.setContentCompressionResistancePriority(.defaultHigh + 20, for: .vertical)
        
        return label
    }()
    
    private lazy var urlLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = .chatSmall
        label.textColor = .chatGray
        addSubview(label)
        
        label.snp.makeConstraints {
            $0.left.equalToSuperview().offset(CGFloat.messageEdgePadding)
            $0.right.equalToSuperview().offset(-CGFloat.messageEdgePadding)
            $0.bottom.equalToSuperview().offset(-CGFloat.messageEdgePadding).priority(999)
        }
        
        label.setContentCompressionResistancePriority(.defaultHigh + 10, for: .vertical)
        
        return label
    }()
    
    public var maxWidth: CGFloat = 0
    
    public var type: AttachmentType = .image {
        didSet { defaultHeight = type.isImage ? .attachmentPreviewHeight : .attachmentPreviewMaxHeight }
    }
    
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
        if superview != nil, widthConstraint == nil {
            snp.makeConstraints {
                $0.height.equalTo(defaultHeight).priority(999)
                widthConstraint = $0.width.equalTo(type.isImage ? defaultHeight : maxWidth).constraint
            }
        }
    }

    func update(attachment: Attachment, maskImage: UIImage? = nil) {
        guard let imageURL = attachment.imageURL else {
            return
        }
        
        if !type.isImage {
            titleLabel.text = attachment.title
            titleLabel.backgroundColor = backgroundColor
            urlLabel.text = attachment.url?.host
            urlLabel.backgroundColor = backgroundColor
            widthConstraint?.update(offset: maxWidth)
        }
        
        let imageRequest = ImageRequest(url: imageURL,
                                        targetSize: CGSize(width: UIScreen.main.scale * maxWidth,
                                                           height: UIScreen.main.scale * .attachmentPreviewHeight),
                                        contentMode: .aspectFit)
        
        let options = ImageLoadingOptions(placeholder: UIImage.Icons.image,
                                          failureImage: UIImage.Icons.close,
                                          contentModes: .init(success: .scaleAspectFill, failure: .center, placeholder: .center))
        
        imageTask = Nuke.loadImage(with: imageRequest, options: options, into: imageView) { [weak self] in
            self?.parseAttachmentImageResponse(response: $0, error: $1, maskImage: maskImage)
        }
    }
    
    private func parseAttachmentImageResponse(response: ImageResponse?, error: Error?, maskImage: UIImage?) {
        var width = type.isImage ? defaultHeight : maxWidth
        
        if let image = response?.image, image.size.height > 0 {
            imageView.backgroundColor = backgroundColor
            
            if type.isImage {
                width = min(image.size.width / image.size.height * defaultHeight, maxWidth)
                widthConstraint?.update(offset: width)
            }
            
            if let url = response?.urlResponse?.url, url.absoluteString.lowercased().contains(".gif") || type == .giphy {
                isGifImage = true
                imageView.setGifFromURL(url)
            }
        } else {
            if let error = error, let url = response?.urlResponse?.url {
                print("⚠️", url, error)
            }
        }
        
        if let maskImage = maskImage {
            let maskView = UIImageView(frame: CGRect(width: width, height: defaultHeight))
            maskView.image = maskImage
            mask = maskView
            layer.cornerRadius = 0
        }
    }
}
