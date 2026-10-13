//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Reads the chart a code block describes, in the formats models write charts in: Chart.js,
/// Plotly heatmaps, ECharts, Highcharts, a subset of Vega-Lite, a custom schema and a flat
/// pie schema.
enum ChartSpecParser {
    private enum ParseError: Error {
        /// The JSON is no chart this SDK can draw.
        case unsupported
        /// The JSON is not in the format being read, so the next one is tried.
        case mismatch
    }

    static func parse(_ data: Data) throws -> USpec {
        guard let json = try? JSONDecoder().decode(RawJSON.self, from: data), let root = try? JSONObject(json) else {
            throw ParseError.unsupported
        }
        // Chart.js, Plotly heatmaps (a single spec, then a figure), ECharts, Highcharts, a subset of
        // Vega-Lite, the custom schema and the flat pie schema, in that order.
        let formats: [(JSONObject) throws -> USpec] = [chartJS, plotlySpec, plotlyFigure, eCharts, highcharts, vegaLite, custom, pieFlat]
        for format in formats {
            do {
                return try format(root)
            } catch ParseError.mismatch {
                continue
            }
        }
        throw ParseError.unsupported
    }

    /// A JSON object, read as strictly as `JSONDecoder` reads a `Decodable` type: a required field
    /// that is missing or null, or any field of the wrong type, means the JSON is in another format.
    private struct JSONObject {
        let fields: [String: RawJSON]

        init(_ value: RawJSON) throws {
            guard case let .dictionary(fields) = value else { throw ParseError.mismatch }
            self.fields = fields
        }

        /// The field, or `nil` when it is missing or null.
        subscript(_ key: String) -> RawJSON? {
            guard let value = fields[key], value != .nil else { return nil }
            return value
        }

        func required(_ key: String) throws -> RawJSON {
            guard let value = self[key] else { throw ParseError.mismatch }
            return value
        }

        func string(_ key: String) throws -> String { try asString(required(key)) }
        func number(_ key: String) throws -> Double { try asNumber(required(key)) }
        func array(_ key: String) throws -> [RawJSON] { try asArray(required(key)) }
        func object(_ key: String) throws -> JSONObject { try JSONObject(required(key)) }
        func optionalString(_ key: String) throws -> String? { try self[key].map(asString) }
        func optionalStrings(_ key: String) throws -> [String]? { try self[key].map { try asArray($0).map(asString) } }
        func optionalObject(_ key: String) throws -> JSONObject? { try self[key].map(JSONObject.init) }
    }

    private static func asString(_ value: RawJSON) throws -> String {
        guard case let .string(string) = value else { throw ParseError.mismatch }
        return string
    }

    private static func asArray(_ value: RawJSON) throws -> [RawJSON] {
        guard case let .array(array) = value else { throw ParseError.mismatch }
        return array
    }

    /// A JSON number. Like `JSONDecoder`, it reads no other value as a `Double`, booleans included.
    private static func asNumber(_ value: RawJSON) throws -> Double {
        guard case let .number(number) = value else { throw ParseError.mismatch }
        return number
    }

    private static func asNumbers(_ value: RawJSON) throws -> [Double] { try asArray(value).map(asNumber) }

    private static func asBool(_ value: RawJSON) throws -> Bool {
        guard case let .bool(bool) = value else { throw ParseError.mismatch }
        return bool
    }

    /// A loosely typed number: a number, or a boolean as 1 or 0.
    private static func looseNumber(_ value: RawJSON?) -> Double? {
        switch value {
        case let .number(number): number
        case let .bool(bool): bool ? 1 : 0
        default: nil
        }
    }

    private static func looseString(_ value: RawJSON?) -> String? {
        guard case let .string(string) = value else { return nil }
        return string
    }

    // MARK: - Custom Schema

    private static func custom(_ root: JSONObject) throws -> USpec {
        let title = try root.optionalString("title")
        let xLabel = try root.optionalString("x_label")
        let yLabel = try root.optionalString("y_label")
        let kind = try ChartKind(rawValue: root.string("chart_type").lowercased()) ?? .line
        let series = try root.array("series").map { series -> USeries in
            let series = try JSONObject(series)
            return try USeries(name: series.string("name"), points: series.array("points").map { point in
                let point = try JSONObject(point)
                return try UPoint(x: point.string("x"), y: point.number("y"))
            })
        }
        return USpec(title: title, kind: kind, xLabel: xLabel, yLabel: yLabel, beginAtZeroY: false, series: series)
    }

    // MARK: - Flat Pie

    private static func pieFlat(_ root: JSONObject) throws -> USpec {
        let type = try root.string("type")
        let title = try root.optionalString("title")
        let points = try root.array("data").map { item -> UPoint in
            let item = try JSONObject(item)
            return try UPoint(x: item.string("label"), y: item.number("value"))
        }
        guard type.lowercased() == "pie" else { throw ParseError.mismatch }
        return USpec(title: title, kind: .pie, series: [USeries(name: title ?? L10n.Charts.pie, points: points)])
    }

    // MARK: - Chart.js

    private typealias ChartJSValue = (x: Double?, y: Double?, r: Double?)

    /// A Chart.js value: a number, or an object of numbers `{x, y, r}`. Anything else has none.
    private static func chartJSValue(_ value: RawJSON) -> ChartJSValue {
        if let y = try? asNumber(value) { return (nil, y, nil) }
        if case let .dictionary(object) = value, let numbers = try? object.mapValues(asNumber) {
            return (numbers["x"], numbers["y"], numbers["r"])
        }
        return (nil, nil, nil)
    }

    private static func chartJS(_ root: JSONObject) throws -> USpec {
        let title = try root.optionalString("title")
        let type = try root.string("type").lowercased()
        let data = try root.object("data")
        let labels = try data.optionalStrings("labels")
        let datasets = try data.array("datasets").map { dataset -> (label: String?, values: [ChartJSValue]) in
            let dataset = try JSONObject(dataset)
            return try (dataset.optionalString("label"), dataset.array("data").map(chartJSValue))
        }
        var beginAtZero = false
        if let y = try root.optionalObject("options")?.optionalObject("scales")?.optionalObject("y"), let begin = y["beginAtZero"] {
            beginAtZero = try asBool(begin)
        }

        // Pie and doughnut
        if type == "pie" || type == "doughnut", let dataset = datasets.first {
            let labels = labels ?? Array(0..<dataset.values.count).map(String.init)
            let points = zip(labels, dataset.values).compactMap { label, value in value.y.map { UPoint(x: label, y: $0) } }
            return USpec(title: title, kind: .pie, series: [USeries(name: dataset.label ?? L10n.Charts.pie, points: points)])
        }

        let series = datasets.map { dataset -> USeries in
            let points: [UPoint]
            if let labels { // arrays aligned with labels
                points = labels.enumerated().compactMap { index, label in
                    let value: ChartJSValue = index < dataset.values.count ? dataset.values[index] : (nil, nil, nil)
                    return value.y.map { UPoint(x: label, y: $0, size: value.r) }
                }
            } else { // scatter/bubble with objects {x,y,r}
                points = dataset.values.compactMap { value in
                    guard let x = value.x, let y = value.y else { return nil }
                    return UPoint(x: String(x), y: y, size: value.r)
                }
            }
            return USeries(name: dataset.label ?? L10n.Charts.series, points: points)
        }

        let kind: ChartKind = switch type {
        case "line": .line
        case "bar": .bar
        case "area": .area
        case "scatter": .scatter
        case "bubble": .bubble
        case "radar": .bar // fallback mapping
        case "polararea": .pie // fallback mapping
        default: .line
        }
        return USpec(title: title, kind: kind, beginAtZeroY: beginAtZero, series: series)
    }

    // MARK: - ECharts and Highcharts

    /// A series value: a number, an `[x, y]` pair or, in ECharts, an object such as
    /// `{name, value}`. Anything else reads as 0.
    private enum Datum {
        case number(Double)
        case pair([Double])
        case object([String: RawJSON])

        init(_ value: RawJSON, objects: Bool) {
            if let number = try? ChartSpecParser.asNumber(value) {
                self = .number(number)
            } else if let pair = try? ChartSpecParser.asNumbers(value) {
                self = .pair(pair)
            } else if objects, case let .dictionary(object) = value {
                self = .object(object)
            } else {
                self = .number(0)
            }
        }
    }

    private static func series(_ root: JSONObject, objects: Bool) throws -> [(name: String?, type: String?, data: [Datum])] {
        try root.array("series").map { series in
            let series = try JSONObject(series)
            return try (series.optionalString("name"), series.optionalString("type"), series.array("data").map { Datum($0, objects: objects) })
        }
    }

    /// A series' points: values aligned with the categories, when there are any, and counted
    /// from zero otherwise.
    private static func points(_ data: [Datum], categories: [String]?) -> [UPoint] {
        var points: [UPoint] = []
        for (index, datum) in data.enumerated() {
            let category = categories.map { index < $0.count ? $0[index] : String(index) }
            switch datum {
            case .number(let y):
                points.append(UPoint(x: category ?? String(points.count), y: y))
            case .pair(let pair):
                if pair.count >= 2 { points.append(UPoint(x: String(pair[0]), y: pair[1])) }
            case .object(let object):
                if let y = looseNumber(object["value"]), let x = category ?? looseString(object["name"]) ?? looseString(object["x"]) {
                    points.append(UPoint(x: x, y: y))
                }
            }
        }
        return points
    }

    /// An ECharts axis' categories.
    private static func eChartsAxis(_ root: JSONObject, _ key: String) throws -> [String]? {
        guard let axis = try root.optionalObject(key) else { return nil }
        _ = try axis.optionalString("type")
        return try axis.optionalStrings("data")
    }

    private static func eCharts(_ root: JSONObject) throws -> USpec {
        let title = try root.optionalObject("title")?.optionalString("text")
        let categories = try eChartsAxis(root, "xAxis")
        _ = try eChartsAxis(root, "yAxis")
        let allSeries = try series(root, objects: true)
        let series = allSeries.map { series in
            guard series.type?.lowercased() == "pie" else {
                return USeries(name: series.name ?? L10n.Charts.series, points: points(series.data, categories: categories))
            }
            // ECharts pie often encodes data as [{name: "Android", value: 71.9}, ...]
            return USeries(name: series.name ?? L10n.Charts.series, points: series.data.compactMap { datum in
                guard case .object(let object) = datum, let name = looseString(object["name"]), let value = looseNumber(object["value"]) else { return nil }
                return UPoint(x: name, y: value)
            })
        }
        // Guess kind by first series type
        let kind: ChartKind = switch allSeries.first?.type?.lowercased() {
        case "bar": .bar
        case "line": .line
        case "scatter": .scatter
        case "pie": .pie
        default: .line
        }
        return USpec(title: title, kind: kind, series: series)
    }

    private static func highcharts(_ root: JSONObject) throws -> USpec {
        let title = try root.optionalObject("title")?.optionalString("text")
        let categories = try root.optionalObject("xAxis")?.optionalStrings("categories")
        let allSeries = try series(root, objects: false)
        let kind: ChartKind = switch allSeries.first?.type?.lowercased() {
        case "bar", "column": .bar
        case "line", "spline": .line
        case "scatter": .scatter
        case "pie": .pie
        default: .line
        }
        let series = allSeries.map { USeries(name: $0.name ?? L10n.Charts.series, points: points($0.data, categories: categories)) }
        return USpec(title: title, kind: kind, series: series)
    }

    // MARK: - Vega-Lite (Tiny Subset)

    private static func vegaLite(_ root: JSONObject) throws -> USpec {
        _ = try root.optionalString("$schema")
        let values = try root.object("data")["values"].map(asArray)
        guard let mark = root.fields["mark"] else { throw ParseError.mismatch }
        let encoding = try root.object("encoding")
        func field(_ channel: String) throws -> String? {
            try encoding.optionalObject(channel)?.optionalString("field")
        }
        let xField = try field("x") ?? "x"
        let yField = try field("y") ?? "y"
        let colorField = try field("color")
        let sizeField = try field("size")
        // Without inline values there is nothing to draw, and no other format is tried.
        guard let values else { throw ParseError.unsupported }

        // Group by colorField into series
        var groups: [String: [UPoint]] = [:]
        for value in values {
            let row: [String: RawJSON] = if case let .dictionary(fields) = value { fields } else { [:] }
            let x = looseString(row[xField]) ?? String(looseNumber(row[xField]) ?? 0)
            let key = colorField.flatMap { looseString(row[$0]) } ?? L10n.Charts.series
            let size = sizeField.flatMap { looseNumber(row[$0]) }
            groups[key, default: []].append(UPoint(x: x, y: looseNumber(row[yField]) ?? 0, size: size))
        }

        // Determine kind from mark
        let kind: ChartKind = switch looseString(mark)?.lowercased() ?? "point" {
        case "line": .line
        case "bar": .bar
        case "area": .area
        case "point": .scatter
        case "rect": .heatmap
        default: .line
        }
        return USpec(title: nil, kind: kind, series: groups.map { USeries(name: $0.key, points: $0.value) })
    }

    // MARK: - Plotly (Heatmap)

    /// A Plotly title: a string, or an object of strings with its `text`.
    private static func plotlyTitle(_ value: RawJSON?) -> String? {
        if let text = looseString(value) { return text }
        guard case let .dictionary(object) = value, object.values.allSatisfy({ looseString($0) != nil }) else { return nil }
        return looseString(object["text"])
    }

    private typealias PlotlyTitles = (title: String?, x: String?, y: String?)

    private static func plotlyLayout(_ root: JSONObject) throws -> PlotlyTitles {
        guard let layout = try root.optionalObject("layout") else { return (nil, nil, nil) }
        let xAxis = try layout.optionalObject("xaxis")
        let yAxis = try layout.optionalObject("yaxis")
        return (plotlyTitle(layout["title"]), plotlyTitle(xAxis?["title"]), plotlyTitle(yAxis?["title"]))
    }

    /// One series per row of `z`, named by `y`, with a point per column, named by `x`.
    private static func heatmap(z: [[Double]], x: [String]?, y: [String]?, titles: PlotlyTitles) -> USpec {
        let xCats = x ?? (z.first?.indices.map { String($0) } ?? [])
        let yCats = y ?? z.indices.map { String($0) }
        let series = z.enumerated().map { i, row in
            USeries(name: i < yCats.count ? yCats[i] : String(i), points: row.enumerated().map { j, value in
                UPoint(x: j < xCats.count ? xCats[j] : String(j), y: 0, z: value)
            })
        }
        return USpec(title: titles.title, kind: .heatmap, xLabel: titles.x, yLabel: titles.y, beginAtZeroY: false, series: series)
    }

    private static func plotlySpec(_ root: JSONObject) throws -> USpec {
        let type = try root.string("type")
        let data = try root.object("data")
        let z = try data.array("z").map(asNumbers)
        let x = try data.optionalStrings("x")
        let y = try data.optionalStrings("y")
        let titles = try plotlyLayout(root)
        guard type.lowercased() == "heatmap" else { throw ParseError.mismatch }
        return heatmap(z: z, x: x, y: y, titles: titles)
    }

    private static func plotlyFigure(_ root: JSONObject) throws -> USpec {
        let traces = try root.array("data").map { trace -> (type: String?, z: [[Double]]?, x: [String]?, y: [String]?) in
            let trace = try JSONObject(trace)
            _ = try trace.optionalString("name")
            return try (trace.optionalString("type"), trace["z"].map { try asArray($0).map(asNumbers) }, trace.optionalStrings("x"), trace.optionalStrings("y"))
        }
        let titles = try plotlyLayout(root)
        guard let trace = traces.first(where: { $0.type?.lowercased() == "heatmap" && $0.z != nil }), let z = trace.z else {
            throw ParseError.mismatch
        }
        return heatmap(z: z, x: trace.x, y: trace.y, titles: titles)
    }
}
