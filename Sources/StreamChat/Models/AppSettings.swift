//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing the app settings.
public struct AppSettings {
    /// The name of the app.
    public let name: String
    /// The the file uploading configuration.
    public let fileUploadConfig: UploadConfig
    /// The the image uploading configuration.
    public let imageUploadConfig: UploadConfig
    /// A boolean value determining if auto translation is enabled.
    public let autoTranslationEnabled: Bool
    /// A boolean value determining if async url enrichment is enabled.
    public let asyncUrlEnrichEnabled: Bool

    public struct UploadConfig {
        /// The allowed file extensions.
        public let allowedFileExtensions: [String]
        /// The blocked file extensions.
        public let blockedFileExtensions: [String]
        /// The allowed mime types.
        public let allowedMimeTypes: [String]
        /// The blocked mime types.
        public let blockedMimeTypes: [String]
        /// The file size limit allowed in Bytes.
        /// This value is configurable from Stream's Dashboard App Settings.
        public let sizeLimitInBytes: Int64?
    }
}

// MARK: - Payload -> Model

extension AppSettingsPayload {
    func asModel() -> AppSettings {
        .init(
            name: app.name,
            fileUploadConfig: app.fileUploadConfig.asModel(),
            imageUploadConfig: app.imageUploadConfig.asModel(),
            autoTranslationEnabled: app.autoTranslationEnabled,
            asyncUrlEnrichEnabled: app.asyncUrlEnrichEnabled
        )
    }
}

extension AppSettingsPayload.UploadConfigPayload {
    func asModel() -> AppSettings.UploadConfig {
        .init(
            allowedFileExtensions: allowedFileExtensions,
            blockedFileExtensions: blockedFileExtensions,
            allowedMimeTypes: allowedMimeTypes,
            blockedMimeTypes: blockedMimeTypes,
            sizeLimitInBytes: sizeLimit
        )
    }
}
