//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing
@MainActor
@Suite("Component envelope and malformed components")
struct ComponentEnvelopeTests {
    @Test("The spec's @ envelope keys are read, ahead of the unprefixed ones")
    func prefixedEnvelopeKeys() throws {
        let component = try #require(Component.fromJson([
            "id": "email",
            "component": "TextField",
            "@checks": [["condition": true, "message": "x"] as JsonMap] as JsonArray,
            "@accessibility": ["label": "Work email"] as JsonMap,
            "@catalogId": "other",
            "catalogId": "ignored",
            "@metadata": ["extensions": [:] as JsonMap] as JsonMap
        ]))

        #expect(component.checks.count == 1)
        #expect(component.catalogId == "other")
        #expect(component.accessibility?.label.rawValue as? String == "Work email")
        #expect(component.metadata != nil)
        #expect(component.properties.keys.allSatisfy { !$0.hasPrefix("@") && $0 != "catalogId" })
    }

    @Test("A component without an id or type is reported, and errors point at the entry in the message")
    func malformedComponents() throws {
        let harness = ProcessorHarness()
        let message = try decodeMessage("""
        {"version": "1.0", "createSurface": {"surfaceId": "main", "catalogId": "\(TestCatalog.catalogId)", "components": [
            {"id": "title", "type": "Text"},
            "nope",
            {"id": "b", "component": "Buton"}
        ]}}
        """)
        harness.processor.handle(message)

        #expect(harness.errors.map(\.path) == ["/components/0/component", "/components/1", "/components/2/component"])
        #expect(harness.errors.allSatisfy { $0.code == RendererError.Code.validationFailed })
    }
}
