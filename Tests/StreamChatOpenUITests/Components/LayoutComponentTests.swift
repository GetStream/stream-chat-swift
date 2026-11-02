//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("Layout components")
struct LayoutComponentTests {
    @Test func justifySpreadsItemsAndKeepsTheGap() {
        let widths: [CGFloat] = [50, 50, 50]

        #expect(JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "start") == [0, 60, 120])
        #expect(JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "center") == [65, 125, 185])
        #expect(JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "end") == [130, 190, 250])
        #expect(JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "between") == [0, 125, 250])
        #expect(JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "evenly") == [32.5, 125, 217.5])

        let around = JustifiedRowLayout.offsets(widths: widths, available: 300, gap: 10, justify: "around")
        let edge = 130.0 / 6
        #expect(abs(around[0] - edge) < 0.001)
        #expect(abs(300 - (around[2] + 50) - edge) < 0.001)
        #expect(abs((around[1] - around[0] - 50) - (10 + 2 * edge)) < 0.001)
    }

    @Test func justifyHandlesOneItemAndOverflow() {
        #expect(JustifiedRowLayout.offsets(widths: [50], available: 300, gap: 10, justify: "between") == [0])
        #expect(JustifiedRowLayout.offsets(widths: [200, 200], available: 300, gap: 10, justify: "evenly") == [0, 210])
        #expect(JustifiedRowLayout.offsets(widths: [], available: 300, gap: 10, justify: "around").isEmpty)
    }

    @Test func justifiedRowPlacesItsItems() async {
        let frames = FrameRecorder()
        let row = JustifiedRowLayout(justify: "between", gap: 10).callAsFunction {
            ForEach(0..<3, id: \.self) { index in
                Color.red
                    .frame(width: 50, height: 20)
                    .overlay {
                        GeometryReader { proxy in
                            Color.clear.onAppear { frames.values[index] = proxy.frame(in: .named("row")) }
                        }
                    }
            }
        }
        .frame(width: 300)
        .coordinateSpace(.named("row"))
        let host = HostedView(row)
        defer { host.close() }
        await host.settle()

        #expect(frames.values[0]?.minX == 0)
        #expect(frames.values[1]?.minX == 125)
        #expect(frames.values[2]?.maxX == 300)
    }

    @Test(arguments: ["between", "around", "evenly"])
    func stackRowRendersEachJustify(_ justify: String) {
        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: """
        root = Stack([row])
        row = Stack([TextContent("One"), TextContent("Two"), TextContent("Three")], "row", "m", "center", "\(justify)")
        """, isStreaming: false)

        #expect(RenderingTests.render(runtime) != nil)
    }

    @Test func modalWithoutABindingClosesOnItsOwn() throws {
        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: """
        root = Stack([info, help])
        info = Modal("Info", true, [TextContent("Hi")])
        help = Modal("Help", true, [TextContent("Help")])
        """, isStreaming: false)
        let children = runtime.root?.props["children"]?.arrayValue ?? []
        let modals = children.compactMap(\.elementValue)
        try #require(modals.count == 2)
        let info = runtime.stateField(name: "open", binding: modals[0].props["open"], formName: nil)
        let help = runtime.stateField(name: "open", binding: modals[1].props["open"], formName: nil)
        var infoPresentation = ModalPresentation()
        let helpPresentation = ModalPresentation()

        #expect(infoPresentation.isOpen(field: info, open: modals[0].props["open"]))
        infoPresentation.close(field: info)

        #expect(!infoPresentation.isOpen(field: info, open: modals[0].props["open"]))
        #expect(helpPresentation.isOpen(field: help, open: modals[1].props["open"]))
        #expect(runtime.store.snapshot.isEmpty)
    }

    @Test func modalWithABindingClosesThroughIt() throws {
        let runtime = OpenUIRuntime(library: .openUI)
        runtime.update(response: """
        $show = true
        root = Stack([info])
        info = Modal("Info", $show, [TextContent("Hi")])
        """, isStreaming: false)
        let modal = try #require(runtime.root?.props["children"]?.arrayValue?.first?.elementValue)
        var presentation = ModalPresentation()

        #expect(presentation.isOpen(field: runtime.stateField(name: "open", binding: modal.props["open"], formName: nil), open: modal.props["open"]))
        presentation.close(field: runtime.stateField(name: "open", binding: modal.props["open"], formName: nil))

        #expect(runtime.store.get("$show") == .bool(false))
        #expect(!presentation.isOpen(field: runtime.stateField(name: "open", binding: modal.props["open"], formName: nil), open: modal.props["open"]))
    }

    @Test func streamingSizeGrowsWithTheContent() {
        let short: OpenUIValue = ["a", ["text": "Hello"]]
        let longer: OpenUIValue = ["a", ["text": "Hello, world"], 3]

        #expect(longer.streamingSize > short.streamingSize)
        #expect(OpenUIValue.null.streamingSize == 0)
    }
}

@MainActor
final class FrameRecorder {
    var values: [Int: CGRect] = [:]
}
