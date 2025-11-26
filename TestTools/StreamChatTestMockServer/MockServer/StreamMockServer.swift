//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import XCTest

public final class StreamMockServer {
    public nonisolated(unsafe) static var url: String?
    public nonisolated(unsafe) static var port: String?
    private let urlSession: URLSession = URLSession.shared
    public static let jwtTimeout: UInt32 = 5
    public let udid = ProcessInfo.processInfo.environment["SIMULATOR_UDID"] ?? ""
    public let forbiddenWord: String = "wth"
    public let jwtTimeout: UInt32 = 5

    public init(driverPort: String, testName: String) {
        let driverUrl = "http://localhost:\(driverPort)"
        let response = getRequest(baseUrl: driverUrl, endpoint: "start/\(testName)")
        XCTAssertEqual(200, response.statusCode, "Failed connecting to mock server.")

        let mockServerPort = response.body
        StreamMockServer.port = mockServerPort
        StreamMockServer.url = driverUrl.replacingOccurrences(
            of: driverPort,
            with: mockServerPort
        )
    }

    public func stop() {
        getRequest(endpoint: "stop")
    }

    @discardableResult
    public func postRequest(
        baseUrl: String = url!,
        endpoint: String,
        body: Data = Data(),
        async: Bool = false
    ) -> (body: String, statusCode: Int) {
        let url = URL(string: "\(baseUrl)/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
        nonisolated(unsafe) var output = ""
        nonisolated(unsafe) var statusCode = 0

        if async {
            URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    output = string
                }
            }.resume()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    output = string
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }

        return (output, statusCode)
    }

    @discardableResult
    public func getRequest(
        baseUrl: String = url!,
        endpoint: String,
        async: Bool = false
    ) -> (body: String, statusCode: Int) {
        let url = URL(string: "\(baseUrl)/\(endpoint)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        nonisolated(unsafe) var output = ""
        nonisolated(unsafe) var statusCode = 0

        if async {
            URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    output = string
                }
            }.resume()
        } else {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: request) { data, response, _ in
                if let httpResponse = response as? HTTPURLResponse {
                    statusCode = httpResponse.statusCode
                }
                if let data = data, let string = String(data: data, encoding: .utf8) {
                    output = string
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }

        return (output, statusCode)
    }
}
