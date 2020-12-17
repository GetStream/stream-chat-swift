//
// Copyright © 2020 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageImageGallery {
    open class UploadingOverlay: ChatMessageAttachmentInfoView<ExtraData> {
        public private(set) lazy var fileSizeContainer = UIView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override open func layoutSubviews() {
            super.layoutSubviews()

            fileSizeContainer.layer.cornerRadius = fileSizeContainer.bounds.height / 2
        }

        override public func defaultAppearance() {
            backgroundColor = uiConfig.colorPalette.galleryUploadingOverlayBackground
            fileSizeContainer.backgroundColor = uiConfig.colorPalette.galleryUploadingProgressBackground
            fileSizeContainer.layer.masksToBounds = true
            fileSizeLabel.textColor = .white
        }

        override open func setUpLayout() {
            fileSizeContainer.addSubview(spinnerAndSizeStack)
            spinnerAndSizeStack.pin(to: fileSizeContainer.layoutMarginsGuide)
            
            addSubview(fileSizeContainer)
            addSubview(actionIconImageView)

            NSLayoutConstraint.activate([
                actionIconImageView.topAnchor.constraint(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                
                fileSizeContainer.topAnchor.constraint(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileSizeContainer.trailingAnchor.constraint(equalTo: layoutMarginsGuide.trailingAnchor),
                fileSizeContainer.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
                fileSizeContainer.bottomAnchor.constraint(equalTo: layoutMarginsGuide.bottomAnchor),
                
                loadingIndicator.widthAnchor.constraint(equalToConstant: 16)
            ])
        }

        override open func updateContent() {
            super.updateContent()

            if case .uploadingFailed = content?.attachment.localState {
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            }

            fileSizeContainer.isVisible = loadingIndicator.isVisible
        }
    }
}
