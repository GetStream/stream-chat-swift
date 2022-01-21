//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class RequestDecoder_Tests: XCTestCase {
    var decoder: RequestDecoder!
    
    override func setUp() {
        super.setUp()
        decoder = DefaultRequestDecoder()
    }
    
    func test_decodingSuccessfullResponse() throws {
        // Prepare test data simulating successful response
        let response = HTTPURLResponse(url: .unique(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let testUser = TestUser(name: "Luke", age: 22)
        let data = try JSONEncoder.stream.encode(testUser)
        
        // Decode it and check the results is `testUser`
        let decoded: TestUser = try decoder.decodeRequestResponse(data: data, response: response, error: nil)
        XCTAssertEqual(decoded, testUser)
    }
    
    func test_decodingResponseWithError() {
        let testError = TestError()
        
        // Check decoding with an incoming error "throws" the same error
        XCTAssertThrowsError(try {
            let _: Data = try self.decoder.decodeRequestResponse(data: nil, response: nil, error: testError)
        }()) { (error) in
            XCTAssertEqual(error as? TestError, testError)
        }
    }
    
    func test_decodingResponseWithServerError() throws {
        // Prepare test data to simulate error payload from the server
        let errorPayload = ErrorPayload(code: 0, message: "Test", statusCode: 400)
        let data = try JSONEncoder.stream.encode(errorPayload)
        let response = HTTPURLResponse(url: .unique(), statusCode: 400, httpVersion: nil, headerFields: nil)
        
        // Decode and check the thrown error is created from the server error payload
        XCTAssertThrowsError(try {
            let _: Data = try self.decoder.decodeRequestResponse(data: data, response: response, error: nil)
        }()) { (error) in
            XCTAssert((error as? ClientError)?.underlyingError is ErrorPayload)
        }
    }
    
    func test_decodingResponseWithServerError_containingExpiredToken() throws {
        // Prepare test data to simulate the "token expired" server error
        let errorPayload = ErrorPayload(code: 40, message: "Test", statusCode: 400)
        let data = try JSONEncoder.stream.encode(errorPayload)
        let response = HTTPURLResponse(url: .unique(), statusCode: 400, httpVersion: nil, headerFields: nil)
        
        // Decode and check the error type is correct
        XCTAssertThrowsError(try {
            let _: Data = try self.decoder.decodeRequestResponse(data: data, response: response, error: nil)
        }()) { (error) in
            XCTAssert(error is ClientError.ExpiredToken)
        }
    }

    func test_decodingDateThreadSafe() throws {
        struct TestModel: Decodable {
            let date: Date
        }

        let json = "{\"date\": \"2021-05-13T22:10:31.960878Z\"}"

        DispatchQueue.concurrentPerform(iterations: 1000) { _ in
            if let data = json.data(using: .utf8) {
                do {
                    _ = try JSONDecoder.stream.decode(TestModel.self, from: data)
                } catch {
                    XCTFail("\(error)")
                }
            }
        }
    }
}

private struct TestUser: Codable, Equatable {
    let name: String
    let age: Int
}
