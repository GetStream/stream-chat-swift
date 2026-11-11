//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

@available(iOS 15.0, macOS 12.0, *)
enum ChartKind: String {
    case line, bar, area, scatter, bubble, pie, heatmap, histogram
}

@available(iOS 15.0, macOS 12.0, *)
struct UPoint: Identifiable, Hashable {
    var id: String { "\(x)|\(y)|\(size ?? -1)|\(z ?? -1)" }
    let x: String // category or stringified number/date
    let y: Double
    let size: Double? // for bubble
    let z: Double? // for heatmap intensity
    init(x: String, y: Double, size: Double? = nil, z: Double? = nil) {
        self.x = x; self.y = y; self.size = size; self.z = z
    }
}

@available(iOS 15.0, macOS 12.0, *)
final class USeries: Identifiable {
    let id = UUID()
    let name: String
    let points: [UPoint]
    init(name: String, points: [UPoint]) { self.name = name; self.points = points }
}

@available(iOS 15.0, macOS 12.0, *)
final class USpec {
    let title: String?
    let kind: ChartKind
    let xLabel: String?
    let yLabel: String?
    let beginAtZeroY: Bool
    let series: [USeries]
    init(title: String?, kind: ChartKind, xLabel: String? = nil, yLabel: String? = nil, beginAtZeroY: Bool = false, series: [USeries]) {
        self.title = title; self.kind = kind; self.xLabel = xLabel; self.yLabel = yLabel; self.beginAtZeroY = beginAtZeroY; self.series = series
    }
}
