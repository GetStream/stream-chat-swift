//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class ChartData_Tests: XCTestCase {
    func test_makeBins_spreadsValuesOverEqualRanges() {
        let bins = makeBins([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], targetBins: 10)

        XCTAssertEqual(bins.count, 10)
        XCTAssertEqual(bins.map(\.count), [1, 1, 1, 1, 1, 1, 1, 1, 1, 2], "the largest value falls in the last bin")
        XCTAssertEqual(bins.first?.label, "0.0–1.0")
        XCTAssertEqual(bins.last?.label, "9.0–10.0")
    }

    func test_makeBins_whenThereIsNoRange_returnsNoBins() {
        XCTAssertTrue(makeBins([], targetBins: 10).isEmpty)
        XCTAssertTrue(makeBins([4, 4, 4], targetBins: 10).isEmpty)
    }

    func test_makeBins_whenNoBinsAreRequested_usesOne() {
        XCTAssertEqual(makeBins([1, 2, 3], targetBins: 0).map(\.count), [3])
    }

    func test_pieData_givesEachSliceItsShare() {
        let spec = USpec(title: "Platforms", kind: .pie, series: [
            USeries(name: "Pie", points: [UPoint(x: "iOS", y: 1), UPoint(x: "Android", y: 3)])
        ])

        let slices = pieData(from: spec)

        XCTAssertEqual(slices.map(\.label), ["iOS", "Android"])
        XCTAssertEqual(slices.map(\.value), [1, 3])
        XCTAssertEqual(slices.map(\.pct), [0.25, 0.75])
    }

    func test_pieData_whenSpecHasNoSeries_isEmpty() {
        XCTAssertTrue(pieData(from: USpec(title: nil, kind: .pie, series: [])).isEmpty)
    }
}
