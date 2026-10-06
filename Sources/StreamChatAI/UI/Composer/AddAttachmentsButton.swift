//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The default leading button for ``ComposerView``.
///
/// Renders a circular `+` icon that, when tapped, opens the attachment picker sheet.
/// The ``ComposerViewFactory/makeLeadingComposerView(options:)`` default implementation
/// returns this view. Supply your own factory method to replace it.
@available(iOS 16, *)
public struct AddAttachmentsButton: View {
    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var onTap: () -> Void
    
    public init(onTap: @escaping () -> Void) {
        self.onTap = onTap
    }
    
    public var body: some View {
        Button {
            onTap()
        } label: {
            images.composerAddAttachment
                .foregroundStyle(Color(colors.composerAttachmentButtonIcon))
                .fontWeight(.semibold)
        }
        .padding(.all, layout.spacingSm)
        .background(Color(colors.composerAttachmentButtonBackground))
        .clipShape(.circle)
    }
}
