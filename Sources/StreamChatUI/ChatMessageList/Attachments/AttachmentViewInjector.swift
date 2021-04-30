//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamChat

public typealias AttachmentViewInjector = _AttachmentViewInjector<NoExtraData>

/// An object used for injecting attachment views into `ChatMessageContentView`.
///
/// This is an abstract superclass meant to be subclassed.
open class _AttachmentViewInjector<ExtraData: ExtraDataTypes> {
    /// Called after `parentContentView.prepareForReuse` is called.
    open func prepareForReuse() {}

    /// Called after `parentContentView.setUp` is called.
    open func setUp() {}

    /// Called after `parentContentView.setUpAppearance` is called.
    open func setUpAppearance() {}

    /// Called after the `parentContentView` finished its `layout(options:)` methods.
    open func layout(options: ChatMessageLayoutOptions) {}

    /// Called after `parentContentView.updateContent` is called.
    open func updateContent() {}

    unowned let parentContentView: _ChatMessageContentView<ExtraData>

    public required init(_ parentContentView: _ChatMessageContentView<ExtraData>) {
        self.parentContentView = parentContentView
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
