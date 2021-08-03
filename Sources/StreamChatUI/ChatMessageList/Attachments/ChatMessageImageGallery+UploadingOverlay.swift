//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

extension ChatMessageGalleryView {
    open class UploadingOverlay: _View, ThemeProvider {
        public var content: AttachmentUploadingState? {
            didSet { updateContentIfNeeded() }
        }

        public var didTapActionButton: (() -> Void)?
        
        open var minBottomContainerHeight: CGFloat = 24

        // MARK: - Subviews
        
        public private(set) lazy var actionButton: AttachmentActionButton = components
            .attachmentActionButton.init()
            .withoutAutoresizingMaskConstraints
        
        public private(set) lazy var loadingIndicator: ChatLoadingIndicator = components
            .loadingIndicator.init()
            .withoutAutoresizingMaskConstraints

        public private(set) lazy var uploadingProgressLabel: UILabel = UILabel()
            .withoutAutoresizingMaskConstraints
            .withBidirectionalLanguagesSupport
            .withAdjustingFontForContentSizeCategory
        
        public private(set) lazy var bottomContainer = ContainerStackView()
            .withoutAutoresizingMaskConstraints

        // MARK: - Overrides

        override open func layoutSubviews() {
            super.layoutSubviews()

            bottomContainer.layer.cornerRadius = minBottomContainerHeight / 2
        }

        override open func setUp() {
            super.setUp()
            
            actionButton.addTarget(
                self,
                action: #selector(handleTapOnActionButton(_:)),
                for: .touchUpInside
            )
        }

        override open func setUpAppearance() {
            super.setUpAppearance()
            
            uploadingProgressLabel.numberOfLines = 0
            uploadingProgressLabel.textColor = appearance.colorPalette.textInverted
            uploadingProgressLabel.font = appearance.fonts.footnote
            
            bottomContainer.backgroundColor = appearance.colorPalette.background4
        }

        override open func setUpLayout() {
            super.setUpLayout()
            
            loadingIndicator.pin(anchors: [.width, .height], to: 16)

            addSubview(actionButton)
            actionButton.pin(anchors: [.top, .trailing], to: layoutMarginsGuide)
           
            addSubview(bottomContainer)
            bottomContainer.directionalLayoutMargins = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
            bottomContainer.addArrangedSubview(loadingIndicator, respectsLayoutMargins: true)
            bottomContainer.addArrangedSubview(uploadingProgressLabel, respectsLayoutMargins: true)
            bottomContainer.pin(anchors: [.trailing, .bottom], to: layoutMarginsGuide)

            NSLayoutConstraint.activate([
                bottomContainer.leadingAnchor.pin(
                    greaterThanOrEqualTo: layoutMarginsGuide.leadingAnchor
                ),
                bottomContainer.heightAnchor.pin(
                    greaterThanOrEqualToConstant: minBottomContainerHeight
                )
            ])
        }

        override open func updateContent() {
            super.updateContent()
            
            backgroundColor = content.flatMap {
                switch $0.state {
                case .uploaded:
                    return nil
                default:
                    return appearance.colorPalette.background3
                }
            }
            
            actionButton.content = content.flatMap {
                switch $0.state {
                case .pendingUpload, .uploading:
                    // TODO: Return `.cancel` when it's is supported.
                    return nil
                case .uploadingFailed:
                    return .restart
                case .uploaded:
                    return .uploaded
                }
            }
            actionButton.isHidden = actionButton.content == nil
            
            uploadingProgressLabel.text = content.flatMap {
                switch $0.state {
                case let .uploading(progress):
                    return NumberFormatter.uploadingPercentage.string(from: .init(value: progress))
                case .pendingUpload:
                    return NumberFormatter.uploadingPercentage.string(from: 0)
                case .uploaded:
                    return nil
                case .uploadingFailed:
                    return L10n.Message.Sending.attachmentUploadingFailed
                }
            }
            uploadingProgressLabel.isHidden = uploadingProgressLabel.text == nil

            switch content?.state {
            case .pendingUpload, .uploading:
                loadingIndicator.isVisible = true
            default:
                loadingIndicator.isVisible = false
            }
            
            bottomContainer.isHidden = bottomContainer.subviews.allSatisfy(\.isHidden)
        }

        // MARK: - Actions
        
        @objc open func handleTapOnActionButton(_ button: AttachmentActionButton) {
            didTapActionButton?()
        }
    }
}

extension Appearance {
    func fileAttachmentActionIcon(for state: LocalAttachmentState) -> UIImage? {
        images.fileAttachmentActionIcons[state]
    }
}

extension AttachmentUploadingState {
    var fileUploadingProgress: String {
        switch state {
        case let .uploading(progress):
            let uploadedByteCount = Int64(Double(file.size) * progress)
            let uploadedSize = AttachmentFile.sizeFormatter.string(fromByteCount: uploadedByteCount)
            return "\(uploadedSize)/\(file.sizeString)"
        case .pendingUpload:
            return "0/\(file.sizeString)"
        case .uploaded, .uploadingFailed:
            return file.sizeString
        }
    }
}
