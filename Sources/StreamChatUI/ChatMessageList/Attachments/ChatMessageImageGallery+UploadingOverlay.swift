//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension _ChatMessageImageGallery {
    open class UploadingOverlay: _ChatMessageAttachmentInfoView<ExtraData> {
        public private(set) lazy var fileSizeContainer = UIView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override open func layoutSubviews() {
            super.layoutSubviews()

            fileSizeContainer.layer.cornerRadius = fileSizeContainer.bounds.height / 2
        }

        override public func defaultAppearance() {
            backgroundColor = uiConfig.colorPalette.background4
            fileSizeContainer.backgroundColor = uiConfig.colorPalette.popoverBackground
            fileSizeContainer.layer.masksToBounds = true
            fileSizeLabel.textColor = .white
        }

        override open func setUpLayout() {
            fileSizeContainer.addSubview(spinnerAndSizeStack)
            spinnerAndSizeStack.pin(to: fileSizeContainer.layoutMarginsGuide)
            
            addSubview(fileSizeContainer)
            addSubview(actionIconImageView)

            NSLayoutConstraint.activate([
                actionIconImageView.topAnchor.pin(equalTo: layoutMarginsGuide.topAnchor),
                actionIconImageView.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                
                fileSizeContainer.topAnchor.pin(greaterThanOrEqualTo: layoutMarginsGuide.topAnchor),
                fileSizeContainer.trailingAnchor.pin(equalTo: layoutMarginsGuide.trailingAnchor),
                fileSizeContainer.leadingAnchor.pin(equalTo: layoutMarginsGuide.leadingAnchor),
                fileSizeContainer.bottomAnchor.pin(equalTo: layoutMarginsGuide.bottomAnchor),
                
                loadingIndicator.widthAnchor.pin(equalToConstant: 16)
            ])
        }

        override open func updateContent() {
            super.updateContent()
            
            if case .uploadingFailed = content?.localState {
                fileSizeLabel.text = L10n.Message.Sending.attachmentUploadingFailed
            }

            fileSizeContainer.isVisible = loadingIndicator.isVisible
        }
    }
}
