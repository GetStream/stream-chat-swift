//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreTransferable
import Foundation
import UniformTypeIdentifiers

// A photo picked in the photo library, copied into a temporary file.
@available(iOS 16, *)
struct PickedPhotoFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(importedContentType: .image) { received in
            // The received file is removed once this returns.
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("streamchat-attachment-\(UUID().uuidString)")
                .appendingPathExtension(received.file.pathExtension)
            try FileManager.default.copyItem(at: received.file, to: url)
            return PickedPhotoFile(url: url)
        }
    }
}
