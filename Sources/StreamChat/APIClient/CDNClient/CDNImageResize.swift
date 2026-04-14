//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreGraphics

/// Parameters for CDN server-side image resize (Stream `w` / `h` / `resize` / `crop` query parameters).
public struct CDNImageResize: Sendable {
    /// Width in points (scaled to pixels using screen scale when building the URL).
    public var width: CGFloat
    /// Height in points (scaled to pixels using screen scale when building the URL).
    public var height: CGFloat
    /// Value for the `resize` query parameter (for example `"clip"`, `"crop"`, `"fill"`, `"scale"`).
    public var resizeMode: String
    /// Value for the `crop` query parameter when using crop resize mode.
    public var crop: String?

    public init(width: CGFloat, height: CGFloat, resizeMode: String, crop: String? = nil) {
        self.width = width
        self.height = height
        self.resizeMode = resizeMode
        self.crop = crop
    }
}
