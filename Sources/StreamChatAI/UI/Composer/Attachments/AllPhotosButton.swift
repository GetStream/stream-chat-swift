//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import StreamCore
import SwiftUI

/// Opens the full photo library to pick up to ten photos, and adds them as attachments.
@available(iOS 16, *)
struct AllPhotosButton: View {
    let viewModel: AIComposerViewModel
    let photoLibrary: PhotoLibraryService

    @State private var selection: [PhotosPickerItem] = []

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        // Read here: the picker builds its label in a Sendable closure.
        let padding = EdgeInsets(top: layout.spacingXs, leading: layout.spacingSm, bottom: layout.spacingXs, trailing: layout.spacingSm)
        let background = Color(colors.attachmentPickerButtonBackground)
        PhotosPicker(
            selection: $selection,
            maxSelectionCount: 10,
            matching: .images
        ) {
            Text(L10n.Composer.buttonAllPhotos)
                .padding(padding)
                .background(background)
                .clipShape(Capsule())
        }
        .onChange(of: selection) { newItems in
            guard !newItems.isEmpty else { return }

            Task {
                await addAttachments(from: newItems)
                selection = []
            }
        }
    }

    // Prefers the photo's file in the library, then a file the item can hand over, and only
    // then copies its data into a temporary file.
    private func addAttachments(from items: [PhotosPickerItem]) async {
        for item in items {
            if let identifier = item.itemIdentifier,
               let asset = photoLibrary.asset(for: identifier),
               let url = await photoLibrary.fileURL(for: asset) {
                viewModel.appendAttachment(.init(url: url, isTemporary: false))
                continue
            }

            if let url = try? await item.loadTransferable(type: URL.self) {
                viewModel.appendAttachment(.init(url: url, isTemporary: false))
                continue
            }

            if let data = try? await item.loadTransferable(type: Data.self),
               let tempURL = writeAttachmentDataToTemporaryURL(data) {
                viewModel.appendAttachment(.init(url: tempURL, isTemporary: true))
            }
        }
    }
}
