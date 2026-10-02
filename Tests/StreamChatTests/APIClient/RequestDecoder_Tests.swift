//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
@testable import StreamChatTestTools
import StreamCore
import XCTest

final class RequestDecoder_Tests: XCTestCase {
    var decoder: RequestDecoder!

    override func setUp() {
        super.setUp()
        decoder = DefaultRequestDecoder()
    }

    override func tearDown() {
        decoder = nil
        super.tearDown()
    }

    func test_decodingSuccessfullResponse() throws {
        // Prepare test data simulating successful response
        let response = HTTPURLResponse(url: .unique(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let testUser = TestUser(name: "Luke", age: 22)
        let data = try JSONEncoder.stream.encode(testUser)

        // Decode it and check the results is `testUser`
        let decoded: TestUser = try decode(data: data, response: response, error: nil)
        XCTAssertEqual(decoded, testUser)
    }

    func test_decodingSuccessfullResponse_responseTypeData() throws {
        // Prepare test data simulating successful response
        let response = HTTPURLResponse(url: .unique(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let testUser = TestUser(name: "Luke", age: 22)
        let data = try JSONEncoder.stream.encode(testUser)

        // Decode it and check the results is `testUser`
        let decoded: Data = try decode(data: data, response: response, error: nil)
        XCTAssertEqual(decoded, data)
    }

    func test_decodingResponseWithError() {
        let testError = TestError()

        // Check decoding with an incoming error "throws" the same error
        XCTAssertThrowsError(try {
            let _: Data = try self.decode(data: nil, response: nil, error: testError)
        }()) { (error) in
            XCTAssertEqual(error as? TestError, testError)
        }
    }

    func test_decodingResponseWithServerError() throws {
        // Prepare test data to simulate error payload from the server
        let errorPayload = APIError(code: 0, message: "Test", statusCode: 400)
        let data = try JSONEncoder.stream.encode(errorPayload)
        let response = HTTPURLResponse(url: .unique(), statusCode: 400, httpVersion: nil, headerFields: nil)

        // Decode and check the thrown error is created from the server error payload
        XCTAssertThrowsError(try {
            let _: Data = try self.decode(data: data, response: response, error: nil)
        }()) { (error) in
            XCTAssertNotNil((error as? ClientError)?.apiError)
        }
    }

    func test_decodingResponseWithServerError_containingExpiredToken() throws {
        // Prepare test data to simulate the "token expired" server error
        let errorPayload = APIError(code: 40, message: "Test", statusCode: 400)
        let data = try JSONEncoder.stream.encode(errorPayload)
        let response = HTTPURLResponse(url: .unique(), statusCode: 400, httpVersion: nil, headerFields: nil)

        // Decode and check the error type is correct
        XCTAssertThrowsError(try {
            let _: Data = try self.decode(data: data, response: response, error: nil)
        }()) { (error) in
            XCTAssert(error is ClientError.ExpiredToken)
        }
    }

    func test_decodingDateThreadSafe() throws {
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

    func test_logMessage_containsStatusResponseAndRequest() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/channels/query")))
        request.httpMethod = "POST"
        let data = Data(#"{"duration":"1ms"}"#.utf8)

        let message = request.logMessage(for: .shared, status: "201", responseData: data)

        XCTAssertEqual(
            message,
            """
            201 POST /channels/query

            Response:
            \(data.debugPrettyPrintedJSON)

            Request:
            \(request.cURLRepresentation(for: .shared))
            """
        )
    }

    func test_logMessage_withError_withoutResponse() throws {
        let request = URLRequest(url: try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/channels")))
        let error = TestError()

        let message = request.logMessage(for: .shared, status: "FAILED", error: error)

        XCTAssertEqual(
            message,
            """
            FAILED GET /channels

            Error:
            \(error)

            Request:
            \(request.cURLRepresentation(for: .shared))
            """
        )
    }

    private func decode<ResponseType: Decodable>(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) throws -> ResponseType {
        try decoder.decodeRequestResponse(
            request: URLRequest(url: .unique()),
            session: .shared,
            data: data,
            response: response,
            error: error
        )
    }
}

private struct TestModel: Decodable {
    let date: Date
}
