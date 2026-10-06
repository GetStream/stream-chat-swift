//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import UIKit

func writeAttachmentDataToTemporaryURL(_ data: Data) -> URL? {
    let fileManager = FileManager.default
    let fileURL = fileManager.temporaryDirectory.appendingPathComponent(
        "streamchat-attachment-\(UUID().uuidString).jpg"
    )
    
    let dataToWrite: Data
    if data.starts(with: [0xff, 0xd8]) {
        dataToWrite = data
    } else if let image = UIImage(data: data),
              let jpegData = image.jpegData(compressionQuality: 0.9) {
        dataToWrite = jpegData
    } else {
        return nil
    }
    
    do {
        try dataToWrite.write(to: fileURL, options: [.atomic])
        return fileURL
    } catch {
        print("ComposerView attachment write error: \(error.localizedDescription)")
        return nil
    }
}
