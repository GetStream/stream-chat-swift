//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import XCTest

class SystemEnvironment_Tests: XCTestCase {
    #if os(iOS)
    func test_getUserAgentForIphoneDevice_returnsCorrectValue() {
        // Given
        guard let info = Bundle.main.infoDictionary else {
            return XCTFail("There should be an info dictionary")
        }
        
        let appName = ((info["CFBundleDisplayName"] ?? info[kCFBundleIdentifierKey as String]) as? String) ?? "App name unavailable"
        let appVersion = (info["CFBundleShortVersionString"] as? String) ?? "0"
        let model = SystemEnvironment.deviceModelName
        let os = "iOS"
        let osVersion = UIDevice.current.systemVersion
        let scale = String(format: "%0.2f", UIScreen.main.scale)
        let expectedUserAgent = "\(appName)/\(appVersion) (\(model); \(os) \(osVersion)" +
            (!scale.isEmpty ? "; Scale/\(scale)" : scale) + ")"
        
        // When
        let userAgent = SystemEnvironment.userAgent
        
        // Then
        XCTAssertEqual(userAgent, expectedUserAgent)
    }
    
    #elseif os(macOS)
    func test_getUserAgentForMacDevice_returnsCorrectValue() {
        // Given
        guard let info = Bundle.main.infoDictionary else {
            return XCTFail("There should be an info dictionary")
        }
        
        let appName = ((info["CFBundleDisplayName"] ?? info[kCFBundleIdentifierKey as String]) as? String) ?? "App name unavailable"
        let appVersion = (info["CFBundleShortVersionString"] as? String) ?? "0"
        let model = SystemEnvironment.getMacModelIdentifier()
        let os = "MacOS"
        let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
        let scale = "1.00"
        let expectedUserAgent = "\(appName)/\(appVersion) (\(model); \(os) \(osVersion); Scale/\(scale))"
        
        // When
        let userAgent = SystemEnvironment.userAgent
        
        // Then
        XCTAssertEqual(userAgent, expectedUserAgent)
    }
    #endif
}
