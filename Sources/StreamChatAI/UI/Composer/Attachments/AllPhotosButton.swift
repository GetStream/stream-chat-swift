//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import StreamCore
import SwiftUI

/// Opens the full photo library to pick up to ten photos.
@available(iOS 16, *)
struct AllPhotosButton: View {
    let onPick: ([PhotosPickerItem]) -> Void

    // What the picker shows as selected while it's open. It's cleared once the photos are handed over.
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
            matching: .images,
            // Without a library, picked items have no identifier to find their asset by.
            photoLibrary: .shared()
        ) {
            Text(L10n.Composer.buttonAllPhotos)
                .padding(padding)
                .background(background)
                .clipShape(Capsule())
        }
        .onChange(of: selection) { newItems in
            guard !newItems.isEmpty else { return }

            onPick(newItems)
            selection = []
        }
    }
}
