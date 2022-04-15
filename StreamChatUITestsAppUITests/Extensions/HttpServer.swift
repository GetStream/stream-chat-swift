//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Swifter

extension HttpServer {
    func register(_ path: String, execution: @escaping ((HttpRequest) throws -> HttpResponse?))  {
        self[path] = {
            do {
                return try execution($0) ?? .badRequest(nil)
            } catch {
                return .badRequest(nil)
            }
        }
    }
}
