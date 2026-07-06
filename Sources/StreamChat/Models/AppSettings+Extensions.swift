//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreServices
import Foundation

extension AppSettings {
    /// The upload configuration.
    public typealias UploadConfig = StreamChat.UploadConfig
}

extension AppSettings.UploadConfig {
    /// The file size limit allowed in Bytes.
    /// This value is configurable from Stream's Dashboard App Settings.
    @available(*, deprecated, renamed: "sizeLimit")
    public var sizeLimitInBytes: Int64? { Int64(sizeLimit) }
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
