//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Photos
import SwiftUI
import UIKit

@available(iOS 16, *)
struct RecentPhotoThumbnail: View {
    enum SelectionChange {
        case select(AttachmentLocation)
        case deselect
        case failed
    }
    
    let asset: PHAsset
    @ObservedObject var service: PhotoLibraryService
    let isSelected: Bool
    let onSelectionChange: (SelectionChange) -> Void
    
    @State private var image: UIImage?
    @State private var didFail = false
    @State private var isFetchingAttachment = false
    
    var body: some View {
        Button {
            Task {
                if isSelected {
                    didFail = false
                    onSelectionChange(.deselect)
                    return
                }
                
                guard !isFetchingAttachment else { return }
                didFail = false
                isFetchingAttachment = true
                
                var attachment: AttachmentLocation?
                if let url = await service.fileURL(for: asset) {
                    attachment = .init(url: url, isTemporary: false)
                } else if let data = await service.data(for: asset),
                          let tempURL = writeAttachmentDataToTemporaryURL(data) {
                    attachment = .init(url: tempURL, isTemporary: true)
                }
                isFetchingAttachment = false
                if let attachment {
                    didFail = false
                    onSelectionChange(.select(attachment))
                } else {
                    didFail = true
                    onSelectionChange(.failed)
                }
            }
        } label: {
            ThumbnailTile(image: image, didFail: didFail)
                .overlay(alignment: .topTrailing) {
                    SelectionBadge(isSelected: isSelected)
                        .padding(6)
                }
        }
        .disabled(isFetchingAttachment)
        .task {
            guard image == nil else { return }
            let scale = UIScreen.main.scale
            let size = CGSize(width: 100 * scale, height: 100 * scale)
            if let thumbnail = await service.thumbnail(for: asset, targetSize: size) {
                image = thumbnail
                didFail = false
            } else {
                didFail = true
            }
        }
        .onChange(of: isSelected) { selected in
            if !selected {
                didFail = false
            }
        }
    }
}
