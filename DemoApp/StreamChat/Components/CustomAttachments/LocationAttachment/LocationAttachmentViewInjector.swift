//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class LocationAttachmentViewInjector: AttachmentViewInjector {
    lazy var locationAttachmentView = LocationAttachmentSnapshotView()

    let mapWidth: CGFloat = 300

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(locationAttachmentView, at: 0)
        contentView.bubbleThreadFootnoteContainer.width(mapWidth)

        locationAttachmentView.didTapOnLocation = { [weak self] in
            self?.handleTapOnLocationAttachment()
        }
        locationAttachmentView.didTapOnStopSharingLocation = { [weak self] in
            self?.handleTapOnStopSharingLocation()
        }

        let isSentByCurrentUser = contentView.content?.isSentByCurrentUser == true
        let maskedCorners: CACornerMask = isSentByCurrentUser
            ? [.layerMinXMaxYCorner, .layerMinXMinYCorner]
            : [.layerMinXMinYCorner, .layerMaxXMaxYCorner, .layerMaxXMinYCorner]
        locationAttachmentView.layer.maskedCorners = maskedCorners
        locationAttachmentView.layer.cornerRadius = 16
        locationAttachmentView.layer.masksToBounds = true
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        if let message = contentView.content, let location = message.sharedLocation {
            locationAttachmentView.content = .init(
                message: message,
                location: location
            )
        }
    }

    func handleTapOnLocationAttachment() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        guard let location = contentView.content?.sharedLocation else {
            return
        }

        locationAttachmentDelegate.didTapOnLocation(location)
    }

    func handleTapOnStopSharingLocation() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        guard let location = contentView.content?.sharedLocation else {
            return
        }

        locationAttachmentDelegate.didTapOnStopSharingLocation(location)
    }
}
