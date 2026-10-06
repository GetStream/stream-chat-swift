//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import StreamCore
import SwiftUI

struct PieDatum: Identifiable { let id = UUID(); let label: String; let value: Double; let pct: Double }

func pieData(from spec: USpec) -> [PieDatum] {
    let pts = spec.series.first?.points ?? []
    let total = max(pts.reduce(0) { $0 + $1.y }, 0.000001)
    return pts.map { PieDatum(label: $0.x, value: $0.y, pct: $0.y / total) }
}

@available(iOS 16.0, *)
struct PieChart: View {
    let spec: USpec

    @Injected(\.aiAppearance.fonts) private var fonts

    var body: some View {
        let data = pieData(from: spec)
        let annotationFont = fonts.chartAnnotation
        Group {
            if #available(iOS 17.0, *) {
                Chart(data) { d in
                    SectorMark(angle: .value(L10n.Charts.value, d.value), innerRadius: .ratio(0.0), angularInset: 1)
                        .foregroundStyle(by: .value(L10n.Charts.category, d.label))
                        .annotation(position: .overlay, alignment: .center) {
                            if d.pct >= 0.08 { Text("\(d.label) \(Int(round(d.pct * 100)))%").font(annotationFont).bold() }
                        }
                }
                .chartLegend(.visible)
            } else {
                // Swift Charts draws sectors from iOS 17, so iOS 16 shows each share as a bar.
                Chart(data) { d in
                    BarMark(x: .value(L10n.Charts.category, d.label), y: .value(L10n.Charts.value, d.value))
                        .foregroundStyle(by: .value(L10n.Charts.category, d.label))
                        .annotation(position: .top) {
                            Text("\(Int(round(d.pct * 100)))%").font(annotationFont).bold()
                        }
                }
                .chartLegend(.visible)
            }
        }
    }
}
