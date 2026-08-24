//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class AppSettings: Sendable, Decodable {
    public let asyncUrlEnrichEnabled: Bool
    public let autoTranslationEnabled: Bool
    public let fileUploadConfig: UploadConfig
    public let id: Int
    public let imageUploadConfig: UploadConfig
    public let name: String
    public let placement: String

    init(
        asyncUrlEnrichEnabled: Bool,
        autoTranslationEnabled: Bool,
        fileUploadConfig: UploadConfig,
        id: Int,
        imageUploadConfig: UploadConfig,
        name: String,
        placement: String
    ) {
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

extension AppSettings: Hashable {
    public static func == (
        lhs: AppSettings,
        rhs: AppSettings
    ) -> Bool {
        lhs.asyncUrlEnrichEnabled == rhs.asyncUrlEnrichEnabled &&
            lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.fileUploadConfig == rhs.fileUploadConfig &&
            lhs.id == rhs.id &&
            lhs.imageUploadConfig == rhs.imageUploadConfig &&
            lhs.name == rhs.name &&
            lhs.placement == rhs.placement
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(asyncUrlEnrichEnabled)
        hasher.combine(autoTranslationEnabled)
        hasher.combine(fileUploadConfig)
        hasher.combine(id)
        hasher.combine(imageUploadConfig)
        hasher.combine(name)
        hasher.combine(placement)
    }
}
