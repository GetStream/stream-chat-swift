//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

// Histogram: expects one series with raw values in y; we bin in 10 buckets
@available(iOS 16.0, macOS 13.0, *)
struct HistogramChart: View {
    let spec: USpec
    var body: some View {
        let raw = spec.series.first?.points.map { $0.y } ?? []
        let bins = makeBins(raw, targetBins: 10)
        Chart(bins) { b in
            BarMark(x: .value(L10n.Charts.bin, b.label), y: .value(L10n.Charts.count, b.count))
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct Bin: Identifiable { let id = UUID(); let label: String; let count: Int }

@available(iOS 15.0, macOS 12.0, *)
func makeBins(_ values: [Double], targetBins: Int) -> [Bin] {
    let values = values.filter(\.isFinite)
    guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return [] }
    let bins = max(targetBins, 1)
    // A range wider than a Double holds, or too narrow to split, has no bins to count in.
    let step = (maxV - minV) / Double(bins)
    guard step.isFinite, step > 0 else { return [] }
    var counts = Array(repeating: 0, count: bins)
    for v in values {
        let position = (v - minV) / step
        let idx = position.isFinite ? min(max(Int(position), 0), bins - 1) : bins - 1
        counts[idx] += 1
    }
    return counts.enumerated().map { i, c in Bin(label: String(format: "%.1f–%.1f", minV + Double(i) * step, minV + Double(i + 1) * step), count: c) }
}
