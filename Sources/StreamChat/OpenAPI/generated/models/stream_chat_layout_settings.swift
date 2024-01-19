//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct StreamChatLayoutSettings: Codable, Hashable {
    public var name: String
    
    public var options: [String: RawJSON]?
    
    public var externalAppUrl: String
    
    public var externalCssUrl: String
    
    public init(name: String, options: [String: RawJSON]?, externalAppUrl: String, externalCssUrl: String) {
        self.name = name
        
        self.options = options
        
        self.externalAppUrl = externalAppUrl
        
        self.externalCssUrl = externalCssUrl
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case name
        
        case options
        
        case externalAppUrl = "external_app_url"
        
        case externalCssUrl = "external_css_url"
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(name, forKey: .name)
        
        try container.encode(options, forKey: .options)
        
        try container.encode(externalAppUrl, forKey: .externalAppUrl)
        
        try container.encode(externalCssUrl, forKey: .externalCssUrl)
    }
}
