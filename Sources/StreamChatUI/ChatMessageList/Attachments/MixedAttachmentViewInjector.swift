//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The injector used to combine multiple types of attachment views.
open class MixedAttachmentViewInjector: AttachmentViewInjector {
    /// The registry of injectors associated with their attachment type, that support mixed attachment rendering.
    ///
    /// **Note:** It is an array and not a dictionary, since it defines the order of the rendering of the different types of attachments.
    /// In order to customise the order, this static property can be changed.
    ///
    /// By default, this is the order of how mixed attachments are rendered:
    ///
    ///     1. Images and Videos
    ///     2. Files
    ///     3. Voice Messages
    public static var injectorsRegistry: [(type: AttachmentType, injector: AttachmentViewInjector.Type)] = [
        (.video, GalleryAttachmentViewInjector.self),
        (.image, GalleryAttachmentViewInjector.self),
        (.file, FilesAttachmentViewInjector.self),
        (.voiceRecording, VoiceRecordingAttachmentViewInjector.self)
    ]

    // This property needs to be lazy so that we only create the injectors once.
    open lazy var injectors: [AttachmentViewInjector] = Self.injectors(for: contentView.content).map {
        $0.init(contentView)
    }

    public required init(_ contentView: ChatMessageContentView) {
        super.init(contentView)
    }

    /// Register a custom attachment injector if the attachment can be mixed with other types of attachments.
    ///
    /// **Advanced:** You can use the `injectorsRegistry` property directly in case you want to change the default order
    /// of how different types of attachments are rendered.
    public static func register(_ type: AttachmentType, with injector: AttachmentViewInjector.Type) {
        injectorsRegistry.append((type, injector))
    }

    /// The mixed injectors for the given message.
    ///
    /// Given a message, it determines which injectors it should use to render the attachments.
    public static func injectors(for message: ChatMessage?) -> [AttachmentViewInjector.Type] {
        let injectorsForMessage = Self.injectorsRegistry
            .filter {
                message?.attachmentCounts.keys.contains($0.type) == true
            }

        var injectorsFound: Set<String> = []
        var injectorsWithoutDuplicates: [AttachmentViewInjector.Type] = []
        injectorsForMessage.map(\.injector).forEach { injector in
            let injectorId = String(describing: injector)
            if !injectorsFound.contains(injectorId) {
                injectorsWithoutDuplicates.append(injector)
                injectorsFound.insert(injectorId)
            }
        }

        return injectorsWithoutDuplicates
    }

    override open func contentViewDidLayout(options: ChatMessageLayoutOptions) {
        injectors.forEach { $0.contentViewDidLayout(options: options) }
    }

    override open func contentViewDidUpdateContent() {
        injectors.forEach { $0.contentViewDidUpdateContent() }
    }

    override open func contentViewDidPrepareForReuse() {
        injectors.forEach { $0.contentViewDidPrepareForReuse() }
    }
}
