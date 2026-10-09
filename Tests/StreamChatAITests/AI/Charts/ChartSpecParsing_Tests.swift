//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatAI
import XCTest

final class ChartSpecParsing_Tests: XCTestCase {
    private func parse(_ json: String) throws -> USpec {
        try ChartSpecParser.parse(Data(json.utf8))
    }

    private func points(_ series: USeries) -> [String] {
        series.points.map { point in
            [point.x, "\(point.y)"] + [point.size, point.z].compactMap { $0.map { "\($0)" } }
        }.map { $0.joined(separator: ",") }
    }

    func testChartJSValuesFollowTheLabels() throws {
        let spec = try parse(#"{"type":"bar","title":"Sales","data":{"labels":["Jan","Feb","Mar"],"datasets":[{"label":"2025","data":[4,{"y":5,"r":2},null]},{"data":[true,1]}]},"options":{"scales":{"y":{"beginAtZero":true}}}}"#)

        XCTAssertEqual(spec.kind, .bar)
        XCTAssertEqual(spec.title, "Sales")
        XCTAssertTrue(spec.beginAtZeroY)
        XCTAssertEqual(spec.series.map(\.name), ["2025", "Series"])
        XCTAssertEqual(points(spec.series[0]), ["Jan,4.0", "Feb,5.0,2.0"])
        XCTAssertEqual(points(spec.series[1]), ["Feb,1.0"], "a boolean is not a number")
    }

    func testChartJSPointsWithoutLabelsAndPies() throws {
        let bubble = try parse(#"{"type":"bubble","data":{"datasets":[{"label":"A","data":[{"x":1,"y":2,"r":3},{"y":4},5]}]}}"#)
        XCTAssertEqual(bubble.kind, .bubble)
        XCTAssertEqual(points(bubble.series[0]), ["1.0,2.0,3.0"])

        let pie = try parse(#"{"type":"doughnut","data":{"labels":["A","B"],"datasets":[{"data":[30,70,5]}]}}"#)
        XCTAssertEqual(pie.kind, .pie)
        XCTAssertEqual(pie.series.map(\.name), ["Pie"])
        XCTAssertEqual(points(pie.series[0]), ["A,30.0", "B,70.0"])
    }

    func testEChartsSeriesReadNumbersPairsAndObjects() throws {
        let spec = try parse(#"{"title":{"text":"Week"},"xAxis":{"type":"category","data":["Mon","Tue","Wed"]},"series":[{"name":"Visits","type":"line","data":[1,{"value":4},[2,3],"-"]}]}"#)
        XCTAssertEqual(spec.kind, .line)
        XCTAssertEqual(spec.title, "Week")
        XCTAssertEqual(points(spec.series[0]), ["Mon,1.0", "Tue,4.0", "2.0,3.0", "3,0.0"])

        let pie = try parse(#"{"series":[{"type":"pie","data":[{"name":"Android","value":71.9},{"name":"iOS","value":"27"}]}]}"#)
        XCTAssertEqual(pie.kind, .pie)
        XCTAssertEqual(points(pie.series[0]), ["Android,71.9"])
    }

    func testHighchartsIsReadWhenItIsNotEChartsToo() throws {
        let spec = try parse(#"{"title":{"text":"H"},"xAxis":{"categories":["a","b"]},"yAxis":[{"title":{"text":"y"}}],"series":[{"name":"s","type":"column","data":[1,[2,3],{"y":4}]}]}"#)

        XCTAssertEqual(spec.kind, .bar, "Highcharts columns are bars")
        XCTAssertEqual(points(spec.series[0]), ["a,1.0", "2.0,3.0", "2,0.0"])
    }

    func testVegaLiteRowsGroupByColor() throws {
        let spec = try parse(#"{"data":{"values":[{"a":"A","b":28,"c":"g1"},{"a":"B","b":true,"c":"g2"},{"a":5,"b":"x","c":"g1"}]},"mark":"bar","encoding":{"x":{"field":"a"},"y":{"field":"b"},"color":{"field":"c"}}}"#)

        XCTAssertEqual(spec.kind, .bar)
        let series = Dictionary(uniqueKeysWithValues: spec.series.map { ($0.name, points($0)) })
        XCTAssertEqual(series, ["g1": ["A,28.0", "5.0,0.0"], "g2": ["B,1.0"]])
        XCTAssertThrowsError(try parse(#"{"data":{"url":"data.csv"},"mark":"line","encoding":{}}"#), "a spec without inline values can't be drawn")
    }

    func testPlotlyHeatmaps() throws {
        let single = try parse(#"{"type":"heatmap","data":{"z":[[1,2],[3,4]],"x":["a","b"],"y":["r1"]},"layout":{"title":"Heat","xaxis":{"title":{"text":"X"}}}}"#)
        XCTAssertEqual(single.kind, .heatmap)
        XCTAssertEqual(single.title, "Heat")
        XCTAssertEqual(single.xLabel, "X")
        XCTAssertEqual(single.series.map(\.name), ["r1", "1"])
        XCTAssertEqual(points(single.series[1]), ["a,0.0,3.0", "b,0.0,4.0"])

        let figure = try parse(#"{"data":[{"type":"scatter"},{"type":"Heatmap","z":[[7]]}],"layout":{"title":{"text":"Fig"}}}"#)
        XCTAssertEqual(figure.title, "Fig")
        XCTAssertEqual(points(figure.series[0]), ["0,0.0,7.0"])
    }

    func testTheCustomAndFlatPieSchemas() throws {
        let custom = try parse(#"{"title":"C","x_label":"X","y_label":"Y","chart_type":"Area","series":[{"name":"s","points":[{"x":"a","y":1}]}]}"#)
        XCTAssertEqual(custom.kind, .area)
        XCTAssertEqual(custom.yLabel, "Y")
        XCTAssertEqual(points(custom.series[0]), ["a,1.0"])

        let pie = try parse(#"{"type":"Pie","title":"P","data":[{"label":"a","value":1},{"label":"b","value":2.5}]}"#)
        XCTAssertEqual(pie.kind, .pie)
        XCTAssertEqual(pie.series.map(\.name), ["P"])
        XCTAssertEqual(points(pie.series[0]), ["a,1.0", "b,2.5"])
    }

    func testAFieldOfTheWrongTypeIsNoChart() {
        XCTAssertThrowsError(try parse(#"{"type":"bar","data":{"labels":[1,2],"datasets":[{"data":[1,2]}]}}"#))
        XCTAssertThrowsError(try parse(#"{"type":"Pie","data":[{"label":"a","value":"1"}]}"#))
        XCTAssertThrowsError(try parse(#"[{"type":"bar"}]"#))
        XCTAssertThrowsError(try parse("not json"))
    }
}
