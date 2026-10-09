//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

// Heatmap (x category, y series.name or y extracted from point.x if encoded)
@available(iOS 16.0, *)
struct HeatmapChart: View {
    let spec: USpec
    var body: some View {
        Chart {
            ForEach(spec.series) { s in
                ForEach(s.points) { p in
                    RectangleMark(
                        x: .value(L10n.Charts.axisX, p.x),
                        y: .value(L10n.Charts.axisY, s.name),
                        width: .ratio(1.0),
                        height: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value(L10n.Charts.value, p.z ?? p.y))
                }
            }
        }
    }
}
