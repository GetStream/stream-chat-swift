//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

protocol FileListContentViewDelegate: MessageContentViewDelegate {
    func didTapOnFileAttachment(_ attachment: ChatMessageFileAttachment, at indexPath: IndexPath)
}

class FileListContentView<ExtraData: ExtraDataTypes>: MessageContentView<ExtraData> {
    lazy var fileListView = uiConfig
        .messageList
        .messageContentSubviews
        .attachmentSubviews
        .fileAttachmentListView
        .init()
        .withoutAutoresizingMaskConstraints

    override func layout(options: ChatMessageLayoutOptions) {
        super.layout(options: options)

        bubbleContentContainer.insertArrangedSubview(fileListView, at: 0)
        NSLayoutConstraint.activate([
            fileListView.widthAnchor.pin(equalTo: mainContainer.widthAnchor)
                .with(priority: .streamLow)
        ])
    }

    override func updateContent() {
        super.updateContent()

        fileListView.content = fileAttachments
        fileListView.didTapOnAttachment = { [weak self] attachment in
            guard let self = self, let indexPath = self.indexPath else { return }
            (self.delegate as? FileListContentViewDelegate)?.didTapOnFileAttachment(attachment, at: indexPath)
        }
    }
}

private extension FileListContentView {
    var fileAttachments: [ChatMessageFileAttachment] {
        content?.attachments.compactMap { $0 as? ChatMessageFileAttachment } ?? []
    }
}
