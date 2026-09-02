//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// A placeholder preview shown while a picked photo or video is still being
/// downloaded, written to disk, or compressed.
open class ProcessingAttachmentComposerPreview: _View, ThemeProvider {
    open var width: CGFloat = 100
    open var height: CGFloat = 100

    /// The data shown while the attachment is processed.
    public var content: Content? {
        didSet { updateContentIfNeeded() }
    }

    public struct Content {
        /// The optional system preview image provided by the item provider.
        public var previewImage: UIImage?
        /// The type of the attachment that is being processed.
        public var type: AttachmentType

        public init(previewImage: UIImage?, type: AttachmentType) {
            self.previewImage = previewImage
            self.type = type
        }
    }

    /// The view that displays the preview image, if one is already available.
    open private(set) lazy var imageView: UIImageView = UIImageView()
        .withoutAutoresizingMaskConstraints

    /// Dims the preview while the attachment is being processed.
    open private(set) lazy var processingOverlayView: UIView = UIView()
        .withoutAutoresizingMaskConstraints

    /// The system spinner shown while the attachment is being processed.
    open private(set) lazy var processingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = false
        return indicator.withoutAutoresizingMaskConstraints
    }()

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        layer.cornerRadius = 12
        backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle

        imageView.contentMode = .scaleAspectFill
        if #available(iOS 17.0, *) {
            imageView.preferredImageDynamicRange = .standard
        }

        // A transparent overlay until the thumbnail arrives, otherwise the cell
        // reads as a black square. `isOpaque` must be false or a translucent
        // background is composited as solid black.
        processingOverlayView.isOpaque = false
        processingOverlayView.backgroundColor = .clear
        processingOverlayView.isAccessibilityElement = true
        processingOverlayView.accessibilityTraits = .updatesFrequently
        processingIndicator.isAccessibilityElement = false
        processingIndicator.startAnimating()
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(imageView)

        addSubview(processingOverlayView)
        processingOverlayView.pin(to: self)
        processingOverlayView.addSubview(processingIndicator)
        processingIndicator.pin(anchors: [.centerX, .centerY], to: processingOverlayView)

        pin(anchors: [.width], to: width)
        pin(anchors: [.height], to: height)
    }

    override open func updateContent() {
        super.updateContent()

        imageView.image = content?.previewImage
        processingOverlayView.backgroundColor = content?.previewImage == nil
            ? .clear
            : UIColor.black.withAlphaComponent(0.35)
        processingOverlayView.accessibilityLabel = L10n.Composer.VideoCompression.preparing
    }
}

/// A preview provider for attachments that are still being processed.
public struct ProcessingAttachmentPreview: AttachmentPreviewProvider {
    public let id: UUID
    public let type: AttachmentType
    public let previewImage: UIImage?

    public init(id: UUID, type: AttachmentType, previewImage: UIImage?) {
        self.id = id
        self.type = type
        self.previewImage = previewImage
    }

    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }

    @MainActor
    public func previewView(components: Components) -> UIView {
        let view = components.processingAttachmentComposerPreview.init()
        view.content = .init(previewImage: previewImage, type: type)
        view.imageView.image = previewImage
        return view
    }
}
