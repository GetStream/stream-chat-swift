//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppResponseFields: Sendable, Codable, JSONEncodable {
    let asyncUrlEnrichEnabled: Bool
    let autoTranslationEnabled: Bool
    let fileUploadConfig: FileUploadConfig
    let imageUploadConfig: FileUploadConfig
    let name: String

    init(asyncUrlEnrichEnabled: Bool, autoTranslationEnabled: Bool, fileUploadConfig: FileUploadConfig, imageUploadConfig: FileUploadConfig, name: String) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.imageUploadConfig = imageUploadConfig
        self.name = name
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        case autoTranslationEnabled = "auto_translation_enabled"
        case fileUploadConfig = "file_upload_config"
        case imageUploadConfig = "image_upload_config"
        case name
    }
}
