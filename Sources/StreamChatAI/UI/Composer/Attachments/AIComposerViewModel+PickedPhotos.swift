//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import StreamCore
import SwiftUI

@available(iOS 16, *)
extension AIComposerViewModel {
    // Adds each photo that isn't attached yet. Returns false if some of them couldn't be loaded.
    func addPhotos(_ items: [PhotosPickerItem], from photoLibrary: PhotoLibraryService) async -> Bool {
        var didLoadAll = true
        for item in items {
            if let identifier = item.itemIdentifier, selectedAssetURLs[identifier] != nil {
                continue
            }

            guard let attachment = await attachment(for: item, from: photoLibrary) else {
                didLoadAll = false
                continue
            }

            if let identifier = item.itemIdentifier {
                selectAsset(assetID: identifier, attachment: attachment)
            } else {
                appendAttachment(attachment)
            }
        }
        return didLoadAll
    }

    // Prefers the photo's file in the library, and otherwise copies the photo into a temporary file.
    private func attachment(for item: PhotosPickerItem, from photoLibrary: PhotoLibraryService) async -> AttachmentLocation? {
        if let identifier = item.itemIdentifier,
           let asset = photoLibrary.asset(for: identifier),
           let url = await photoLibrary.fileURL(for: asset) {
            return .init(url: url, isTemporary: false)
        }

        do {
            guard let file = try await item.loadTransferable(type: PickedPhotoFile.self) else { return nil }
            return .init(url: file.url, isTemporary: true)
        } catch {
            // Such as a photo in iCloud without a network connection.
            log.error("Couldn't load a picked photo", error: error)
            return nil
        }
    }
}
