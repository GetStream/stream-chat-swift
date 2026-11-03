//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics
import Foundation
import ImageIO
@testable import StreamChatA2UI
import SwiftUI
import Testing

// The agent writes every message, so none of these can crash or freeze the app.
@MainActor
@Suite("Untrusted messages")
struct RobustnessTests {
    @Test("A formatString template from the data model that formats itself stops")
    func selfFormattingTemplate() throws {
        let template = "${formatString(value:${/t})}"
        let router = StubRemoteRouter()
        let (evaluator, model) = makeEvaluator(data: ["t": template], router: router)

        #expect(try evaluator.interpolate(template, in: DataContext(model, "/")) == "")
        #expect(router.errors.map(\.code) == [RendererError.Code.expressionError])
    }

    @Test("A component that lists itself as a child twice renders once and reports it")
    func selfContainingComponent() {
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": ["root", "root"]])
        ])

        _ = renderer.renderer.rootView(dataContext: DataContext(renderer.model, "/"))

        #expect(renderer.errors.count == 2)
        #expect(renderer.errors.allSatisfy { $0.code == RendererError.Code.recursionLimitExceeded })
        #expect(renderer.errors.first?.message == "Component 'root' contains itself: root > root.")
    }

    @Test("A tree whose shared children multiply past the limit isn't rendered")
    func multiplyingChildren() {
        // Each level lists the next one twice: 2^30 components from 31 definitions.
        let levels = (0..<30).map { level in
            Component(id: level == 0 ? "root" : "c\(level)", type: "Column", properties: ["children": ["c\(level + 1)", "c\(level + 1)"]])
        } + [Component(id: "c30", type: "Text", properties: ["text": "leaf"])]
        let renderer = makeRenderer(levels)

        #expect(renderer.renderer.expandedSize(limit: SurfaceRenderer.maxExpandedComponents) > SurfaceRenderer.maxExpandedComponents)
        _ = renderer.renderer.rootView(dataContext: DataContext(renderer.model, "/"))
        #expect(renderer.errors.map(\.code) == [RendererError.Code.recursionLimitExceeded])
    }

    @Test("An ordinary tree expands to its own size")
    func ordinaryTree() {
        let renderer = makeRenderer([
            Component(id: "root", type: "Column", properties: ["children": ["a", "b"]]),
            Component(id: "a", type: "Text", properties: ["text": "a"]),
            Component(id: "b", type: "Row", properties: ["children": ["c"]]),
            Component(id: "c", type: "Text", properties: ["text": "c"])
        ])

        #expect(renderer.renderer.expandedSize(limit: 100) == 4)
    }

    @Test("A slider's bounds and step are always ones SwiftUI takes")
    func sliderBounds() {
        #expect(A2UISliderView.range(minimum: nil, maximum: nil) == 0...1)
        #expect(A2UISliderView.range(minimum: 1e16, maximum: 0) == 1e15...(1e15 + 1))
        #expect(A2UISliderView.range(minimum: -.infinity, maximum: .nan) == 0...1)
        #expect(A2UISliderView.range(minimum: 5, maximum: 5) == 5...6)
        #expect(A2UISliderView.step(in: 0...10, steps: 5) == 2)
        #expect(A2UISliderView.step(in: 0...10, steps: 0) == nil)
        #expect(A2UISliderView.step(in: 1e15...(1e15 + 1), steps: 1) == 1)
    }

    @Test("A pattern that backtracks gives up instead of freezing the app")
    func backtrackingPattern() throws {
        let expression = try NSRegularExpression(pattern: "^(a+)+$")
        let started = ProcessInfo.processInfo.systemUptime

        #expect(ValidationFunctions.firstMatch(of: expression, in: String(repeating: "a", count: 40) + "b") == nil)
        #expect(ProcessInfo.processInfo.systemUptime - started < 2)
        #expect(ValidationFunctions.firstMatch(of: expression, in: "aaa") == true)
        #expect(ValidationFunctions.firstMatch(of: expression, in: "aab") == false)
    }

    @Test("A write can't nest deeper than the data model does, or pad its arrays without end")
    func dataModelLimits() throws {
        let model = DataModel()
        let deep = DataPath("/" + Array(repeating: "a", count: A2UIProtocol.maxNestingDepth + 1).joined(separator: "/"))

        #expect(throws: DataModelError.pathTooDeep(deep)) { try model.set(1, at: deep) }
        #expect(model.value(at: DataPath("/" + Array(repeating: "a", count: 50000).joined(separator: "/"))) == nil)
        #expect(throws: DataModelError.self) { try model.set(1, at: DataPath("/a/10000/10000")) }
        try model.set(1, at: DataPath("/b/3"))
        #expect(Json.array(model.value(at: DataPath("/b")))?.count == 4)
    }

    @Test("A number too large for an Int reads as no number")
    func largeNumbers() throws {
        let renderer = makeRenderer([Component(id: "root", type: "Text", properties: ["text": "x", "count": 1e19])])
        let context = renderer.context("root")

        #expect(context.int("count") == nil)
        #expect(context.int("text") == nil)
    }

    @Test("Image downloads stop at the limit, whether or not the server says the length")
    func imageDownloadLimit() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubImageProtocol.self]
        let session = URLSession(configuration: configuration)

        for path in ["declared", "undeclared"] {
            let url = try #require(URL(string: "https://example.com/\(path)"))
            await #expect(throws: URLError.self, "\(path)") {
                try await A2UIImageLoader.download(url, maxBytes: StubImageProtocol.body.count - 1, session: session)
            }
            let data = try await A2UIImageLoader.download(url, maxBytes: StubImageProtocol.body.count, session: session)
            #expect(data == StubImageProtocol.body)
        }
    }

    @Test("Large images are downsampled, and a URL downloads once for every view showing it")
    func imageLoading() async throws {
        let fetches = FetchCount()
        let png = try Self.png(width: 3000, height: 1500)
        let loader = A2UIImageLoader(maxPixelSize: 400) { _, _ in
            await fetches.add()
            return png
        }
        let url = try #require(URL(string: "https://example.com/a.png"))

        async let first = loader.image(for: url)
        async let second = loader.image(for: url)
        let images = await [first, second]

        let image = try #require(images[0])
        #expect(max(image.width, image.height) == 400)
        #expect(images[1] != nil)
        #expect(await fetches.count == 1)
        #expect(loader.cachedImage(for: url) != nil)
    }

    private static func png(width: Int, height: Int) throws -> Data {
        let context = try #require(CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ))
        context.setFillColor(CGColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let image = try #require(context.makeImage())
        let data = NSMutableData()
        let destination = try #require(CGImageDestinationCreateWithData(data, "public.png" as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, nil)
        #expect(CGImageDestinationFinalize(destination))
        return data as Data
    }

    // A renderer over the test catalog, which records the errors it reports.
    private func makeRenderer(_ components: [Component]) -> (renderer: SurfaceRenderer, model: DataModel, errors: ErrorLog, context: (String) -> ComponentRenderContext) {
        var definition = SurfaceDefinition(surfaceId: "surface", catalogId: TestCatalog.catalogId)
        definition.merge(components)
        let (evaluator, model) = makeEvaluator()
        let errors = ErrorLog()
        let renderer = SurfaceRenderer(
            definition: definition,
            catalogs: evaluator.catalogs,
            evaluator: evaluator,
            onAction: { _ in },
            onError: { errors.append($0) }
        )
        let context = { (id: String) in
            ComponentRenderContext(
                component: definition.component(id)!,
                definition: TestCatalog.make(recorder: RenderRecorder()).component(definition.component(id)!.type)!,
                surfaceId: "surface",
                dataContext: DataContext(model, "/"),
                evaluator: evaluator,
                renderer: renderer,
                ancestors: [id]
            )
        }
        return (renderer, model, errors, context)
    }
}

@MainActor
final class ErrorLog {
    private(set) var errors: [RendererError] = []

    var count: Int { errors.count }
    var first: RendererError? { errors.first }

    func append(_ error: RendererError) {
        errors.append(error)
    }

    func allSatisfy(_ predicate: (RendererError) -> Bool) -> Bool {
        errors.allSatisfy(predicate)
    }

    func map<T>(_ transform: (RendererError) -> T) -> [T] {
        errors.map(transform)
    }
}

private actor FetchCount {
    private(set) var count = 0

    func add() {
        count += 1
    }
}

// Serves the same body for every image, saying its length only for the path `/declared`.
private final class StubImageProtocol: URLProtocol {
    static let body = Data(repeating: 7, count: 1000)

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        var headers = ["Content-Type": "image/png"]
        if request.url?.path == "/declared" {
            headers["Content-Length"] = "\(Self.body.count)"
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }
}

@Suite("Theme")
struct ThemeTests {
    @Test("Heading levels past the theme's last font use the last one")
    func headings() {
        let theme = A2UITheme(headings: [.title, .headline])

        #expect(theme.heading(1) == .title)
        #expect(theme.heading(2) == .headline)
        #expect(theme.heading(6) == .headline)
        #expect(theme.heading(0) == .title)
        #expect(A2UITheme(headings: []).heading(1) == A2UITheme().body)
    }

    @Test("The default theme keeps the catalog's system look")
    func defaults() {
        let theme = A2UITheme()

        #expect(theme.accent == .accentColor)
        #expect(theme.body == .body)
        #expect(theme.buttonCornerRadius == 10)
        #expect(theme.controlCornerRadius == 8)
    }
}
