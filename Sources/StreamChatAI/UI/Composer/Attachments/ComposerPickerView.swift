//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import PhotosUI
import StreamCore
import SwiftUI

@available(iOS 16, *)
struct ComposerPickerView: View {
    @ObservedObject var viewModel: AIComposerViewModel
    
    @StateObject private var photoLibrary = PhotoLibraryService()
    @State private var allPhotosSelection: [PhotosPickerItem] = []
    @State private var cameraPresented = false

    @Injected(\.aiAppearance.tokens.layout) private var layout
        
    var body: some View {
        VStack(spacing: layout.spacingMd) {
            HStack {
                Spacer()
                AllPhotosButton(selection: $allPhotosSelection)
                    .padding()
            }
            RecentPhotosRow(viewModel: viewModel, photoLibrary: photoLibrary) {
                cameraPresented = true
            }
            Spacer()
            if !viewModel.chatOptions.isEmpty {
                Divider()
                
                ChatOptionsList(options: viewModel.chatOptions)
            }
        }
        .task {
            await photoLibrary.prepare(limit: 10)
        }
        .onChange(of: allPhotosSelection) { newItems in
            guard !newItems.isEmpty else { return }
            
            Task {
                await addAttachments(from: newItems)
                allPhotosSelection = []
            }
        }
        .fullScreenCover(isPresented: $cameraPresented) {
            CameraPicker(isPresented: $cameraPresented) { result in
                viewModel.appendAttachment(result)
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
