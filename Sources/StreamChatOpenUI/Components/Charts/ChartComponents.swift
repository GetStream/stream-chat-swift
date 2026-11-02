//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI

/// One value of a named series at a category.
@available(iOS 17.0, macOS 14.0, *)
struct ChartPoint: Identifiable, Hashable {
    let category: String
    let series: String
    let value: Double
    let order: Int
    var id: String { "\(series)#\(order)" }
}

@available(iOS 17.0, macOS 14.0, *)
enum ChartData {
    /// Port of `buildChartData`: `labels` + `Series` elements, or tabular rows (`[[label, v1, v2], ...]`).
    static func points(labels: [OpenUIValue], series: [OpenUIValue]) -> (points: [ChartPoint], series: [String]) {
        let labelStrings = labels.map { JS.isNullish($0) ? "" : JS.toString($0) }
        if case .array? = series.first {
            let seriesNames = Array(labelStrings.dropFirst())
            var points: [ChartPoint] = []
            for (rowIndex, row) in series.enumerated() {
                let cells = row.arrayValue ?? []
                let category = cells.first.map { JS.isNullish($0) ? "" : JS.toString($0) } ?? ""
                for (seriesIndex, name) in seriesNames.enumerated() {
                    let cell = seriesIndex + 1 < cells.count ? cells[seriesIndex + 1] : nil
                    points.append(ChartPoint(category: category, series: name, value: JS.toNumber(cell), order: rowIndex))
                }
            }
            return (points, seriesNames)
        }
        let elements = series.compactMap(\.elementValue)
        var names: [String] = []
        var points: [ChartPoint] = []
        for element in elements {
            guard case .string(let name)? = element.props["category"], case .array(let values)? = element.props["values"] else { continue }
            if !names.contains(name) { names.append(name) }
            for (index, label) in labelStrings.enumerated() where index < values.count {
                points.append(ChartPoint(category: label, series: name, value: JS.toNumber(values[index]), order: index))
            }
        }
        return (points, names)
    }

    /// `labels` + `values`, falling back to legacy `Slice` elements.
    static func slices(labels: [OpenUIValue], values: [OpenUIValue]) -> [(label: String, value: Double)] {
        if !labels.isEmpty, !values.isEmpty {
            return labels.enumerated().map { index, label in
                let value: Double
                if index < values.count, case .number(let number) = values[index] { value = number } else { value = 0 }
                return (JS.isNullish(label) ? "" : JS.toString(label), value)
            }
        }
        return labels.compactMap(\.elementValue).map { slice in
            (slice.props["category"].map { JS.toString($0) } ?? "", JS.toNumber(slice.props["value"]))
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
private struct ChartFrame<Content: View>: View {
    let height: CGFloat
    let xLabel: String?
    let yLabel: String?
    @ViewBuilder let content: () -> Content
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            if let yLabel, !yLabel.isEmpty {
                Text(yLabel).font(.caption2).foregroundStyle(theme.colors.textSecondary)
            }
            content().frame(height: height)
            if let xLabel, !xLabel.isEmpty {
                Text(xLabel).font(.caption2).foregroundStyle(theme.colors.textSecondary).frame(maxWidth: .infinity)
            }
        }
    }
}

// MARK: - Cartesian charts

/// `BarChart`, `LineChart`, `AreaChart` and `HorizontalBarChart`.
@available(iOS 17.0, macOS 14.0, *)
struct CartesianChartView: View {
    enum Kind { case bar, line, area, horizontalBar }

    let context: ComponentContext
    let kind: Kind
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let props = context.props
        let (points, seriesNames) = ChartData.points(labels: props.array("labels"), series: props.array("series"))
        if !points.isEmpty {
            let variant = props.string("variant")
            let height = CGFloat(props.number("height") ?? (kind == .horizontalBar ? Double(max(160, Set(points.map(\.category)).count * 34 + 40)) : 220))
            ChartFrame(height: height, xLabel: props.text("xLabel"), yLabel: props.text("yLabel")) {
                Chart(points) { point in
                    mark(point, variant: variant)
                }
                .chartForegroundStyleScale(domain: seriesNames, range: seriesNames.indices.map { theme.colors.chartColor($0) })
                .chartLegend(seriesNames.count > 1 ? .visible : .hidden)
                .chartLegend(position: .bottom, alignment: .leading)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(Self.summary(points: points, series: seriesNames)))
        }
    }

    @ChartContentBuilder
    private func mark(_ point: ChartPoint, variant: String?) -> some ChartContent {
        let interpolation: InterpolationMethod = variant == "natural" ? .catmullRom : variant == "step" ? .stepCenter : .linear
        switch kind {
        case .bar:
            if variant == "stacked" {
                BarMark(x: .value("Category", point.category), y: .value("Value", point.value))
                    .foregroundStyle(by: .value("Series", point.series))
                    .cornerRadius(3)
            } else {
                BarMark(x: .value("Category", point.category), y: .value("Value", point.value))
                    .foregroundStyle(by: .value("Series", point.series))
                    .position(by: .value("Series", point.series))
                    .cornerRadius(3)
            }
        case .horizontalBar:
            if variant == "stacked" {
                BarMark(x: .value("Value", point.value), y: .value("Category", point.category))
                    .foregroundStyle(by: .value("Series", point.series))
                    .cornerRadius(3)
            } else {
                BarMark(x: .value("Value", point.value), y: .value("Category", point.category))
                    .foregroundStyle(by: .value("Series", point.series))
                    .position(by: .value("Series", point.series))
                    .cornerRadius(3)
            }
        case .line:
            LineMark(x: .value("Category", point.category), y: .value("Value", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(interpolation)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
            PointMark(x: .value("Category", point.category), y: .value("Value", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .symbolSize(24)
        case .area:
            AreaMark(x: .value("Category", point.category), y: .value("Value", point.value), stacking: .unstacked)
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(interpolation)
                .opacity(0.25)
            LineMark(x: .value("Category", point.category), y: .value("Value", point.value))
                .foregroundStyle(by: .value("Series", point.series))
                .interpolationMethod(interpolation)
                .lineStyle(StrokeStyle(lineWidth: 2))
        }
    }

    static func summary(points: [ChartPoint], series: [String]) -> String {
        series.map { name in
            let values = points.filter { $0.series == name }.map { "\($0.category) \(JS.numberToString($0.value))" }
            return "\(name): " + values.joined(separator: ", ")
        }.joined(separator: ". ")
    }
}

/// `ScatterChart(datasets, xLabel?, yLabel?)` with `ScatterSeries(name, points)` and `Point(x, y, z?)`.
@available(iOS 17.0, macOS 14.0, *)
struct ScatterChartView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    private struct ScatterPoint: Identifiable {
        let id: Int
        let series: String
        let x: Double
        let y: Double
        let z: Double?
    }

    var body: some View {
        var points: [ScatterPoint] = []
        var names: [String] = []
        for dataset in context.props.array("datasets") {
            let props = dataset.elementValue?.props ?? dataset.objectValue ?? [:]
            let name = props["name"].map { JS.toString($0) } ?? ""
            names.append(name)
            for point in props["points"]?.arrayValue ?? [] {
                let pointProps = point.elementValue?.props ?? point.objectValue ?? [:]
                points.append(ScatterPoint(
                    id: points.count,
                    series: name,
                    x: JS.toNumber(pointProps["x"]),
                    y: JS.toNumber(pointProps["y"]),
                    z: JS.isNullish(pointProps["z"]) ? nil : JS.toNumber(pointProps["z"])
                ))
            }
        }
        let maxZ = points.compactMap(\.z).max() ?? 1
        return Group {
            if !points.isEmpty {
                ChartFrame(height: 240, xLabel: context.props.text("xLabel"), yLabel: context.props.text("yLabel")) {
                    Chart(points) { point in
                        PointMark(x: .value("X", point.x), y: .value("Y", point.y))
                            .foregroundStyle(by: .value("Series", point.series))
                            .symbolSize(point.z.map { 30 + 170 * $0 / max(maxZ, 1) } ?? 50)
                            .opacity(0.8)
                    }
                    .chartForegroundStyleScale(domain: names, range: names.indices.map { theme.colors.chartColor($0) })
                    .chartLegend(names.count > 1 ? .visible : .hidden)
                }
            }
        }
    }
}

// MARK: - Proportional charts

@available(iOS 17.0, macOS 14.0, *)
struct LegendView: View {
    let entries: [(label: String, value: Double)]
    let showPercent: Bool
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let total = entries.map(\.value).reduce(0, +)
        VStack(alignment: .leading, spacing: 6) {
            ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                HStack(spacing: theme.spacing.s) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.colors.chartColor(index))
                        .frame(width: 10, height: 10)
                    Text(entry.label)
                        .font(theme.fonts.caption)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                    Spacer(minLength: theme.spacing.s)
                    Text(JS.numberToString(entry.value))
                        .font(theme.fonts.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(theme.colors.textPrimary)
                    if showPercent, total > 0, let percent = Self.percent(entry.value, of: total) {
                        Text("\(percent)%")
                            .font(theme.fonts.caption)
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.textSecondary)
                            .frame(minWidth: 34, alignment: .trailing)
                    }
                }
            }
        }
    }

    // A value's whole percentage of the total, or nil when the model's numbers don't make one,
    // such as an infinite slice.
    static func percent(_ value: Double, of total: Double) -> Int? {
        let percent = (value / total * 100).rounded()
        return percent.isFinite ? Int(percent) : nil
    }
}

/// A pie/donut sector.
@available(iOS 17.0, macOS 14.0, *)
private struct SectorShape: Shape {
    let start: Angle
    let end: Angle
    let innerRatio: CGFloat
    let semicircle: Bool

    func path(in rect: CGRect) -> Path {
        let center = semicircle ? CGPoint(x: rect.midX, y: rect.maxY) : CGPoint(x: rect.midX, y: rect.midY)
        let radius = semicircle ? min(rect.width / 2, rect.height) : min(rect.width, rect.height) / 2
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        if innerRatio > 0 {
            path.addArc(center: center, radius: radius * innerRatio, startAngle: end, endAngle: start, clockwise: true)
        } else {
            path.addLine(to: center)
        }
        path.closeSubpath()
        return path
    }
}

/// `PieChart(labels, values, variant?, appearance?)`.
@available(iOS 17.0, macOS 14.0, *)
struct PieChartView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let slices = ChartData.slices(labels: context.props.array("labels"), values: context.props.array("values"))
        let total = slices.map { max(0, $0.value) }.reduce(0, +)
        if total > 0 {
            let donut = context.props.string("variant") == "donut"
            let semicircle = context.props.string("appearance") == "semiCircular"
            let span: Double = semicircle ? 180 : 360
            let startOffset: Double = semicircle ? 180 : -90
            VStack(spacing: theme.spacing.m) {
                ZStack {
                    ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                        let before = slices.prefix(index).map { max(0, $0.value) }.reduce(0, +)
                        SectorShape(
                            start: .degrees(startOffset + before / total * span),
                            end: .degrees(startOffset + (before + max(0, slice.value)) / total * span),
                            innerRatio: donut ? 0.58 : 0,
                            semicircle: semicircle
                        )
                        .fill(theme.colors.chartColor(index))
                        .overlay(
                            SectorShape(
                                start: .degrees(startOffset + before / total * span),
                                end: .degrees(startOffset + (before + max(0, slice.value)) / total * span),
                                innerRatio: donut ? 0.58 : 0,
                                semicircle: semicircle
                            )
                            .stroke(theme.colors.surface, lineWidth: 1.5)
                        )
                    }
                    if donut {
                        VStack(spacing: 0) {
                            Text(JS.numberToString((total * 100).rounded() / 100))
                                .font(.title3.weight(.semibold))
                                .monospacedDigit()
                            Text("Total")
                                .font(.caption2)
                                .foregroundStyle(theme.colors.textSecondary)
                        }
                        .offset(y: semicircle ? 50 : 0)
                    }
                }
                .frame(width: semicircle ? 220 : 180, height: semicircle ? 110 : 180)
                .frame(maxWidth: .infinity)
                LegendView(entries: slices, showPercent: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(slices.map { "\($0.label) \(JS.numberToString($0.value))" }.joined(separator: ", ")))
        }
    }
}

/// `RadialChart(labels, values)` — one ring per category.
@available(iOS 17.0, macOS 14.0, *)
struct RadialChartView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let slices = ChartData.slices(labels: context.props.array("labels"), values: context.props.array("values"))
        let maximum = slices.map(\.value).max() ?? 0
        if !slices.isEmpty, maximum > 0 {
            VStack(spacing: theme.spacing.m) {
                ZStack {
                    ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                        let inset = CGFloat(index) * 16
                        Circle()
                            .stroke(theme.colors.sunkenSurface, lineWidth: 11)
                            .padding(inset)
                        Circle()
                            .trim(from: 0, to: max(0, slice.value) / maximum * 0.75)
                            .stroke(theme.colors.chartColor(index), style: StrokeStyle(lineWidth: 11, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .padding(inset)
                    }
                }
                .frame(width: 180, height: 180)
                .frame(maxWidth: .infinity)
                LegendView(entries: slices, showPercent: false)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(slices.map { "\($0.label) \(JS.numberToString($0.value))" }.joined(separator: ", ")))
        }
    }
}

/// `SingleStackedBarChart(labels, values)` — one horizontal bar split by share.
@available(iOS 17.0, macOS 14.0, *)
struct SingleStackedBarView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let slices = ChartData.slices(labels: context.props.array("labels"), values: context.props.array("values"))
        let total = slices.map { max(0, $0.value) }.reduce(0, +)
        if total > 0 {
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                GeometryReader { proxy in
                    HStack(spacing: 2) {
                        ForEach(Array(slices.enumerated()), id: \.offset) { index, slice in
                            Rectangle()
                                .fill(theme.colors.chartColor(index))
                                .frame(width: max(0, (proxy.size.width - CGFloat(slices.count - 1) * 2) * max(0, slice.value) / total))
                        }
                    }
                }
                .frame(height: 16)
                .clipShape(Capsule())
                LegendView(entries: slices, showPercent: true)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(slices.map { "\($0.label) \(JS.numberToString($0.value))" }.joined(separator: ", ")))
        }
    }
}

/// `RadarChart(labels, series)`.
@available(iOS 17.0, macOS 14.0, *)
struct RadarChartView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let labels = context.props.strings("labels")
        let (points, seriesNames) = ChartData.points(labels: context.props.array("labels"), series: context.props.array("series"))
        let maximum = max(points.map(\.value).max() ?? 0, 1)
        if labels.count >= 3, !points.isEmpty {
            VStack(spacing: theme.spacing.m) {
                Canvas { canvas, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - 28
                    func point(_ index: Int, _ fraction: Double) -> CGPoint {
                        let angle = -Double.pi / 2 + Double(index) / Double(labels.count) * 2 * Double.pi
                        return CGPoint(x: center.x + CGFloat(cos(angle) * fraction) * radius, y: center.y + CGFloat(sin(angle) * fraction) * radius)
                    }
                    for level in 1...4 {
                        var grid = Path()
                        for index in labels.indices {
                            let p = point(index, Double(level) / 4)
                            if index == 0 { grid.move(to: p) } else { grid.addLine(to: p) }
                        }
                        grid.closeSubpath()
                        canvas.stroke(grid, with: .color(theme.colors.border), lineWidth: 0.5)
                    }
                    for index in labels.indices {
                        var axis = Path()
                        axis.move(to: center)
                        axis.addLine(to: point(index, 1))
                        canvas.stroke(axis, with: .color(theme.colors.border), lineWidth: 0.5)
                        let labelPoint = point(index, 1.18)
                        canvas.draw(Text(labels[index]).font(.caption2).foregroundStyle(theme.colors.textSecondary), at: labelPoint)
                    }
                    for (seriesIndex, name) in seriesNames.enumerated() {
                        let values = points.filter { $0.series == name }.sorted { $0.order < $1.order }
                        guard !values.isEmpty else { continue }
                        var shape = Path()
                        for value in values {
                            let p = point(value.order, max(0, value.value) / maximum)
                            if value.order == values.first?.order { shape.move(to: p) } else { shape.addLine(to: p) }
                        }
                        shape.closeSubpath()
                        let color = theme.colors.chartColor(seriesIndex)
                        canvas.fill(shape, with: .color(color.opacity(0.2)))
                        canvas.stroke(shape, with: .color(color), lineWidth: 2)
                    }
                }
                .frame(height: 250)
                if seriesNames.count > 1 {
                    HStack(spacing: theme.spacing.m) {
                        ForEach(Array(seriesNames.enumerated()), id: \.offset) { index, name in
                            HStack(spacing: 4) {
                                Circle().fill(theme.colors.chartColor(index)).frame(width: 8, height: 8)
                                Text(name).font(theme.fonts.caption).foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(CartesianChartView.summary(points: points, series: seriesNames)))
        }
    }
}
