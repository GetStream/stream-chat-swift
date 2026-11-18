//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatOpenUI
import SwiftUI
import Testing

@MainActor
@Suite("Chart components")
struct ChartComponentTests {
    @Test(arguments: 1...24)
    func radialRingsFitAnyNumberOfCategories(_ count: Int) {
        let diameter = RadialChartView.diameter
        let rings = RadialChartView.rings(count: count, diameter: diameter)
        let innermostRadius = diameter / 2 - CGFloat(count - 1) * rings.pitch - rings.lineWidth

        #expect(rings.lineWidth > 0)
        #expect(rings.lineWidth < rings.pitch)
        #expect(innermostRadius >= 12)
    }

    @Test func radialRingsKeepTheirSizeForFewCategories() {
        let rings = RadialChartView.rings(count: 3, diameter: RadialChartView.diameter)

        #expect(rings.pitch == 16)
        #expect(rings.lineWidth == 11)
    }

    @Test func radarUsesOneAxisPerRowOfTabularData() {
        let labels: [OpenUIValue] = ["skill", "Ana", "Ben"]
        let rows: [OpenUIValue] = [["Speed", 5, 3], ["Power", 2, 4], ["Range", 4, 4], ["Focus", 1, 5]]
        let (points, series) = ChartData.points(labels: labels, series: rows)

        #expect(series == ["Ana", "Ben"])
        #expect(RadarChartView.axes(labels: ["skill", "Ana", "Ben"], series: rows, points: points) == ["Speed", "Power", "Range", "Focus"])
        #expect(points.filter { $0.series == "Ben" }.map(\.order) == [0, 1, 2, 3])
    }

    @Test func radarUsesTheLabelsForSeriesData() throws {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: """
        root = Card([chart])
        chart = RadarChart(["Speed", "Power", "Range"], [Series("Ana", [5, 2, 4])])
        """, isStreaming: false)
        let chart = try #require(runtime.root?.props["children"]?.arrayValue?.first?.elementValue)
        let props = ComponentProps(chart.props)
        let (points, _) = ChartData.points(labels: props.array("labels"), series: props.array("series"))

        #expect(RadarChartView.axes(labels: props.strings("labels"), series: props.array("series"), points: points) == ["Speed", "Power", "Range"])
    }

    @Test(arguments: [
        #"BarChart(["a", "b", "c"], [Series("s", [1e308, -1e308, 1])])"#,
        #"LineChart(["a", "b"], [Series("s", [1e308, 1])])"#,
        #"AreaChart(["a", "b"], [Series("s", [-1e308, 1])])"#,
        #"HorizontalBarChart(["a", "b"], [Series("s", [1e308, -1e308])])"#,
        #"ScatterChart([ScatterSeries("s", [Point(1e308, -1e308), Point(1, 2, 1e308)])])"#,
        #"PieChart(["a", "b"], [1e308, 1e308])"#,
        #"RadialChart(["a", "b"], [1e308, -1e308])"#,
        #"SingleStackedBarChart(["a", "b"], [1e308, 1e308])"#,
        #"RadarChart(["x", "y", "z"], [Series("s", [1e308, -1e308, 1])])"#
    ])
    func hugeValuesRenderWithoutTrapping(_ chart: String) {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: "root = Card([chart])\nchart = \(chart)", isStreaming: false)

        #expect(runtime.root?.props["children"]?.arrayValue?.count == 1)
        #expect(RenderingTests.render(runtime) != nil)
    }

    @Test func chartValuesAreKeptFiniteAndInRange() {
        let series = OpenUIValue.element(ElementNode(typeName: "Series", props: ["category": "s", "values": [1e308, .number(.nan), -1e308, 3]]))
        let (points, _) = ChartData.points(labels: ["a", "b", "c", "d"], series: [series])
        let rows = ChartData.points(labels: ["label", "s"], series: [["a", 1e308], ["b", .number(-.infinity)]]).points

        #expect(points.map(\.value) == [1e15, -1e15, 3])
        #expect(points.map(\.category) == ["a", "c", "d"])
        #expect(rows.map(\.value) == [1e15])
        #expect(ChartData.slices(labels: ["a", "b", "c"], values: [1e308, .number(.infinity), 2]).map(\.value) == [1e15, 2])
    }

    @Test func seriesWithTheSameNameHaveTheirOwnPoints() {
        let first = OpenUIValue.element(ElementNode(typeName: "Series", props: ["category": "Sales", "values": [1, 2]]))
        let second = OpenUIValue.element(ElementNode(typeName: "Series", props: ["category": "Sales", "values": [3, 4]]))
        let (points, series) = ChartData.points(labels: ["a", "b"], series: [first, second])
        let rows = ChartData.points(labels: ["label", "s", "s"], series: [["a", 1, 2]])

        #expect(Set(points.map(\.id)).count == 4)
        #expect(series == ["Sales"])
        #expect(Set(rows.points.map(\.id)).count == 2)
        #expect(rows.series == ["s"])
    }

    @Test func seriesWithTheSameNameAreDrawnApart() {
        let rows = ChartData.points(labels: ["day", "Sales", "Sales"], series: [["Mon", 1, 4], ["Tue", 2, 5], ["Wed", 3, 6]])

        #expect(rows.series == ["Sales"])
        #expect(ChartData.bySeries(rows.points).map { $0.map(\.value) } == [[1, 2, 3], [4, 5, 6]])
        #expect(ChartData.distinct(["b", "a", "b", "c", "a"]) == ["b", "a", "c"])
    }

    @Test func bubbleSizesFollowTheRangeOfZ() {
        #expect(ScatterChartView.symbolSizes([-5, 0, 5, nil]) == [30, 115, 200, 50])
        #expect(ScatterChartView.symbolSizes([3, 3]) == [50, 50])
        #expect(ScatterChartView.symbolSizes([]).isEmpty)
    }

    @Test func modelSizesAreKeptInRange() {
        #expect(clampedDimension(-200, in: 80...1200, default: 220) == 80)
        #expect(clampedDimension(1e300, in: 80...1200, default: 220) == 1200)
        #expect(clampedDimension(.infinity, in: 80...1200, default: 220) == 220)
        #expect(clampedDimension(.nan, in: 0...64, default: 12) == 12)
        #expect(clampedDimension(nil, in: 16...200, default: 40) == 40)
        #expect(clampedDimension(48, in: 16...200, default: 40) == 48)
    }

    @Test func anEmptyPaletteFallsBackToTheDefaultColors() {
        var colors = OpenUITheme.Colors()
        let defaults = colors.chartPalette
        colors.chartPalette = []

        #expect(colors.chartColor(0) == defaults[0])
        #expect(colors.chartColor(-1) == defaults[defaults.count - 1])
        #expect(RenderingTests.render(OpenUIView(runtime: Self.pieRuntime()).environment(\.openUITheme, Self.theme(palette: []))) != nil)
    }

    static func pieRuntime() -> OpenUIRuntime {
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: #"root = Card([PieChart(["a", "b"], [1, 2]), BarChart(["a"], [Series("s", [1])])])"#, isStreaming: false)
        return runtime
    }

    static func theme(palette: [Color]) -> OpenUITheme {
        var theme = OpenUITheme()
        theme.colors.chartPalette = palette
        return theme
    }

    @Test func chartsWithManyCategoriesRender() {
        let labels = (1...12).map { "\"C\($0)\"" }.joined(separator: ", ")
        let values = (1...12).map(String.init).joined(separator: ", ")
        let runtime = OpenUIRuntime(library: .openUIChat)
        runtime.update(response: """
        root = Card([radial, radar])
        radial = RadialChart([\(labels)], [\(values)])
        radar = RadarChart(["skill", "Ana"], [["Speed", 5], ["Power", 2], ["Range", 4]])
        """, isStreaming: false)

        #expect(RenderingTests.render(runtime) != nil)
        #expect(RenderingTests.render(runtime, colorScheme: .dark) != nil)
    }
}
