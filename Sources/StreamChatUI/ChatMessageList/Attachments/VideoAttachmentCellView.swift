//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat
import UIKit

/// The view used to display video attachment preview in a gallery inside a message cell
typealias VideoAttachmentCellView = _VideoAttachmentCellView<NoExtraData>

/// A view used to display video attachment preview in a gallery inside a message cell
open class _VideoAttachmentCellView<ExtraData: ExtraDataTypes>: _View, ThemeProvider {
    /// A video attachment the view displays
    open var content: ChatMessageVideoAttachment? {
        didSet { updateContentIfNeeded() }
    }
    
    /// A handler that will be invoked when the view is tapped
    open var didTapOnAttachment: ((ChatMessageVideoAttachment) -> Void)?
    
    /// A handler that will be invoked when action button on uploading overlay is tapped
    open var didTapOnUploadingActionButton: ((ChatMessageVideoAttachment) -> Void)?
    
    /// An image view used to display video preview image
    open private(set) lazy var imageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// A loading indicator that is shown when preview is being loaded
    open private(set) lazy var loadingIndicator = components
        .loadingIndicator.init()
        .withoutAutoresizingMaskConstraints

    /// An uploading overlay that shows video uploading progress
    open private(set) lazy var uploadingOverlay = components
        .imageUploadingOverlay.init()
        .withoutAutoresizingMaskConstraints
    
    /// A button displaying `play` icon.
    open private(set) lazy var playButton = UIButton()
        .withoutAutoresizingMaskConstraints
    
    override open func setUpAppearance() {
        super.setUpAppearance()
        
        imageView.backgroundColor = appearance.colorPalette.background1
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        
        playButton.setImage(appearance.images.bigPlay, for: .normal)
    }

    override open func setUp() {
        super.setUp()
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapOnAttachment(_:)))
        addGestureRecognizer(tapRecognizer)
        
        playButton.addTarget(self, action: #selector(handleTapOnPlay), for: .touchUpInside)
        
        uploadingOverlay.didTapActionButton = { [weak self] in
            guard let self = self, let attachment = self.content else { return }
            
            self.didTapOnUploadingActionButton?(attachment)
        }
    }

    override open func setUpLayout() {
        super.setUpLayout()
        
        addSubview(imageView)
        imageView.pin(to: self)
        
        addSubview(loadingIndicator)
        loadingIndicator.pin(anchors: [.centerX, .centerY], to: self)
        
        addSubview(uploadingOverlay)
        uploadingOverlay.pin(to: self)

        addSubview(playButton)
        playButton.pin(anchors: [.centerY, .centerX], to: self)
    }

    override open func updateContent() {
        super.updateContent()
        
        loadingIndicator.isHidden = false
        imageView.image = nil
        playButton.isVisible = false
        
        if let url = content?.videoURL {
            components.videoPreviewLoader.loadPreviewForVideo(at: url) { [weak self] in
                self?.loadingIndicator.isHidden = true
                
                switch $0 {
                case let .success(preview):
                    self?.imageView.image = preview
                    self?.playButton.isVisible = self?.content?.uploadingState == nil
                case .failure:
                    break
                }
            }
        }
        
        uploadingOverlay.content = content?.uploadingState
        uploadingOverlay.isVisible = uploadingOverlay.content != nil
    }

    /// A handler that is invoked when view is tapped.
    @objc open func handleTapOnAttachment(_ recognizer: UITapGestureRecognizer) {
        guard let attachment = content else { return }
        
        didTapOnAttachment?(attachment)
    }
    
    /// A handler that is invoked when `playButton` is touched up inside.
    @objc open func handleTapOnPlay(_ sender: UIButton) {
        guard let attachment = content else { return }
        
        didTapOnAttachment?(attachment)
    }
}

extension _VideoAttachmentCellView: GalleryItemPreview {
    public var attachmentId: AttachmentId? {
        content?.id
    }
}
