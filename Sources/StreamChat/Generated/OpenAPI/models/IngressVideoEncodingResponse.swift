//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IngressVideoEncodingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var layers: [IngressVideoLayerResponse]
    var source: IngressSourceResponse

    init(layers: [IngressVideoLayerResponse], source: IngressSourceResponse) {
        self.layers = layers
        self.source = source
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case layers
        case source
    }

    static func == (lhs: IngressVideoEncodingResponse, rhs: IngressVideoEncodingResponse) -> Bool {
        lhs.layers == rhs.layers &&
            lhs.source == rhs.source
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(layers)
        hasher.combine(source)
    }
}
