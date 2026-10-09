//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

@available(iOS 16.0, *)
struct USpecChartView: View {
    let spec: USpec
    init(spec: USpec) { self.spec = spec }

    @Injected(\.aiAppearance.fonts) private var fonts
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = spec.title { Text(title).font(fonts.chartTitle) }
            
            switch spec.kind {
            case .pie:
                PieChart(spec: spec).frame(height: 280)
                
            case .heatmap:
                HeatmapChart(spec: spec).frame(height: 280)
                
            case .histogram:
                HistogramChart(spec: spec).frame(height: 280)
                
            case .bubble:
                BubbleChart(spec: spec).frame(height: 280)

            case .scatter, .line, .bar, .area:
                CartesianChart(spec: spec).frame(height: 280)
            }
        }
        .padding(.vertical, 6)
    }
}
