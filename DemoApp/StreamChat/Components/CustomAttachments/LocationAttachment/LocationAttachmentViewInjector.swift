//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import StreamChat
import StreamChatUI
import UIKit

class LocationAttachmentViewInjector: AttachmentViewInjector {
    lazy var locationAttachmentView = LocationAttachmentSnapshotView()

    var staticLocationAttachment: ChatMessageStaticLocationAttachment? {
        attachments(payloadType: StaticLocationAttachmentPayload.self).first
    }

    var liveLocationAttachment: ChatMessageLiveLocationAttachment? {
        attachments(payloadType: LiveLocationAttachmentPayload.self).first
    }

    override func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        super.contentViewDidLayout(options: options)

        contentView.bubbleContentContainer.insertArrangedSubview(locationAttachmentView, at: 0)

        locationAttachmentView.didTapOnLocation = { [weak self] in
            self?.handleTapOnLocationAttachment()
        }
        locationAttachmentView.didTapOnStopSharingLocation = { [weak self] in
            self?.handleTapOnStopSharingLocation()
        }
    }

    override func contentViewDidUpdateContent() {
        super.contentViewDidUpdateContent()

        if let staticLocation = staticLocationAttachment {
            locationAttachmentView.content = .init(
                messageId: contentView.content?.id,
                latitude: staticLocation.latitude,
                longitude: staticLocation.longitude,
                isLive: false
            )
        } else if let liveLocation = liveLocationAttachment {
            locationAttachmentView.content = .init(
                messageId: contentView.content?.id,
                latitude: liveLocation.latitude,
                longitude: liveLocation.longitude,
                isLive: liveLocation.stoppedSharing == false || liveLocation.stoppedSharing == nil
            )
        }
    }

    func handleTapOnLocationAttachment() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        if let staticLocationAttachment = self.staticLocationAttachment {
            locationAttachmentDelegate.didTapOnStaticLocationAttachment(staticLocationAttachment)
        } else if let liveLocationAttachment = self.liveLocationAttachment {
            locationAttachmentDelegate.didTapOnLiveLocationAttachment(liveLocationAttachment)
        }
    }

    func handleTapOnStopSharingLocation() {
        guard let locationAttachmentDelegate = contentView.delegate as? LocationAttachmentViewDelegate else {
            return
        }

        guard let locationAttachment = liveLocationAttachment else {
            return
        }

        locationAttachmentDelegate.didTapOnStopSharingLocation(locationAttachment)
    }
}
