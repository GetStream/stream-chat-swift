//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import StreamChatTestTools
@testable import StreamChatUI
import XCTest

final class NukeImageLoader_Tests: XCTestCase {
    private var requests: [ImageDownloadRequest]!
    private var imageLoader: MockNukeImageLoader!
    private var imagePipeline: MockPipeline!
    
    override func setUpWithError() throws {
        imagePipeline = MockPipeline()
        imageLoader = MockNukeImageLoader(mockPipeline: imagePipeline)
        requests = (0..<5)
            .compactMap { URL(string: "https://www.example.com/\($0)") }
            .map { ImageDownloadRequest(url: $0, options: .init()) }
    }
    
    override func tearDownWithError() throws {
        imageLoader = nil
        imagePipeline = nil
        requests = nil
    }

    func test_downloadMultipleImages_whenPipelineReturnsResultsInTheSameOrder_thenCompletionResultsAreInTheSameOrderAsPassedInRequests() throws {
        let expectation = XCTestExpectation()
        imageLoader.downloadMultipleImages(with: requests) { results in
            let ids = results.map(MockPipeline.pipelineLoadingCompletionIndex(for:))
            XCTAssertEqual(ids, [1, 2, 3, 4, 5])
            expectation.fulfill()
        }
        imagePipeline.dispatchPipelineCompletions(order: .same)
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    func test_downloadMultipleImages_whenPipelineReturnsResultsInReverseOrder_thenCompletionResultsAreInTheSameOrderAsPassedInRequests() throws {
        let expectation = XCTestExpectation()
        imageLoader.downloadMultipleImages(with: requests) { results in
            let ids = results.map(MockPipeline.pipelineLoadingCompletionIndex(for:))
            XCTAssertEqual(ids, [1, 2, 3, 4, 5])
            expectation.fulfill()
        }
        imagePipeline.dispatchPipelineCompletions(order: .reversed)
        wait(for: [expectation], timeout: defaultTimeout)
    }
    
    func test_downloadMultipleImages_whenPipelineReturnsResultsInShuffledOrder_thenCompletionResultsAreInTheSameOrderAsPassedInRequests() throws {
        let expectation = XCTestExpectation()
        imageLoader.downloadMultipleImages(with: requests) { results in
            let ids = results.map(MockPipeline.pipelineLoadingCompletionIndex(for:))
            XCTAssertEqual(ids, [1, 2, 3, 4, 5])
            expectation.fulfill()
        }
        imagePipeline.dispatchPipelineCompletions(order: .shuffled)
        wait(for: [expectation], timeout: defaultTimeout)
    }
}

extension NukeImageLoader_Tests {
    final class MockPipeline: NukeImagePipelineLoading {
        enum Order {
            case same, reversed, shuffled
        }
        
        private var counter: Int = 0
        private var scheduledRequests = [(loadOrderId: Int, request: ImageRequest, completion: (Result<UIImage, Error>) -> Void)]()
        
        func dispatchPipelineCompletions(order: Order) {
            let requests = {
                switch order {
                case .same: return scheduledRequests
                case .reversed: return scheduledRequests.reversed()
                case .shuffled:
                    let first = scheduledRequests.filter { !$0.loadOrderId.isMultiple(of: 2) }
                    let second = scheduledRequests.filter { $0.loadOrderId.isMultiple(of: 2) }
                    return first + second
                }
            }()
            for request in requests {
                request.completion(.success(Self.responseImage(for: request.loadOrderId)))
            }
        }
        
        static func responseImage(for loadOrderId: Int) -> UIImage {
            UIGraphicsImageRenderer(size: CGSize(width: loadOrderId, height: loadOrderId)).image { _ in }
        }
        
        static func pipelineLoadingCompletionIndex(for result: Result<UIImage, Error>) -> Int {
            guard let image = try? result.get() else { return -1 }
            return Int(image.size.width)
        }
        
        func loadImage(with request: ImageRequest, completion: @escaping (Result<UIImage, Swift.Error>) -> Void) -> ImageTask {
            counter += 1
            scheduledRequests.append((counter, request, completion))
            return ImageTask(taskId: Int64(counter), request: request, isDataTask: false)
        }
    }
    
    final class MockNukeImageLoader: NukeImageLoader {
        let mockPipeline: MockPipeline
        
        init(mockPipeline: MockPipeline) {
            self.mockPipeline = mockPipeline
        }
        
        override var imagePipeline: NukeImagePipelineLoading {
            mockPipeline
        }
    }
}
