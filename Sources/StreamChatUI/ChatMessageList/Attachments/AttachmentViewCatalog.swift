//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// A class that is used to determine the AttachmentViewInjector to use for rendering one message's attachments.
/// If your application uses custom attachment types, you will need to create a subclass and override the attachmentViewInjectorClassFor
/// method so that the correct AttachmentViewInjector is used.
@available(iOSApplicationExtension, unavailable)
// swiftlint:disable convenience_type
open class AttachmentViewCatalog {
    open class func attachmentViewInjectorClassFor(
        message: ChatMessage,
        components: Components
    ) -> AttachmentViewInjector.Type? {
        if message.isDeleted { return nil }

        let attachmentCounts = message.attachmentCounts

        if attachmentCounts.keys.contains(.image) || attachmentCounts.keys.contains(.video) {
            if attachmentCounts.keys.contains(.file) || attachmentCounts.keys.contains(.voiceRecording) {
                return components.mixedAttachmentInjector
            } else {
                return components.galleryAttachmentInjector
            }
        } else if attachmentCounts.keys.contains(.voiceRecording), attachmentCounts.count > 1 { // Contains voiceRecording and any other type
            return components.mixedAttachmentInjector
        } else if attachmentCounts.keys.contains(.giphy) {
            return components.giphyAttachmentInjector
        } else if attachmentCounts.keys.contains(.file) {
            return components.filesAttachmentInjector
        } else if attachmentCounts.keys.contains(.linkPreview) {
            return components.linkAttachmentInjector
        } else if attachmentCounts.keys.contains(.voiceRecording) {
            return components.isVoiceRecordingEnabled
                ? components.voiceRecordingAttachmentInjector
                : components.filesAttachmentInjector
        } else {
            return nil
        }
    }
}

// swiftlint:enable convenience_type
