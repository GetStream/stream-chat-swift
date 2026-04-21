//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class IndividualRecordingSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    var mode: String
    var outputTypes: [String]?

    init(mode: String, outputTypes: [String]? = nil) {
        self.mode = mode
        self.outputTypes = outputTypes
    }

    enum CodingKeys: String, CodingKey, CaseIterable {
        case mode
        case outputTypes = "output_types"
    }

    static func == (lhs: IndividualRecordingSettingsResponse, rhs: IndividualRecordingSettingsResponse) -> Bool {
        lhs.mode == rhs.mode &&
            lhs.outputTypes == rhs.outputTypes
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(mode)
        hasher.combine(outputTypes)
    }
}
