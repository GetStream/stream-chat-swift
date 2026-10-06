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
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .symbolSize(by: .value("Size", r))
                        .foregroundStyle(by: .value("Series", s.name))
                    } else if let r = p.size {
                        // iOS 16: use a fixed numeric size (coarse fallback)
                        PointMark(
                            x: .value(spec.xLabel ?? "X", p.x),
                            y: .value(spec.yLabel ?? "Y", p.y)
                        )
                        .symbolSize(CGFloat(max(6, min(80, r))))
                        .foregroundStyle(by: .value("Series", s.name))
                    } else {
                        // no size provided
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
