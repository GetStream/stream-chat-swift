//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class LocationAttachmentViewInjector: AttachmentViewInjector {
    lazy var locationAttachmentView = LocationAttachmentSnapshotView()

    var locationAttachment: ChatMessageLocationAttachment? {
        attachments(payloadType: LocationAttachmentPayload.self).first
    }

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(locationAttachmentView, at: 0)

        NSLayoutConstraint.activate([
            locationAttachmentView.widthAnchor.constraint(equalToConstant: 250),
            locationAttachmentView.heightAnchor.constraint(equalToConstant: 150)
        ])

        locationAttachmentView.didTapOnLocation = { [weak self] in
            self?.handleTapOnLocationAttachment()
        }
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        locationAttachmentView.coordinate = locationAttachment?.coordinate
    }

    func handleTapOnLocationAttachment() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        guard let locationAttachment = self.locationAttachment else {
            return
        }

        locationAttachmentDelegate.didTapOnLocationAttachment(locationAttachment)
    }
}
