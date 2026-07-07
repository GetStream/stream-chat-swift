//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AppSettings: Sendable, Codable, JSONEncodable {
    public let asyncUrlEnrichEnabled: Bool
    public let autoTranslationEnabled: Bool
    public let fileUploadConfig: UploadConfig
    public let id: Int
    public let imageUploadConfig: UploadConfig
    public let name: String
    public let placement: String

    init(asyncUrlEnrichEnabled: Bool, autoTranslationEnabled: Bool, fileUploadConfig: UploadConfig, id: Int, imageUploadConfig: UploadConfig, name: String, placement: String) {
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
