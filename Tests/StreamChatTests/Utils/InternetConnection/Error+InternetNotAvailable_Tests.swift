//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

final class Error_Tests: XCTestCase {
    func test_errorIsNSURLErrorNotConnectedToInternet() throws {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: nil
        )
        
        XCTAssertTrue(error.isInternetOfflineError)
    }
    
    func test_errorIsNSPOSIXErrorDomain50() throws {
        let error = NSError(
            domain: NSPOSIXErrorDomain,
            code: 50,
            userInfo: nil
        )
        
        XCTAssertTrue(error.isInternetOfflineError)
    }
    
    func test_errorDomainIsNotOneOfInternetOfflineError() throws {
        let error = NSError(
            domain: "Some domain",
            code: 50,
            userInfo: nil
        )
        
        XCTAssertFalse(error.isInternetOfflineError)
    }
    
    func test_errorCodeIsNotOneOfInternetOfflineError() throws {
        let error = NSError(
            domain: NSURLErrorDomain,
            code: 50,
            userInfo: nil
        )
        
        XCTAssertFalse(error.isInternetOfflineError)
    }
    
    func test_websocketEngineErrorInternetIsOffline() throws {
        let error = WebSocketEngineError(
            reason: "",
            code: -1009,
            engineError: NSError(
                domain: NSURLErrorDomain,
                code: NSURLErrorNotConnectedToInternet,
                userInfo: nil
            )
        )
        
        XCTAssertTrue(error.isInternetOfflineError)
    }
    
    func test_websocketEngineErrorDomainIsNotInternetIsOffline() throws {
        let error = WebSocketEngineError(
            reason: "",
            code: 304,
            engineError: NSError(
                domain: "Some domain",
                code: NSURLErrorNotConnectedToInternet,
                userInfo: nil
            )
        )
        
        XCTAssertFalse(error.isInternetOfflineError)
    }
    
    func test_websocketEngineErrorCodeIsNotInternetIsOffline() throws {
        let error = WebSocketEngineError(
            reason: "",
            code: 304,
            engineError: NSError(
                domain: NSURLErrorDomain,
                code: 304,
                userInfo: nil
            )
        )
        
        XCTAssertFalse(error.isInternetOfflineError)
    }
    
    func test_isBackendErrorWith400StatusCode_errorIsNotClientError() {
        let error = WebSocketEngineError(error: nil)
        XCTAssertFalse(error.isBackendErrorWith400StatusCode)
    }
    
    func test_isBackendErrorWith400StatusCode_errorIsClientError() {
        // When error is a ClientError, but it doesn't have unerdlying backend error
        let error = ClientError(with: nil)
        XCTAssertFalse(error.isBackendErrorWith400StatusCode)
    }
    
    func test_isBackendErrorWith400StatusCode_errorIsClientErrorWithErrorPayload() {
        // When error is a ClientError, it's unerdlying error is a backend error,
        // but it's status code is not 400
        let error = ClientError(with: ErrorPayload(code: 0, message: "", statusCode: 503))
        XCTAssertFalse(error.isBackendErrorWith400StatusCode)
    }
    
    func test_isBackendErrorWith400StatusCode() {
        let error = ClientError(with: ErrorPayload(code: 0, message: "", statusCode: 400))
        XCTAssertTrue(error.isBackendErrorWith400StatusCode)
    }
}
