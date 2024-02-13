//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct LayoutSettings: Codable, Hashable {
    public var externalAppUrl: String
    public var externalCssUrl: String
    public var name: String
    public var options: [String: RawJSON]? = nil

    public init(externalAppUrl: String, externalCssUrl: String, name: String, options: [String: RawJSON]? = nil) {
        self.externalAppUrl = externalAppUrl
        self.externalCssUrl = externalCssUrl
        self.name = name
        self.options = options
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case externalAppUrl = "external_app_url"
        case externalCssUrl = "external_css_url"
        case name
        case options
    }
}
