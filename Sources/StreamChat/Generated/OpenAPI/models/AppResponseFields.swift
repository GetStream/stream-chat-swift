//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class AppResponseFields: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var asyncUrlEnrichEnabled: Bool
    var autoTranslationEnabled: Bool
    var fileUploadConfig: FileUploadConfig
    var id: Int
    var imageUploadConfig: FileUploadConfig
    var name: String
    var placement: String

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

    static func == (lhs: AppResponseFields, rhs: AppResponseFields) -> Bool {
        lhs.asyncUrlEnrichEnabled == rhs.asyncUrlEnrichEnabled &&
            lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.fileUploadConfig == rhs.fileUploadConfig &&
            lhs.id == rhs.id &&
            lhs.imageUploadConfig == rhs.imageUploadConfig &&
            lhs.name == rhs.name &&
            lhs.placement == rhs.placement
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(asyncUrlEnrichEnabled)
        hasher.combine(autoTranslationEnabled)
        hasher.combine(fileUploadConfig)
        hasher.combine(id)
        hasher.combine(imageUploadConfig)
        hasher.combine(name)
        hasher.combine(placement)
    }
}
