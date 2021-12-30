//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

public protocol AttachmentPreviewProvider {
    /// The view representing the attachment.
    func previewView(components: Components) -> UIView
    
    /// The preferred axis to be used for attachment previews in attachments view.
    static var preferredAxis: NSLayoutConstraint.Axis { get }
}

extension ImageAttachmentPayload: AttachmentPreviewProvider {
    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }

    /// The view representing the attachment.
    public func previewView(components: Components) -> UIView {
        let view = components.imageAttachmentComposerPreview.init()
        view.content = imagePreviewURL
        return view
    }
}

extension WalletAttachmentPayload: AttachmentPreviewProvider {
    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }

    /// The view representing the attachment.
    public func previewView(components: Components) -> UIView {
        let view = components.walletAttachmentComposerPreview.init()
        view.walletAttachment = self
        return view
    }
}

extension FileAttachmentPayload: AttachmentPreviewProvider {
    public static var preferredAxis: NSLayoutConstraint.Axis { .vertical }

    /// The view representing the attachment.
    public func previewView(components: Components) -> UIView {
        let view = components.messageComposerFileAttachmentView.init()
        view.content = .init(
            title: title ?? "",
            size: file.size,
            iconName: assetURL.pathExtension
        )
        return view
    }
}

extension VideoAttachmentPayload: AttachmentPreviewProvider {
    public static var preferredAxis: NSLayoutConstraint.Axis { .horizontal }

    /// The view representing the video attachment.
    public func previewView(components: Components) -> UIView {
        let preview = components.videoAttachmentComposerPreview.init()
        preview.content = videoURL
        return preview
    }
}
