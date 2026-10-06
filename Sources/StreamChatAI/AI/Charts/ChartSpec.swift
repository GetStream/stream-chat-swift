//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public enum ChartKind: String {
    case line, bar, area, scatter, bubble, pie, heatmap, histogram
}

public struct UPoint: Identifiable, Hashable {
    public var id: String { "\(x)|\(y)|\(size ?? -1)|\(z ?? -1)" }
    public let x: String // category or stringified number/date
    public let y: Double
    public let size: Double? // for bubble
    public let z: Double? // for heatmap intensity
    public init(x: String, y: Double, size: Double? = nil, z: Double? = nil) {
        self.x = x; self.y = y; self.size = size; self.z = z
    }
}

public final class USeries: Identifiable {
    public let id = UUID()
    public let name: String
    public let points: [UPoint]
    public init(name: String, points: [UPoint]) { self.name = name; self.points = points }
}

public final class USpec {
    public let title: String?
    public let kind: ChartKind
    public let xLabel: String?
    public let yLabel: String?
    public let beginAtZeroY: Bool
    public let series: [USeries]
    public init(title: String?, kind: ChartKind, xLabel: String? = nil, yLabel: String? = nil, beginAtZeroY: Bool = false, series: [USeries]) {
        self.title = title; self.kind = kind; self.xLabel = xLabel; self.yLabel = yLabel; self.beginAtZeroY = beginAtZeroY; self.series = series
    }
}
