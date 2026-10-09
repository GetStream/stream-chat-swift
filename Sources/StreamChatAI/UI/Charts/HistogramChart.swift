//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

// Histogram: expects one series with raw values in y; we bin in 10 buckets
@available(iOS 16.0, *)
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

struct Bin: Identifiable { let id = UUID(); let label: String; let count: Int }

func makeBins(_ values: [Double], targetBins: Int) -> [Bin] {
    guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return [] }
    let bins = max(targetBins, 1)
    let step = (maxV - minV) / Double(bins)
    var counts = Array(repeating: 0, count: bins)
    for v in values { let idx = min(Int((v - minV) / step), bins - 1); counts[idx] += 1 }
    return counts.enumerated().map { i, c in Bin(label: String(format: "%.1f–%.1f", minV + Double(i) * step, minV + Double(i + 1) * step), count: c) }
}
