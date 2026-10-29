//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// A type representing the app settings.
public final class AppSettings: Sendable, Decodable {
    /// A boolean value determining if async url enrichment is enabled.
    public let asyncUrlEnrichEnabled: Bool
    /// A boolean value determining if auto translation is enabled.
    public let autoTranslationEnabled: Bool
    public let fileUploadConfig: UploadConfig
    public let id: Int
    public let imageUploadConfig: UploadConfig
    /// The name of the app.
    public let name: String
    public let placement: String

    init(
        asyncUrlEnrichEnabled: Bool,
        autoTranslationEnabled: Bool,
        fileUploadConfig: UploadConfig,
        id: Int,
        imageUploadConfig: UploadConfig,
        name: String,
        placement: String
    ) {
        self.asyncUrlEnrichEnabled = asyncUrlEnrichEnabled
        self.autoTranslationEnabled = autoTranslationEnabled
        self.fileUploadConfig = fileUploadConfig
        self.id = id
        self.imageUploadConfig = imageUploadConfig
        self.name = name
        self.placement = placement
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.asyncUrlEnrichEnabled = try container.decode(Bool.self, forKey: .asyncUrlEnrichEnabled)
        self.autoTranslationEnabled = try container.decode(
            Bool.self,
            forKey: .autoTranslationEnabled
        )
        self.fileUploadConfig = try container.decode(UploadConfig.self, forKey: .fileUploadConfig)
        self.id = try container.decode(Int.self, forKey: .id)
        self.imageUploadConfig = try container.decode(UploadConfig.self, forKey: .imageUploadConfig)
        self.name = try container.decode(String.self, forKey: .name)
        self.placement = try container.decode(String.self, forKey: .placement)
    }
}

extension AppSettings: Hashable {
    public static func == (lhs: AppSettings, rhs: AppSettings) -> Bool {
        lhs.asyncUrlEnrichEnabled == rhs.asyncUrlEnrichEnabled &&
            lhs.autoTranslationEnabled == rhs.autoTranslationEnabled &&
            lhs.fileUploadConfig == rhs.fileUploadConfig &&
            lhs.id == rhs.id &&
            lhs.imageUploadConfig == rhs.imageUploadConfig &&
            lhs.name == rhs.name &&
            lhs.placement == rhs.placement
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(asyncUrlEnrichEnabled)
        hasher.combine(autoTranslationEnabled)
        hasher.combine(fileUploadConfig)
        hasher.combine(id)
        hasher.combine(imageUploadConfig)
        hasher.combine(name)
        hasher.combine(placement)
    }
}
