//
// Copyright © 2024 Stream.io Inc. All rights reserved.
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
        let attachmentCounts = message.attachmentCounts

        if attachmentCounts.keys.contains(.image) || attachmentCounts.keys.contains(.video) {
            if attachmentCounts.keys.contains(.file)
                || attachmentCounts.keys.contains(.voiceRecording)
                || attachmentCounts.keys.contains(.unknown) {
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
        } else if attachmentCounts.keys.contains(.unknown) {
            return components.unsupportedAttachmentInjector
        } else if attachmentCounts.isEmpty == false {
            return components.unsupportedAttachmentInjector
        } else {
            return nil
        }
    }
}

// swiftlint:enable convenience_type
