//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// The injector used to combine multiple types of attachment views.
open class MixedAttachmentViewInjector: AttachmentViewInjector {
    /// The injectors that should support mixed attachment rendering.
    static var injectorsRegistry: [AttachmentType: AttachmentViewInjector.Type] = [
        .file: FilesAttachmentViewInjector.self,
        .video: GalleryAttachmentViewInjector.self,
        .image: GalleryAttachmentViewInjector.self,
        .voiceRecording: VoiceRecordingAttachmentViewInjector.self
    ]

    private var _injectors: [AttachmentViewInjector] {
        contentView.content?.attachmentCounts.keys
            .compactMap { Self.injectorsRegistry[$0] }
            .map { $0.init(contentView) }
            ?? []
    }

    open lazy var injectors: [AttachmentViewInjector] = _injectors

    public required init(_ contentView: ChatMessageContentView) {
        super.init(contentView)
    }

    /// Register a custom attachment injector if the attachment can be mixed with other types of attachments.
    public static func register(type: AttachmentType, for injector: AttachmentViewInjector.Type) {
        injectorsRegistry[type] = injector
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
