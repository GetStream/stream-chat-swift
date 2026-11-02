//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreTransferable
@testable import StreamChatAI
import UniformTypeIdentifiers
import XCTest

// On the main actor: the item provider answers on the main queue, which would be blocked otherwise.
@available(iOS 16, *)
@MainActor
final class PickedPhotoFile_Tests: XCTestCase {
    private var createdFiles: [URL] = []

    override func tearDown() async throws {
        createdFiles.forEach { try? FileManager.default.removeItem(at: $0) }
        createdFiles = []
        try await super.tearDown()
    }

    func test_import_copiesThePhotoIntoATemporaryFile() async throws {
        let photo = FileManager.default.temporaryDirectory.appendingPathComponent("picked-photo-\(UUID().uuidString).jpg")
        try Data([0xff, 0xd8, 0xff, 0xd9]).write(to: photo)
        createdFiles.append(photo)
        let provider = try XCTUnwrap(NSItemProvider(contentsOf: photo))

        let file = try await withCheckedThrowingContinuation { continuation in
            _ = provider.loadTransferable(type: PickedPhotoFile.self) { continuation.resume(with: $0) }
        }
        createdFiles.append(file.url)

        XCTAssertNotEqual(file.url, photo)
        XCTAssertEqual(file.url.deletingLastPathComponent().path, FileManager.default.temporaryDirectory.path)
        XCTAssertEqual(UTType(filenameExtension: file.url.pathExtension), .jpeg)
        XCTAssertEqual(try Data(contentsOf: file.url), try Data(contentsOf: photo))
    }
}
