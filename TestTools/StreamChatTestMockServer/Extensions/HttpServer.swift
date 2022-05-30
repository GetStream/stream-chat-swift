//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Swifter
import Foundation

public extension HttpServer {
    func register(_ path: String, execution: @escaping ((HttpRequest) throws -> HttpResponse?))  {
        self[path] = { [weak self] in
            self?.delayServerResponseIfNeeded()

            do {
                return try execution($0) ?? .badRequest(nil)
            } catch {
                return .badRequest(nil)
            }
        }
    }

    private func delayServerResponseIfNeeded() {
        let delay = StreamMockServer.httpResponseDelay
        if delay > 0.0 {
            Thread.sleep(forTimeInterval: delay)
        }
    }
}
