//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// The attachments picked for the next message, each with a button that removes it.
@available(iOS 16, *)
struct SelectedAttachmentsRow: View {
    @ObservedObject var viewModel: ComposerViewModel

    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layout.spacingSm) {
                ForEach(viewModel.attachments, id: \.self) { url in
                    SelectedAttachmentThumbnail(url: url) {
                        withAnimation {
                            viewModel.removeAttachment(url)
                        }
                    }
                }
            }
        }
    }
}
