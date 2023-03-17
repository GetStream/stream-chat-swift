//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamChat
import XCTest

final class StreamAssetPropertyLoader_Tests: XCTestCase {
    private lazy var subject: StreamAssetPropertyLoader! = .init()
    private lazy var mockAsset: MockAVURLAsset! = .init(url: .init(string: "http://getstream.io")!)

    override func tearDownWithError() throws {
        mockAsset = nil
        subject = nil
        try super.tearDownWithError()
    }

    // MARK: - loadProperties

    // MARK: single property

    func test_loadProperties_assetPropertyStatusReturnsAsLoading_completionWasCalledWithoutErrors() throws {
        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .loading],
            completion: { completion in
                switch completion {
                case let .success(asset):
                    XCTAssertEqual(mockAsset, asset)
                case .failure:
                    XCTFail()
                }
            }
        )
    }

    func test_loadProperties_assetPropertyStatusReturnsAsLoaded_completionWasCalledWithoutErrors() throws {
        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .loaded],
            completion: { completion in
                switch completion {
                case let .success(asset):
                    XCTAssertEqual(mockAsset, asset)
                case .failure:
                    XCTFail()
                }
            }
        )
    }

    func test_loadProperties_assetPropertyStatusReturnsAsCancelled_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .cancelled],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.cancelledProperties.first?.property.name, "duration")
                }
            }
        )
    }

    func test_loadProperties_assetPropertyStatusReturnsFailedWithError_completionWasCalledWithExpectedError() throws {
        let expectedError = NSError(domain: "test", code: 100)
        mockAsset.statusOfValueErrorMap["duration"] = expectedError

        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .failed],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.first?.property.name, "duration")
                    XCTAssertEqual((compositeError.failedProperties.first)?.error as? NSError, expectedError)
                }
            }
        )
    }

    func test_loadProperties_assetPropertyStatusReturnsFailedWithoutError_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .failed],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.first?.property.name, "duration")
                }
            }
        )
    }

    func test_loadProperties_assetPropertyStatusReturnsUnknown_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration)],
            resultMap: ["duration": .unknown],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.first?.property.name, "duration")
                }
            }
        )
    }

    // MARK: multiple properties

    func test_loadProperties_multipleProperties_allPropertiesFailed_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration), .init(\.isReadable), .init(\.isPlayable)],
            resultMap: [
                "duration": .failed,
                "readable": .failed,
                "playable": .failed
            ],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.count, 3)
                    XCTAssertEqual(compositeError.failedProperties.map(\.property.name), ["duration", "readable", "playable"])
                }
            }
        )
    }

    func test_loadProperties_multipleProperties_somePropertiesFailedAndSomeCancelled_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration), .init(\.isReadable), .init(\.isPlayable)],
            resultMap: [
                "duration": .loaded,
                "readable": .cancelled,
                "playable": .failed
            ],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.count, 1)
                    XCTAssertEqual(compositeError.cancelledProperties.count, 1)
                    XCTAssertEqual(compositeError.failedProperties.map(\.property.name), ["playable"])
                    XCTAssertEqual(compositeError.cancelledProperties.map(\.property.name), ["readable"])
                }
            }
        )
    }

    func test_loadProperties_multipleProperties_somePropertiesFailed_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration), .init(\.isReadable), .init(\.isPlayable)],
            resultMap: [
                "duration": .loaded,
                "readable": .failed,
                "playable": .failed
            ],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.failedProperties.count, 2)
                    XCTAssertEqual(compositeError.failedProperties.map(\.property.name), ["readable", "playable"])
                }
            }
        )
    }

    func test_loadProperties_multipleProperties_somePropertiesCancelled_completionWasCalledWithExpectedError() throws {
        try assertPropertiesLoading(
            [.init(\.duration), .init(\.isReadable), .init(\.isPlayable)],
            resultMap: [
                "duration": .loaded,
                "readable": .cancelled,
                "playable": .cancelled
            ],
            completion: { completion in
                switch completion {
                case .success:
                    XCTFail()
                case let .failure(error):
                    let compositeError = try XCTUnwrap(error as? AssetPropertyLoadingCompositeError)
                    XCTAssertEqual(compositeError.cancelledProperties.count, 2)
                    XCTAssertEqual(compositeError.cancelledProperties.map(\.property.name), ["readable", "playable"])
                }
            }
        )
    }

    func test_loadProperties_multipleProperties_allPropertiesSucceed_completionWasCalledWithoutError() throws {
        try assertPropertiesLoading(
            [.init(\.duration), .init(\.isReadable), .init(\.isPlayable)],
            resultMap: [
                "duration": .loaded,
                "readable": .loaded,
                "playable": .loaded
            ],
            completion: { completion in
                switch completion {
                case let .success(asset):
                    XCTAssertEqual(mockAsset, asset)
                case .failure:
                    XCTFail()
                }
            }
        )
    }

    // MARK: - Private API

    private func assertPropertiesLoading(
        _ properties: [AssetProperty],
        resultMap statusOfValueResultMap: [String: AVKeyValueStatus],
        completion: (Result<AVURLAsset, Error>) throws -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        var completionWasCalledWithResult: Result<AVURLAsset, Error>?
        mockAsset.statusOfValueResultMap = statusOfValueResultMap

        subject.loadProperties(
            properties,
            of: mockAsset,
            completion: { completionWasCalledWithResult = $0 }
        )

        XCTAssertEqual(
            mockAsset.recordedFunctions,
            properties.map { "statusOfValue(\($0.name))" },
            file: file,
            line: line
        )
        XCTAssertEqual(
            mockAsset.loadValuesAsynchronouslyWasCalledWithKeys,
            properties.map(\.name),
            file: file,
            line: line
        )

        try completion(completionWasCalledWithResult!)
    }
}

// MARK: - Private Helpers

extension StreamAssetPropertyLoader_Tests {
    private final class MockAVURLAsset: AVURLAsset, Spy {
        var recordedFunctions: [String] = []

        var statusOfValueResultMap: [String: AVKeyValueStatus] = [:]
        var statusOfValueErrorMap: [String: Error] = [:]

        private(set) var loadValuesAsynchronouslyWasCalledWithKeys: [String]?

        override func statusOfValue(
            forKey key: String,
            error outError: NSErrorPointer
        ) -> AVKeyValueStatus {
            recordedFunctions.append("statusOfValue(\(key))")
            outError?.pointee = statusOfValueErrorMap[key] as? NSError
            return statusOfValueResultMap[key]!
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
