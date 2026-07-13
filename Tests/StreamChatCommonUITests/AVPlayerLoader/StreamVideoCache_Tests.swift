//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import XCTest

final class StreamVideoCache_Tests: XCTestCase {
    private var root: URL!
    private var directory: URL!
    private var tempDirectory: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = fileManager.temporaryDirectory
            .appendingPathComponent("StreamVideoCache_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        directory = root.appendingPathComponent("cache", isDirectory: true)
        tempDirectory = root.appendingPathComponent("temps", isDirectory: true)
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: root)
        root = nil
        directory = nil
        tempDirectory = nil
        try super.tearDownWithError()
    }

    func test_storeCompletedFile_thenCompletedFileURL_returnsStoredFileWithContents() async throws {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 1_000_000)
        let temp = try makeTempFile(byteCount: 100)

        let storedURL = await cache.storeCompletedFile(at: temp, forKey: "/path/video.mp4", fileExtension: "mp4")
        let cachedURL = await cache.completedFileURL(forKey: "/path/video.mp4", fileExtension: "mp4")

        XCTAssertNotNil(storedURL)
        XCTAssertEqual(cachedURL, storedURL)
        XCTAssertEqual(try Data(contentsOf: try XCTUnwrap(cachedURL)).count, 100)
    }

    func test_completedFileURL_whenNotStored_returnsNil() async {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 1_000_000)

        let cachedURL = await cache.completedFileURL(forKey: "/missing.mp4", fileExtension: "mp4")

        XCTAssertNil(cachedURL)
    }

    func test_remove_deletesCachedEntry() async throws {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 1_000_000)
        _ = await cache.storeCompletedFile(at: try makeTempFile(byteCount: 100), forKey: "/v.mp4", fileExtension: "mp4")

        await cache.remove(forKey: "/v.mp4", fileExtension: "mp4")

        let cachedURL = await cache.completedFileURL(forKey: "/v.mp4", fileExtension: "mp4")
        XCTAssertNil(cachedURL)
    }

    func test_removeAll_clearsCache() async throws {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 1_000_000)
        _ = await cache.storeCompletedFile(at: try makeTempFile(byteCount: 100), forKey: "/v.mp4", fileExtension: "mp4")

        await cache.removeAll()

        let cachedURL = await cache.completedFileURL(forKey: "/v.mp4", fileExtension: "mp4")
        XCTAssertNil(cachedURL)
    }

    func test_storeCompletedFile_whenOverCapacity_evictsOldestCompletedFiles() async throws {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 250)
        _ = await cache.storeCompletedFile(at: try makeTempFile(byteCount: 100), forKey: "a", fileExtension: nil)
        _ = await cache.storeCompletedFile(at: try makeTempFile(byteCount: 100), forKey: "b", fileExtension: nil)
        _ = await cache.completedFileURL(forKey: "a", fileExtension: nil)

        _ = await cache.storeCompletedFile(at: try makeTempFile(byteCount: 100), forKey: "c", fileExtension: nil)

        let a = await cache.completedFileURL(forKey: "a", fileExtension: nil)
        let b = await cache.completedFileURL(forKey: "b", fileExtension: nil)
        let c = await cache.completedFileURL(forKey: "c", fileExtension: nil)
        XCTAssertNotNil(a)
        XCTAssertNil(b)
        XCTAssertNotNil(c)
    }

    func test_temporaryFile_isNotReturnedBeforePromotion() async throws {
        let cache = StreamVideoCache(directory: directory, maxSizeInBytes: 1_000_000)
        let temp = try cache.temporaryFileURL()
        try Data(repeating: 0xab, count: 100).write(to: temp)

        let cachedURL = await cache.completedFileURL(forKey: "/v.mp4", fileExtension: "mp4")

        XCTAssertNil(cachedURL)
    }

    private func makeTempFile(byteCount: Int) throws -> URL {
        let url = tempDirectory.appendingPathComponent(UUID().uuidString)
        try Data(repeating: 0xab, count: byteCount).write(to: url)
        return url
    }
}
