//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

open class HttpServer: HttpServerIO, @unchecked Sendable {
    public static let VERSION: String = {
        #if os(Linux)
        return "1.5.0"
        #else
        let bundle = Bundle(for: HttpServer.self)
        guard let version = bundle.infoDictionary?["CFBundleShortVersionString"] as? String else { return "Unspecified" }
        return version
        #endif
    }()

    private let router = HttpRouter()

    override public init() {
        DELETE = MethodRoute(method: "DELETE", router: router)
        PATCH = MethodRoute(method: "PATCH", router: router)
        HEAD = MethodRoute(method: "HEAD", router: router)
        POST = MethodRoute(method: "POST", router: router)
        GET = MethodRoute(method: "GET", router: router)
        PUT = MethodRoute(method: "PUT", router: router)

        delete = MethodRoute(method: "DELETE", router: router)
        patch = MethodRoute(method: "PATCH", router: router)
        head = MethodRoute(method: "HEAD", router: router)
        post = MethodRoute(method: "POST", router: router)
        get = MethodRoute(method: "GET", router: router)
        put = MethodRoute(method: "PUT", router: router)
    }

    public var DELETE, PATCH, HEAD, POST, GET, PUT: MethodRoute
    public var delete, patch, head, post, get, put: MethodRoute

    public subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
        get { nil }
        set {
            router.register(nil, path: path, handler: newValue)
        }
    }

    public var routes: [String] {
        router.routes()
    }

    public var notFoundHandler: ((HttpRequest) -> HttpResponse)?

    public var middleware = [(HttpRequest) -> HttpResponse?]()

    override open func dispatch(_ request: HttpRequest) -> ([String: String], (HttpRequest) -> HttpResponse) {
        for layer in middleware {
            if let response = layer(request) {
                return ([:], { _ in response })
            }
        }
        if let result = router.route(request.method, path: request.path) {
            return result
        }
        if let notFoundHandler = self.notFoundHandler {
            return ([:], notFoundHandler)
        }
        return super.dispatch(request)
    }

    public struct MethodRoute {
        public let method: String
        public let router: HttpRouter
        public subscript(path: String) -> ((HttpRequest) -> HttpResponse)? {
            get { nil }
            set {
                router.register(method, path: path, handler: newValue)
            }
        }
    }
}
