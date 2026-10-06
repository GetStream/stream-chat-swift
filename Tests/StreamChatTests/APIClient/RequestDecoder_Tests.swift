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

    func test_decodingEmptyResponse_redirectStatus_logsDebug() throws {
        let levels = try loggedLevels(forEmptyResponseWithStatusCode: 304)

        XCTAssertEqual(levels, [.debug])
    }

    func test_decodingEmptyResponse_serverErrorStatus_logsError() throws {
        let levels = try loggedLevels(forEmptyResponseWithStatusCode: 500)

        XCTAssertEqual(levels, [.error])
    }

    func test_decodingInvalidPayload_logsErrorWithHTTPAttachment() throws {
        let response = HTTPURLResponse(url: .unique(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let data = Data(#"{"name": 1}"#.utf8)
        var thrownError: Error?

        let details = try capturedLogDetails(count: 2) {
            XCTAssertThrowsError(try {
                let _: TestUser = try self.decode(data: data, response: response, error: nil)
            }()) { thrownError = $0 }
        }

        XCTAssert(thrownError is DecodingError)
        XCTAssertEqual(details.map(\.level), [.debug, .error])
        let attachment = try XCTUnwrap(details.last?.attachment as? HTTPLogAttachment)
        XCTAssertEqual(attachment.response as? HTTPURLResponse, response)
        XCTAssertEqual(attachment.responseBody, data)
        XCTAssert(attachment.error is DecodingError)
        XCTAssertNotNil(attachment.session)
    }

    private func loggedLevels(forEmptyResponseWithStatusCode statusCode: Int) throws -> [LogLevel] {
        let response = HTTPURLResponse(url: .unique(), statusCode: statusCode, httpVersion: nil, headerFields: nil)
        return try capturedLogDetails(count: 1) {
            XCTAssertThrowsError(try {
                let _: Data = try self.decode(data: nil, response: response, error: nil)
            }()) { error in
                XCTAssert(error is ClientError.ResponseBodyEmpty)
            }
        }.map(\.level)
    }

    private func capturedLogDetails(count: Int, during action: () throws -> Void) rethrows -> [LogDetails] {
        let logged = expectation(description: "logged")
        logged.expectedFulfillmentCount = count
        let destination = CapturingLogDestination { logged.fulfill() }
        let previousDestinations = LogConfig.destinations
        LogConfig.destinations = [destination]
        defer { LogConfig.destinations = previousDestinations }

        try action()
        wait(for: [logged], timeout: defaultTimeout)
        return destination.details
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

private final class CapturingLogDestination: BaseLogDestination, @unchecked Sendable {
    private let lock = NSLock()
    private var capturedDetails: [LogDetails] = []
    private var onProcess: @Sendable () -> Void = {}

    var details: [LogDetails] {
        lock.lock()
        defer { lock.unlock() }
        return capturedDetails
    }

    convenience init(onProcess: @escaping @Sendable () -> Void) {
        self.init(
            identifier: UUID().uuidString,
            level: .debug,
            subsystems: .all,
            showDate: false,
            dateFormatter: DateFormatter(),
            formatters: [],
            showLevel: false,
            showIdentifier: false,
            showThreadName: false,
            showFileName: false,
            showLineNumber: false,
            showFunctionName: false
        )
        self.onProcess = onProcess
    }

    override func process(logDetails: LogDetails) {
        lock.lock()
        capturedDetails.append(logDetails)
        lock.unlock()
        onProcess()
    }
}
