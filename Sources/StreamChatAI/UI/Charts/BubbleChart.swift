//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

@available(iOS 16.0, *)
struct BubbleChart: View {
    let spec: USpec

    var body: some View {
        Chart {
            ForEach(spec.series) { s in
                ForEach(s.points) { p in
                    if #available(iOS 17.0, *), let r = p.size {
                        // iOS 17: data-driven size
                        PointMark(
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .symbolSize(by: .value(L10n.Charts.size, r))
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    } else if let r = p.size {
                        // iOS 16: use a fixed numeric size (coarse fallback)
                        PointMark(
                            x: .value(spec.xLabel ?? L10n.Charts.axisX, p.x),
                            y: .value(spec.yLabel ?? L10n.Charts.axisY, p.y)
                        )
                        .symbolSize(CGFloat(max(6, min(80, r))))
                        .foregroundStyle(by: .value(L10n.Charts.series, s.name))
                    } else {
                        // no size provided
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
