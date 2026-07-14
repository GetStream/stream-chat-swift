//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import StreamCore
import XCTest

final class LRUDiskCache_Tests: XCTestCase {
    private var root: URL!
    private var directory: URL!
    private let fileManager = FileManager.default

    override func setUpWithError() throws {
        try super.setUpWithError()
        root = fileManager.temporaryDirectory
            .appendingPathComponent("LRUDiskCache_Tests", isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        directory = root.appendingPathComponent("cache", isDirectory: true)
    }

    override func tearDownWithError() throws {
        try? fileManager.removeItem(at: root)
        root = nil
        directory = nil
        try super.tearDownWithError()
    }

    func test_storeData_whenEntryExceedsMaxSize_rejectsEntry() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 50)

        let storeError = store(Data(repeating: 0xab, count: 100), forKey: "big", in: cache)
        let cached = data(forKey: "big", in: cache)

        XCTAssertNotNil(storeError)
        XCTAssertNil(cached)
    }

    func test_data_whenCacheIsDisabled_doesNotReadOrRemoveSharedEntry() {
        let enabled = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        let disabled = LRUDiskCache(directory: directory, maxSizeInBytes: 0)
        let expected = Data([0x01])
        store(expected, forKey: "image", in: enabled)

        let disabledResult = data(forKey: "image", in: disabled)
        let enabledResult = data(forKey: "image", in: enabled)

        XCTAssertNil(disabledResult)
        XCTAssertEqual(enabledResult, expected)
    }

    func test_data_whenExistingEntryExceedsLimit_removesEntryAndReturnsNil() {
        let seed = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 50)
        store(Data(repeating: 0x01, count: 100), forKey: "image", in: seed)

        let cached = data(forKey: "image", in: cache)
        let removed = data(forKey: "image", in: seed)

        XCTAssertNil(cached)
        XCTAssertNil(removed)
    }

    func test_data_whenAnotherInstanceStoredEntry_returnsData() {
        let first = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        let second = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        store(Data([0x01]), forKey: "first", in: first)
        store(Data([0x02]), forKey: "second", in: second)

        let cached = data(forKey: "second", in: first)

        XCTAssertEqual(cached, Data([0x02]))
    }

    func test_store_acrossInstances_enforcesSharedDirectoryLimit() throws {
        let first = LRUDiskCache(directory: directory, maxSizeInBytes: 100)
        let second = LRUDiskCache(directory: directory, maxSizeInBytes: 100)
        store(Data(repeating: 0x01, count: 60), forKey: "a", in: first)
        store(Data(repeating: 0x02, count: 60), forKey: "b", in: second)

        store(Data(repeating: 0x03, count: 60), forKey: "c", in: first)

        XCTAssertLessThanOrEqual(try cacheSize(), 100)
    }

    func test_data_firstAccess_trimsExistingDirectoryToConfiguredLimit() throws {
        let seed = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        store(Data(repeating: 0x01, count: 60), forKey: "a", in: seed)
        store(Data(repeating: 0x02, count: 60), forKey: "b", in: seed)
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 100)

        _ = data(forKey: "b", in: cache)

        XCTAssertLessThanOrEqual(try cacheSize(), 100)
    }

    func test_store_thenData_returnsStoredContents() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        let expected = Data(repeating: 0xab, count: 100)

        let storeError = store(expected, forKey: "image", in: cache)
        let cached = data(forKey: "image", in: cache)

        XCTAssertNil(storeError)
        XCTAssertEqual(cached, expected)
    }

    func test_data_whenNotStored_returnsNil() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        let cached = data(forKey: "missing", in: cache)
        XCTAssertNil(cached)
    }

    func test_data_callsCompletionOffTheMainThread() {
        let enabled = LRUDiskCache(directory: directory, maxSizeInBytes: 1000)
        let disabled = LRUDiskCache(directory: directory, maxSizeInBytes: 0)
        let expectation = expectation(description: "completions")
        expectation.expectedFulfillmentCount = 2
        let completedOnMain = AllocatedUnfairLock(false)

        enabled.data(forKey: "missing") { _ in
            if Thread.isMainThread { completedOnMain.value = true }
            expectation.fulfill()
        }
        disabled.data(forKey: "missing") { _ in
            if Thread.isMainThread { completedOnMain.value = true }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5)
        XCTAssertFalse(completedOnMain.value)
    }

    func test_store_whenOverCapacity_evictsLeastRecentlyUsed() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 250)
        store(Data(repeating: 0x01, count: 100), forKey: "a", in: cache)
        store(Data(repeating: 0x02, count: 100), forKey: "b", in: cache)
        _ = data(forKey: "a", in: cache)
        store(Data(repeating: 0x03, count: 100), forKey: "c", in: cache)

        let a = data(forKey: "a", in: cache)
        let b = data(forKey: "b", in: cache)
        let c = data(forKey: "c", in: cache)
        XCTAssertNotNil(a, "recently used -> survives")
        XCTAssertNil(b, "least recently used -> evicted")
        XCTAssertNotNil(c, "just stored -> survives")
    }

    func test_store_overwritingExistingKey_replacesContents() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        store(Data(repeating: 0x01, count: 100), forKey: "image", in: cache)
        let expected = Data(repeating: 0x02, count: 175)
        store(expected, forKey: "image", in: cache)

        let cached = data(forKey: "image", in: cache)
        XCTAssertEqual(cached, expected)
    }

    func test_remove_deletesCachedEntry() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        store(Data([0x01]), forKey: "image", in: cache)

        remove(forKey: "image", in: cache)

        let cached = data(forKey: "image", in: cache)
        XCTAssertNil(cached)
    }

    func test_remove_afterRemoval_canStoreSameKeyAgain() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        store(Data([0x01]), forKey: "image", in: cache)
        remove(forKey: "image", in: cache)
        let expected = Data([0x02])

        let storeError = store(expected, forKey: "image", in: cache)
        let cached = data(forKey: "image", in: cache)

        XCTAssertNil(storeError)
        XCTAssertEqual(cached, expected)
    }

    func test_data_bumpsModificationDate_soRecencySurvivesReload() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 250)
        store(Data(repeating: 0x01, count: 100), forKey: "a", in: cache)
        store(Data(repeating: 0x02, count: 100), forKey: "b", in: cache)
        _ = data(forKey: "a", in: cache)

        let reloaded = LRUDiskCache(directory: directory, maxSizeInBytes: 250)
        store(Data(repeating: 0x03, count: 100), forKey: "c", in: reloaded)

        let a = data(forKey: "a", in: reloaded)
        let b = data(forKey: "b", in: reloaded)
        let c = data(forKey: "c", in: reloaded)
        XCTAssertNotNil(a, "touched before reload -> survives")
        XCTAssertNil(b, "least recently used -> evicted after reload")
        XCTAssertNotNil(c, "just stored -> survives")
    }

    func test_removeAll_clearsCache() {
        let cache = LRUDiskCache(directory: directory, maxSizeInBytes: 1_000_000)
        store(Data([0x01]), forKey: "image", in: cache)

        removeAll(in: cache)

        let cached = data(forKey: "image", in: cache)
        XCTAssertNil(cached)
    }

    // MARK: - Helpers

    @discardableResult
    private func store(_ data: Data, forKey key: String, in cache: LRUDiskCache) -> Error? {
        let expectation = expectation(description: "store \(key)")
        let result = AllocatedUnfairLock<Error?>(nil)
        cache.store(data, forKey: key) {
            result.value = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result.value
    }

    private func data(forKey key: String, in cache: LRUDiskCache) -> Data? {
        let expectation = expectation(description: "data \(key)")
        let result = AllocatedUnfairLock<Data?>(nil)
        cache.data(forKey: key) {
            result.value = $0
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5)
        return result.value
    }

    private func remove(forKey key: String, in cache: LRUDiskCache) {
        let expectation = expectation(description: "remove \(key)")
        cache.remove(forKey: key) { expectation.fulfill() }
        wait(for: [expectation], timeout: 5)
    }

    private func removeAll(in cache: LRUDiskCache) {
        let expectation = expectation(description: "removeAll")
        cache.removeAll { expectation.fulfill() }
        wait(for: [expectation], timeout: 5)
    }

    private func cacheSize() throws -> Int {
        guard fileManager.fileExists(atPath: directory.path) else { return 0 }
        return try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: [.fileSizeKey]
        ).reduce(0) { size, url in
            size + (try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0)
        }
    }
}
