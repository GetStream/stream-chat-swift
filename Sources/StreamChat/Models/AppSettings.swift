//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreServices
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

// MARK: - Validation

extension AppSettings.UploadConfig {
    // MARK: - UTI Validation
    
    /// Returns an array of allowed UTI identifiers based on allowed mime types and file extensions.
    public var allowedUTITypes: [String] {
        allowedMimeTypes.compactMap { $0.utiType(mime: true) } +
            allowedFileExtensions.compactMap { $0.utiType(mime: false) }
    }
    
    /// Returns an array of blocked UTI identifiers based on allowed mime types and file extensions.
    public var blockedUTITypes: [String] {
        blockedMimeTypes.compactMap { $0.utiType(mime: true) } +
            blockedFileExtensions.compactMap { $0.utiType(mime: false) }
    }
    
    // MARK: - URL Validation
    
    func isAllowed(localURL: URL) -> Bool {
        guard !localURL.pathExtension.isEmpty else { return true }
        
        if !allowedFileExtensions.isEmpty || !blockedFileExtensions.isEmpty {
            if !isAllowed(pathExtension: localURL.pathExtension.lowercased()) {
                return false
            }
        }
        if !allowedMimeTypes.isEmpty || !blockedMimeTypes.isEmpty {
            let mimeType = AttachmentFileType(ext: localURL.pathExtension).mimeType.lowercased()
            if !isAllowed(mimeType: mimeType) {
                return false
            }
        }
        return true
    }
    
    private func isAllowed(pathExtension: String) -> Bool {
        let isBlocked = blockedFileExtensions.contains { blocked in
            blocked.drop(while: { $0 == Character(".") }).caseInsensitiveCompare(pathExtension) == .orderedSame
        }
        guard !isBlocked else { return false }
        guard !allowedFileExtensions.isEmpty else { return true }
        return allowedFileExtensions.contains { allowed in
            allowed.drop(while: { $0 == Character(".") }).caseInsensitiveCompare(pathExtension) == .orderedSame
        }
    }
    
    private func isAllowed(mimeType: String) -> Bool {
        let isBlocked = blockedMimeTypes.contains { blocked in
            blocked.caseInsensitiveCompare(mimeType) == .orderedSame
        }
        guard !isBlocked else { return false }
        guard !allowedMimeTypes.isEmpty else { return true }
        return allowedMimeTypes.contains { allowed in
            allowed.caseInsensitiveCompare(mimeType) == .orderedSame
        }
    }
}

private extension String {
    func utiType(mime: Bool) -> String? {
        let string = mime ? self : String(drop(while: { $0 == Character(".") }))
        return UTTypeCreatePreferredIdentifierForTag(
            mime ? kUTTagClassMIMEType : kUTTagClassFilenameExtension,
            string as CFString,
            nil
        )?.takeRetainedValue() as? String
    }
}
