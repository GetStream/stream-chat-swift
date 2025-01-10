//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import XCTest

final class AppSettings_Tests: XCTestCase {
    // MARK: - Upload Config Path Extensions
    
    func test_uploadConfig_empty_pathExtension() {
        let config = AppSettings.UploadConfig.mock()
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual(allowedURLs.count, Self.testFileURLs.count)
    }
    
    func test_uploadConfig_noPathExtension() {
        let config = AppSettings.UploadConfig.mock()
        let url = URL(fileURLWithPath: "/A/file")
        XCTAssertTrue(config.isAllowed(localURL: url))
    }
    
    func test_uploadConfig_noPathExtension_allowSet() {
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".txt"],
            allowedMimeTypes: ["text/plain"]
        )
        let url = URL(fileURLWithPath: "/A/file")
        XCTAssertTrue(config.isAllowed(localURL: url))
    }
    
    func test_uploadConfig_allowed_pathExtension() {
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".M4A", ".txt", "zip"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual(["m4a", "txt", "zip"], allowedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_blocked_pathExtension() {
        let config = AppSettings.UploadConfig.mock(
            blockedFileExtensions: [".M4A", ".txt", "zip"]
        )
        let blockedURLs = Self.testFileURLs.filter { !config.isAllowed(localURL: $0) }
        XCTAssertEqual(["m4a", "txt", "zip"], blockedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_invalid_allowedAndBlockedEqual_pathExtension() {
        // Should not happen, but when it does, nothing goes through
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".txt"],
            blockedFileExtensions: [".txt"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual([], allowedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_invalid_allowedAndBlockedMixed_pathExtension() {
        // Should not happen, only either of these should be defined, but when both are, blocked overrides allowed
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".m4a", ".txt"],
            blockedFileExtensions: [".m4a"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual(["txt"], allowedURLs.map(\.pathExtension).sorted())
    }
    
    // MARK: - Upload Config MIME Types
    
    func test_uploadConfig_allowed_mimeType() {
        let config = AppSettings.UploadConfig.mock(
            allowedMimeTypes: ["application/ZIP", "text/plain"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual(["txt", "zip"], allowedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_blocked_mimeType() {
        let config = AppSettings.UploadConfig.mock(
            blockedMimeTypes: ["application/zip", "texT/plain"]
        )
        let blockedURLs = Self.testFileURLs.filter { !config.isAllowed(localURL: $0) }
        XCTAssertEqual(["txt", "zip"], blockedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_invalid_allowedAndBlockedEqual_mimeTypes() {
        // Should not happen, but when it does, nothing goes through
        let config = AppSettings.UploadConfig.mock(
            allowedMimeTypes: ["text/plain"],
            blockedMimeTypes: ["text/plain"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual([], allowedURLs.map(\.pathExtension).sorted())
    }
    
    func test_uploadConfig_invalid_allowedAndBlockedMixed_mimeTypes() {
        // Should not happen, only either of these should be defined, but when both are, blocked overrides allowed
        let config = AppSettings.UploadConfig.mock(
            allowedMimeTypes: ["audio/mp4", "text/plain"],
            blockedMimeTypes: ["audio/mp4"]
        )
        let allowedURLs = Self.testFileURLs.filter { config.isAllowed(localURL: $0) }
        XCTAssertEqual(["txt"], allowedURLs.map(\.pathExtension).sorted())
    }
    
    // MARK: - Upload Config UTI Type Conversion
    
    func test_uploadConfig_allowed_utiType() {
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".m4a"],
            allowedMimeTypes: ["application/ZIP", "text/plain"]
        )
        XCTAssertEqual(["com.apple.m4a-audio", "public.plain-text", "public.zip-archive"], config.allowedUTITypes.sorted())
    }
    
    func test_uploadConfig_blocked_utiType() {
        let config = AppSettings.UploadConfig.mock(
            allowedFileExtensions: [".7z"],
            allowedMimeTypes: ["video/mp4"]
        )
        XCTAssertEqual(["org.7-zip.7-zip-archive", "public.mpeg-4"], config.allowedUTITypes.sorted())
    }
    
    // MARK: - Test Data
    
    static var testFileURLs: [URL] = {
        let pathExtensions = AttachmentFileType.allCases.map(\.rawValue)
        return pathExtensions.map { pathExtension in
            URL(fileURLWithPath: "/A/file.\(pathExtension)")
        }
    }()
}

private extension URL {
    static func fileName(_ fileName: String) -> URL {
        URL(fileURLWithPath: "/A/\(fileName)")
    }
}
