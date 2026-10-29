//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

struct ComposerPickerView: View {
    @ObservedObject var viewModel: AIComposerViewModel

    @StateObject private var photoLibrary = PhotoLibraryService()
    @State private var cameraPresented = false

    @Injected(\.aiAppearance.tokens.layout) private var layout

    var body: some View {
        VStack(spacing: layout.spacingMd) {
            HStack {
                Spacer()
                if #available(iOS 16, *) {
                    AllPhotosButton(viewModel: viewModel, photoLibrary: photoLibrary)
                }
            }
            .padding()
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
        .fullScreenCover(isPresented: $cameraPresented) {
            CameraPicker(isPresented: $cameraPresented) { result in
                viewModel.appendAttachment(result)
            }
        }
    }
}
