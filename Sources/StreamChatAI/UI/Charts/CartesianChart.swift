//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

/// Line, bar, area and scatter charts.
@available(iOS 16.0, *)
struct CartesianChart: View {
    let spec: USpec

    var body: some View {
        Chart {
            ForEach(spec.series) { s in
                switch spec.kind {
                case .bar:
                    ForEach(s.points) { p in
                        BarMark(
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .foregroundStyle(by: .value("Series", s.name))
                    }
                case .area:
                    ForEach(s.points) { p in
                        AreaMark(
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .foregroundStyle(by: .value("Series", s.name))
                    }
                case .line:
                    ForEach(s.points) { p in
                        LineMark(
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .foregroundStyle(by: .value("Series", s.name))
                    }
                default: // scatter
                    ForEach(s.points) { p in
                        PointMark(
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .foregroundStyle(by: .value("Series", s.name))
                    }
                }
            }
        }
        .applyBeginAtZero(spec.beginAtZeroY)
    }
}
