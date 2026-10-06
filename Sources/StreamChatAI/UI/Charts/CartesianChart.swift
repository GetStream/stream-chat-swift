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
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    }
                case .area:
                    ForEach(s.points) { p in
                        AreaMark(
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    }
                case .line:
                    ForEach(s.points) { p in
                        LineMark(
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    }
                default: // scatter
                    ForEach(s.points) { p in
                        PointMark(
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    }
                }
            }
        }
        .applyBeginAtZero(spec.beginAtZeroY)
    }
}
