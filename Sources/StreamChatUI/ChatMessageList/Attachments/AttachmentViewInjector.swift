//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

/// An object used for injecting attachment views into `ChatMessageContentView`. The injector is also
/// responsible for updating the content of the injected views.
///
/// - Important: This is an abstract superclass meant to be subclassed.
///
public typealias AttachmentViewInjector = _AttachmentViewInjector<NoExtraData>

/// An object used for injecting attachment views into `ChatMessageContentView`. The injector is also
/// responsible for updating the content of the injected views.
///
/// - Important: This is an abstract superclass meant to be subclassed.
///
open class _AttachmentViewInjector {
    /// Says whether a message content should start filling all available width.
    /// Is `true` by default.
    open var fillAllAvailableWidth: Bool = true
    
    /// Called after `contentView.prepareForReuse` is called.
    open func contentViewDidPrepareForReuse() {}

    /// Called after the `contentView` finished its `layout(options:)` methods.
    open func contentViewDidLayout(options: ChatMessageLayoutOptions) {}

    /// Called after `contentView.updateContent` is called.
    open func contentViewDidUpdateContent() {}

    /// The target view used for injecting the views of this injector.
    public unowned let contentView: _ChatMessageContentView<ExtraData>

    /// Creates a new instance of the injector.
    ///
    /// - Parameter contentView: The target view used for injecting the views of this injector.
    ///
    public required init(_ contentView: _ChatMessageContentView<ExtraData>) {
        self.contentView = contentView
    }

    public func attachments<Payload: AttachmentPayload>(
        payloadType: Payload.Type
    ) -> [_ChatMessageAttachment<Payload>] {
        contentView.content?.attachments(payloadType: payloadType) ?? []
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
