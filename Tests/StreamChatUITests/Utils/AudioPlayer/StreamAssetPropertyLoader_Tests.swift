//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChatUI
import XCTest

final class StreamAssetPropertyLoader_Tests: XCTestCase {
    private lazy var subject: StreamAssetPropertyLoader! = .init()
    private lazy var mockAsset: MockAVURLAsset! = .init(url: .init(string: "http://getstream.io")!)

    override func tearDownWithError() throws {
        mockAsset = nil
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - loadProperty

    func test_loadProperty_assetPropertyStatusReturnsAsLoading_completionWillNotBeCalled() throws {
        try assertDurationLoading(
            propertyStatus: .loading
        ) { result in
            XCTAssertNil(result)
        }
    }

    func test_loadProperty_assetPropertyStatusReturnsAsLoaded_completionWasCalledWithExpectedValue() throws {
        mockAsset.statusOfValueResult = .loaded
        mockAsset.stubbedDuration = .init(seconds: 10, preferredTimescale: CMTimeScale(NSEC_PER_SEC))

        try assertDurationLoading(
            propertyStatus: .loaded
        ) { result in
            let result = try XCTUnwrap(result)
            switch result {
            case let .success(duration):
                XCTAssertEqual(duration, 10)
            case .failure:
                XCTFail()
            }
        }
    }

    func test_loadProperty_assetPropertyStatusReturnsAsCancelled_completionWasCalledWithExpectedError() throws {
        try assertDurationLoading(
            propertyStatus: .cancelled
        ) { result in
            let result = try XCTUnwrap(result)
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertEqual(error as? AssetPropertyLoadingError, .cancelled)
            }
        }
    }

    func test_loadProperty_assetPropertyStatusReturnsFailedWithError_completionWasCalledWithExpectedError() throws {
        let expectedError = NSError(domain: "test", code: 100)
        mockAsset.statusOfValueError = expectedError

        try assertDurationLoading(
            propertyStatus: .failed
        ) { result in
            let result = try XCTUnwrap(result)
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertEqual(error as NSError, expectedError)
            }
        }
    }

    func test_loadProperty_assetPropertyStatusReturnsFailedWithoutError_completionWasCalledWithExpectedError() throws {
        try assertDurationLoading(
            propertyStatus: .failed
        ) { result in
            let result = try XCTUnwrap(result)
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertEqual(error as? AssetPropertyLoadingError, .unknown)
            }
        }
    }

    func test_loadProperty_assetPropertyStatusReturnsUnknown_completionWasCalledWithExpectedError() throws {
        try assertDurationLoading(
            propertyStatus: .unknown
        ) { result in
            let result = try XCTUnwrap(result)
            switch result {
            case .success:
                XCTFail()
            case let .failure(error):
                XCTAssertEqual(error as? AssetPropertyLoadingError, .unknown)
            }
        }
    }

    // MARK: - Private API

    private func assertDurationLoading(
        propertyStatus: AVKeyValueStatus,
        completion: (Result<TimeInterval, Error>?) throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        var completionWasCalledWithResult: Result<TimeInterval, Error>?
        mockAsset.statusOfValueResult = propertyStatus

        subject.loadProperty(
            .duration,
            of: mockAsset,
            onSuccessTransformer: { $0.duration.seconds },
            completion: { completionWasCalledWithResult = $0 }
        )

        XCTAssertEqual(
            mockAsset.statusOfValueWasCalledWithKey,
            "duration",
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockAsset.loadValuesAsynchronouslyWasCalledWithKeys,
            ["duration"],
            file: file,
            line: line
        )

        try completion(completionWasCalledWithResult)
    }
}

// MARK: - Private Helpers

extension StreamAssetPropertyLoader_Tests {
    private final class MockAVURLAsset: AVURLAsset {
        private(set) var statusOfValueWasCalledWithKey: String?
        var statusOfValueResult: AVKeyValueStatus?
        var statusOfValueError: NSError?

        private(set) var loadValuesAsynchronouslyWasCalledWithKeys: [String]?

        var stubbedDuration: CMTime = .zero

        override var duration: CMTime { stubbedDuration }

        override func statusOfValue(
            forKey key: String,
            error outError: NSErrorPointer
        ) -> AVKeyValueStatus {
            statusOfValueWasCalledWithKey = key
            outError?.pointee = statusOfValueError
            return statusOfValueResult!
        }

        override func loadValuesAsynchronously(
            forKeys keys: [String],
            completionHandler handler: (() -> Void)? = nil
        ) {
            loadValuesAsynchronouslyWasCalledWithKeys = keys
            handler?()
        }
    }
}
