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

    func test_logMessage_containsStatusMethodAndPath() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/channels/query?api_key=key")))
        request.httpMethod = "POST"

        XCTAssertEqual(request.logMessage(status: "201"), "201 POST /channels/query")
    }

    func test_logMetadata_containsRequestAndPrettyPrintedJSONBodies() throws {
        let url = try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/channels/query?api_key=key"))
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = Data(#"{"limit":10}"#.utf8)

        let metadata = request.logMetadata(for: .shared, statusCode: 201, responseData: Data(#"{"url":"https://a.b/c"}"#.utf8))

        XCTAssertEqual(metadata, [
            .httpMethod: "POST",
            .httpURL: url.absoluteString,
            .httpStatusCode: "201",
            .httpRequestBody: "{\n  \"limit\" : 10\n}",
            .httpResponseBody: "{\n  \"url\" : \"https://a.b/c\"\n}",
            .httpCURL: request.cURLRepresentation(for: .shared)
        ])
    }

    func test_logMetadata_withError_withoutResponse() throws {
        let request = URLRequest(url: try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/channels")))
        let error = TestError()

        let metadata = request.logMetadata(for: .shared, error: error)

        XCTAssertEqual(metadata[.httpMethod], "GET")
        XCTAssertEqual(metadata[.httpError], "\(error)")
        XCTAssertNil(metadata[.httpStatusCode])
        XCTAssertNil(metadata[.httpResponseBody])
    }

    func test_logMetadata_keepsTextBodiesAndSkipsBinaryBodies() throws {
        var request = URLRequest(url: try XCTUnwrap(URL(string: "https://chat.stream-io-api.com/uploads")))
        request.httpBody = Data([0xff, 0xd8, 0xff, 0xe0])

        let metadata = request.logMetadata(for: .shared, statusCode: 500, responseData: Data("<html>Error</html>".utf8))

        XCTAssertNil(metadata[.httpRequestBody])
        XCTAssertEqual(metadata[.httpResponseBody], "<html>Error</html>")
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
