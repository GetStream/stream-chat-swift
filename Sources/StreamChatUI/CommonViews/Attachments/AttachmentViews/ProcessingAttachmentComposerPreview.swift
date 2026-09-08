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

    /// The processing progress, a value between 0 and 1.
    public var progress: Double = 0 {
        didSet {
            guard progress != oldValue else { return }
            updateContentIfNeeded()
        }
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

    /// Dims the preview and shows upload-style progress while the attachment is processed.
    open private(set) lazy var uploadingOverlay: UploadingOverlayView = components
        .uploadingOverlayView.init()
        .withoutAutoresizingMaskConstraints

    override open func setUpAppearance() {
        super.setUpAppearance()

        layer.masksToBounds = true
        layer.cornerRadius = 12
        backgroundColor = appearance.colorPalette.backgroundCoreSurfaceSubtle

        imageView.contentMode = .scaleAspectFill
        imageView.isAccessibilityElement = false
        if #available(iOS 17.0, *) {
            imageView.preferredImageDynamicRange = .standard
        }

        layoutMargins = .init(top: 4, left: 4, bottom: 4, right: 4)
        uploadingOverlay.isAccessibilityElement = true
        uploadingOverlay.accessibilityTraits = .updatesFrequently
        uploadingOverlay.uploadingProgressLabel.isAccessibilityElement = false
        uploadingOverlay.loadingIndicator.isAccessibilityElement = false
    }

    override open func setUpLayout() {
        super.setUpLayout()

        embed(imageView)

        addSubview(uploadingOverlay)
        uploadingOverlay.pin(to: self)

        pin(anchors: [.width], to: width)
        pin(anchors: [.height], to: height)
    }

    override open func updateContent() {
        super.updateContent()

        imageView.image = content?.previewImage
        let showsProgress = content?.type == .video
        uploadingOverlay.isHidden = !showsProgress
        uploadingOverlay.isAccessibilityElement = showsProgress
        isAccessibilityElement = !showsProgress
        if showsProgress {
            uploadingOverlay.content = uploadingState
            uploadingOverlay.accessibilityLabel = L10n.Composer.MediaProcessing.Accessibility.preparingVideo
            uploadingOverlay.accessibilityValue = appearance.formatters.uploadingProgress.format(progress)
            accessibilityLabel = nil
            accessibilityValue = nil
        } else {
            accessibilityLabel = L10n.Composer.MediaProcessing.Accessibility.preparingPhoto
            accessibilityValue = nil
        }
    }

    private var uploadingState: AttachmentUploadingState {
        AttachmentUploadingState(
            localFileURL: URL(fileURLWithPath: "/"),
            state: .uploading(progress: progress),
            file: AttachmentFile(type: .generic, size: 0, mimeType: nil)
        )
    }
}

/// A preview provider for attachments that are still being processed.
public struct ProcessingAttachmentPreview: AttachmentPreviewProvider {
    public let id: UUID
    public let type: AttachmentType
    public let previewImage: UIImage?
    public let progress: Double

    public init(id: UUID, type: AttachmentType, previewImage: UIImage?, progress: Double = 0) {
        self.id = id
        self.type = type
        self.previewImage = previewImage
        self.progress = progress
    }

    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }

    @MainActor
    public func previewView(components: Components) -> UIView {
        let view = components.processingAttachmentComposerPreview.init()
        view.progress = progress
        view.content = .init(previewImage: previewImage, type: type)
        return view
    }
}
