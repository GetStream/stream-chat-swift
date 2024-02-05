//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChat
import UIKit

/// StreamChat's native attachment types.
internal extension AttachmentType {
    static var knownTypes: Set<AttachmentType> {
        [.image, .file, .giphy, .video, .audio, .voiceRecording, .linkPreview]
    }
}

/// Returns all the non-native attachments.
internal extension ChatMessage {
    var unsupportedAttachments: [AnyChatMessageAttachment] {
        allAttachments.filter {
            AttachmentType.knownTypes.contains($0.type) == false
        }
    }
}

/// The injector for unknown/unsupported attachments.
///
/// By default it renders unsupported attachments as file attachments.
public class UnsupportedAttachmentViewInjector: AttachmentViewInjector {
    public lazy var filesAttachmentInjector = FilesAttachmentViewInjector(self.contentView)

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        filesAttachmentInjector.contentViewDidLayout(options: options)
        filesAttachmentInjector.fileAttachmentView.didTapOnAttachment = nil
    }

    override open func contentViewDidUpdateContent() {
        let unsupportedAttachments = contentView.content?.unsupportedAttachments ?? []
        let unsupportedFileAttachments = unsupportedAttachments.map {
            ChatMessageFileAttachment(
                id: $0.id,
                type: $0.type,
                payload: FileAttachmentPayload(
                    title: nil,
                    assetRemoteURL: $0.uploadingState?.localFileURL ?? URL(string: "unknown")!,
                    file: .init(type: .unknown, size: 0, mimeType: nil),
                    extraData: nil
                ),
                uploadingState: $0.uploadingState
            )
        }

        filesAttachmentInjector.fileAttachmentView.content = unsupportedFileAttachments
    }
}
