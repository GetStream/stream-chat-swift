//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import StreamCore
import SwiftUI

/// Opens the full photo library to pick up to ten photos, and hands over each one's file.
@available(iOS 16, *)
struct AllPhotosButton: View {
    let photoLibrary: PhotoLibraryService
    let onPick: (AttachmentLocation) -> Void
    // Called once for a selection when some of its photos couldn't be loaded.
    let onFailure: () -> Void

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
                await pick(newItems)
                selection = []
            }
        }
    }

    private func pick(_ items: [PhotosPickerItem]) async {
        var didFail = false
        for item in items {
            if let attachment = await attachment(for: item) {
                onPick(attachment)
            } else {
                didFail = true
            }
        }
        if didFail {
            onFailure()
        }
    }

    // Prefers the photo's file in the library, then a file the item can hand over, and only
    // then copies its data into a temporary file.
    private func attachment(for item: PhotosPickerItem) async -> AttachmentLocation? {
        if let identifier = item.itemIdentifier,
           let asset = photoLibrary.asset(for: identifier),
           let url = await photoLibrary.fileURL(for: asset) {
            return .init(url: url, isTemporary: false)
        }

        if let url = try? await item.loadTransferable(type: URL.self) {
            return .init(url: url, isTemporary: false)
        }

        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let tempURL = writeAttachmentDataToTemporaryURL(data) else { return nil }
            return .init(url: tempURL, isTemporary: true)
        } catch {
            // Such as a photo in iCloud without a network connection.
            log.error("Couldn't load a picked photo", error: error)
            return nil
        }
    }
}
