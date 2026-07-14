//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatCommonUI
import UIKit
import XCTest

final class ImageMemoryCache_Tests: XCTestCase {
    func test_store_thenImage_returnsStoredImage() {
        let cache = ImageMemoryCache(costLimit: .max)
        let image = DownloadedImage(image: solidImage(side: 32))

        cache.store(image, forKey: "a")

        XCTAssertEqual(cache.image(forKey: "a")?.image, image.image)
        XCTAssertNil(cache.image(forKey: "missing"))
    }

    func test_removeAll_clearsCache() {
        let cache = ImageMemoryCache(costLimit: .max)
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "a")

        cache.removeAll()

        XCTAssertNil(cache.image(forKey: "a"))
        XCTAssertEqual(cache.totalCost, 0)
    }

    func test_trim_evictsLeastRecentlyUsedFirst() {
        let unit = probeUnitCost()
        let cache = ImageMemoryCache(costLimit: .max)
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "a")
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "b")
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "c")

        // Access "a" so "b" becomes the least-recently-used entry.
        _ = cache.image(forKey: "a")

        // Keep room for two entries.
        cache.trim(toCost: unit * 2)

        XCTAssertNotNil(cache.image(forKey: "a"))
        XCTAssertNil(cache.image(forKey: "b"))
        XCTAssertNotNil(cache.image(forKey: "c"))
    }

    func test_trim_toZero_removesEverything() {
        let cache = ImageMemoryCache(costLimit: .max)
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "a")
        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "b")

        cache.trim(toCost: 0)

        XCTAssertNil(cache.image(forKey: "a"))
        XCTAssertNil(cache.image(forKey: "b"))
        XCTAssertEqual(cache.totalCost, 0)
    }

    func test_store_rejectsEntryLargerThanTenPercentOfLimit() {
        let unit = probeUnitCost()
        // 10% of the limit is below a single entry's cost, so it must not be cached.
        let cache = ImageMemoryCache(costLimit: unit * 5)

        cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "a")

        XCTAssertNil(cache.image(forKey: "a"))
    }

    func test_store_overCostLimit_evictsOldestEntries() {
        let unit = probeUnitCost()
        // Room for ~10 entries (each entry is within the 10% per-entry limit).
        let cache = ImageMemoryCache(costLimit: unit * 20)

        for index in 0..<25 {
            cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "key-\(index)")
        }

        XCTAssertLessThanOrEqual(cache.totalCost, unit * 20)
        XCTAssertNil(cache.image(forKey: "key-0"), "The oldest entry should have been evicted")
        XCTAssertNotNil(cache.image(forKey: "key-24"), "The newest entry should be retained")
    }

    func test_didEnterBackground_trimsToTenPercentOfCostLimit() {
        let unit = probeUnitCost()
        let costLimit = unit * 20
        let cache = ImageMemoryCache(costLimit: costLimit)
        for index in 0..<15 {
            cache.store(DownloadedImage(image: solidImage(side: 32)), forKey: "key-\(index)")
        }

        NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification, object: nil)

        XCTAssertLessThanOrEqual(cache.totalCost, costLimit / 10)
    }

    // MARK: - Helpers

    /// The cost of a single test image, measured against an unbounded cache.
    private func probeUnitCost() -> Int {
        let probe = ImageMemoryCache(costLimit: .max)
        probe.store(DownloadedImage(image: solidImage(side: 32)), forKey: "probe")
        return probe.totalCost
    }

    /// A solid-color image with a fixed pixel size (scale 1) so its cost is deterministic.
    private func solidImage(side: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: side, height: side)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
