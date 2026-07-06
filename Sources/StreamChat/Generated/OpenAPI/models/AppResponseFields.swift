//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppResponseFields: Sendable, Codable, JSONEncodable {
    let asyncUrlEnrichEnabled: Bool
    let autoTranslationEnabled: Bool
    let fileUploadConfig: FileUploadConfig
    let id: Int
    let imageUploadConfig: FileUploadConfig
    let name: String
    let placement: String

    init(asyncUrlEnrichEnabled: Bool, autoTranslationEnabled: Bool, fileUploadConfig: FileUploadConfig, id: Int, imageUploadConfig: FileUploadConfig, name: String, placement: String) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.id = id
        self.imageUploadConfig = imageUploadConfig
        self.name = name
        self.placement = placement
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
        case autoTranslationEnabled = "auto_translation_enabled"
        case fileUploadConfig = "file_upload_config"
        case id
        case imageUploadConfig = "image_upload_config"
        case name
        case placement
    }
}
