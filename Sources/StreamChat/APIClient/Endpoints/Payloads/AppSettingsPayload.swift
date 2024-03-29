//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The payload of the /GET app request.
struct AppSettingsPayload: Decodable {
    let app: AppPayload

    struct AppPayload: Decodable {
        let name: String
        let fileUploadConfig: UploadConfigPayload
        let imageUploadConfig: UploadConfigPayload
        let autoTranslationEnabled: Bool
        let asyncUrlEnrichEnabled: Bool
    }
    
    struct UploadConfigPayload: Decodable {
        let allowedFileExtensions: [String]
        let blockedFileExtensions: [String]
        let allowedMimeTypes: [String]
        let blockedMimeTypes: [String]
        let sizeLimit: Int64?
    }
}

// MARK: - Codable

extension AppSettingsPayload {
    enum CodingKeys: CodingKey {
        case app
    }
}

extension AppSettingsPayload.AppPayload {
    enum CodingKeys: String, CodingKey {
        case name
        case fileUploadConfig = "file_upload_config"
        case imageUploadConfig = "image_upload_config"
        case autoTranslationEnabled = "auto_translation_enabled"
        case asyncUrlEnrichEnabled = "async_url_enrich_enabled"
    }
}

extension AppSettingsPayload.UploadConfigPayload {
    enum CodingKeys: String, CodingKey {
        case allowedFileExtensions = "allowed_file_extensions"
        case blockedFileExtensions = "blocked_file_extensions"
        case allowedMimeTypes = "allowed_mime_types"
        case blockedMimeTypes = "blocked_mime_types"
        case sizeLimit = "size_limit"
    }
}
