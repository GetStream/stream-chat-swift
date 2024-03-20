//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class AppSettingsPayload_Tests: XCTestCase {
    func testDecoding() throws {
        let url = XCTestCase.mockData(fromJSONFile: "AppSettings")
        let payload = try JSONDecoder.default.decode(AppSettingsPayload.self, from: url)

        XCTAssertEqual(payload.app.name, "Stream SDK - iOS")
        XCTAssertEqual(payload.app.autoTranslationEnabled, true)
        XCTAssertEqual(payload.app.asyncUrlEnrichEnabled, false)
        XCTAssertEqual(payload.app.fileUploadConfig.allowedFileExtensions, ["jpg", "png"])
        XCTAssertEqual(payload.app.fileUploadConfig.blockedFileExtensions, ["webp"])
        XCTAssertEqual(payload.app.fileUploadConfig.allowedMimeTypes, ["image/jpg", "image/png"])
        XCTAssertEqual(payload.app.fileUploadConfig.blockedMimeTypes, ["image/webp"])
        XCTAssertEqual(payload.app.fileUploadConfig.sizeLimit, 104_857_600)
        XCTAssertEqual(payload.app.imageUploadConfig.allowedFileExtensions, ["mp3", "wav"])
        XCTAssertEqual(payload.app.imageUploadConfig.blockedFileExtensions, ["mp4"])
        XCTAssertEqual(payload.app.imageUploadConfig.allowedMimeTypes, ["audio/mp3", "audio/wav"])
        XCTAssertEqual(payload.app.imageUploadConfig.blockedMimeTypes, ["audio/mp4"])
        XCTAssertEqual(payload.app.imageUploadConfig.sizeLimit, 10_485_760)
    }
}
