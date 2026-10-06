//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI
import UIKit

/// The camera, then the most recent photos, each selectable as an attachment.
@available(iOS 16, *)
struct RecentPhotosRow: View {
    @ObservedObject var viewModel: ComposerViewModel
    @ObservedObject var photoLibrary: PhotoLibraryService
    let onCamera: () -> Void

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: layout.spacingSm) {
                Button {
                    onCamera()
                } label: {
                    AttachmentTile {
                        images.attachmentPickerCamera
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(colors.attachmentPickerTileIcon))
                    }
                }
                .tint(Color(colors.attachmentPickerTileIcon))
                .disabled(!UIImagePickerController.isSourceTypeAvailable(.camera))
                
                ForEach(photoLibrary.recentAssets, id: \.localIdentifier) { asset in
                    RecentPhotoThumbnail(
                        asset: asset,
                        service: photoLibrary,
                        isSelected: viewModel.selectedAssetURLs[asset.localIdentifier] != nil
                    ) { change in
                        switch change {
                        case .select(let attachment):
                            viewModel.selectAsset(assetID: asset.localIdentifier, attachment: attachment)
                        case .deselect:
                            viewModel.deselectAsset(assetID: asset.localIdentifier)
                        case .failed:
                            viewModel.deselectAsset(assetID: asset.localIdentifier)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}
