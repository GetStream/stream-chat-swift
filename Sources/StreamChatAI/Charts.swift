//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Charts
import SwiftUI
internal import MarkdownUI

// MARK: - Unified Internal Model (USpec)

public enum ChartKind: String {
    case line, bar, area, scatter, bubble, pie, heatmap, histogram
}

public struct UPoint: Identifiable, Hashable {
    public var id: String { "\(x)|\(y)|\(size ?? -1)|\(z ?? -1)" }
    public let x: String // category or stringified number/date
    public let y: Double
    public let size: Double? // for bubble
    public let z: Double? // for heatmap intensity
    public init(x: String, y: Double, size: Double? = nil, z: Double? = nil) {
        self.x = x; self.y = y; self.size = size; self.z = z
    }
}

public final class USeries: Identifiable {
    public let id = UUID()
    public let name: String
    public let points: [UPoint]
    public init(name: String, points: [UPoint]) { self.name = name; self.points = points }
}

public final class USpec {
    public let title: String?
    public let kind: ChartKind
    public let xLabel: String?
    public let yLabel: String?
    public let beginAtZeroY: Bool
    public let series: [USeries]
    public init(title: String?, kind: ChartKind, xLabel: String? = nil, yLabel: String? = nil, beginAtZeroY: Bool = false, series: [USeries]) {
        self.title = title; self.kind = kind; self.xLabel = xLabel; self.yLabel = yLabel; self.beginAtZeroY = beginAtZeroY; self.series = series
    }
}

// MARK: - Decoders & Adapters

private enum ParsedSpecError: Error {
    /// The JSON is no chart this SDK can draw.
    case unsupported
    /// The JSON is not in the format being read, so the next one is tried.
    case mismatch
}

public func parseUSpec(from jsonData: Data) throws -> USpec {
    guard let root = try? JSONObject(JSONSerialization.jsonObject(with: jsonData)) else {
        throw ParsedSpecError.unsupported
    }
    // Chart.js, Plotly heatmaps (a single spec, then a figure), ECharts, Highcharts, a subset of
    // Vega-Lite, the custom schema and the flat pie schema, in that order.
    let formats: [(JSONObject) throws -> USpec] = [chartJS, plotlySpec, plotlyFigure, eCharts, highcharts, vegaLite, custom, pieFlat]
    for format in formats {
        do {
            return try format(root)
        } catch ParsedSpecError.mismatch {
            continue
        }
    }
    throw ParsedSpecError.unsupported
}

/// A JSON object, read as strictly as `JSONDecoder` reads a `Decodable` type: a required field
/// that is missing or null, or any field of the wrong type, means the JSON is in another format.
private struct JSONObject {
    let fields: [String: Any]

    init(_ value: Any) throws {
        guard let fields = value as? [String: Any] else { throw ParsedSpecError.mismatch }
        self.fields = fields
    }

    /// The field, or `nil` when it is missing or null.
    subscript(_ key: String) -> Any? {
        guard let value = fields[key], !(value is NSNull) else { return nil }
        return value
    }

    func required(_ key: String) throws -> Any {
        guard let value = self[key] else { throw ParsedSpecError.mismatch }
        return value
    }

    func string(_ key: String) throws -> String { try asString(required(key)) }
    func number(_ key: String) throws -> Double { try asNumber(required(key)) }
    func array(_ key: String) throws -> [Any] { try asArray(required(key)) }
    func object(_ key: String) throws -> JSONObject { try JSONObject(required(key)) }
    func optionalString(_ key: String) throws -> String? { try self[key].map(asString) }
    func optionalStrings(_ key: String) throws -> [String]? { try self[key].map { try asArray($0).map(asString) } }
    func optionalObject(_ key: String) throws -> JSONObject? { try self[key].map(JSONObject.init) }
}

private func asString(_ value: Any) throws -> String {
    guard let string = value as? String else { throw ParsedSpecError.mismatch }
    return string
}

private func asArray(_ value: Any) throws -> [Any] {
    guard let array = value as? [Any] else { throw ParsedSpecError.mismatch }
    return array
}

/// A JSON number. Like `JSONDecoder`, it reads no other value as a `Double`, booleans included.
private func asNumber(_ value: Any) throws -> Double {
    guard let number = value as? NSNumber, CFGetTypeID(number) != CFBooleanGetTypeID() else { throw ParsedSpecError.mismatch }
    return number.doubleValue
}

private func asNumbers(_ value: Any) throws -> [Double] { try asArray(value).map(asNumber) }

private func asBool(_ value: Any) throws -> Bool {
    guard let number = value as? NSNumber, CFGetTypeID(number) == CFBooleanGetTypeID() else { throw ParsedSpecError.mismatch }
    return number.boolValue
}

/// A loosely typed number, as `AnyDecodable` reads it: a number, or a boolean as 1 or 0.
private func looseNumber(_ value: Any?) -> Double? { (value as? NSNumber)?.doubleValue }

private func looseString(_ value: Any?) -> String? { value as? String }

// ---------- Custom schema (from earlier) ----------
private func custom(_ root: JSONObject) throws -> USpec {
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

// ---------- Flat pie ----------
private func pieFlat(_ root: JSONObject) throws -> USpec {
    let type = try root.string("type")
    let title = try root.optionalString("title")
    let points = try root.array("data").map { item -> UPoint in
        let item = try JSONObject(item)
        return try UPoint(x: item.string("label"), y: item.number("value"))
    }
    guard type.lowercased() == "pie" else { throw ParsedSpecError.mismatch }
    return USpec(title: title, kind: .pie, series: [USeries(name: title ?? "Pie", points: points)])
}

// ---------- Chart.js ----------
private typealias ChartJSValue = (x: Double?, y: Double?, r: Double?)

/// A Chart.js value: a number, or an object of numbers `{x, y, r}`. Anything else has none.
private func chartJSValue(_ value: Any) -> ChartJSValue {
    if let y = try? asNumber(value) { return (nil, y, nil) }
    if let object = value as? [String: Any], let numbers = try? object.mapValues(asNumber) {
        return (numbers["x"], numbers["y"], numbers["r"])
    }
    return (nil, nil, nil)
}

private func chartJS(_ root: JSONObject) throws -> USpec {
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
        return USpec(title: title, kind: .pie, series: [USeries(name: dataset.label ?? "Pie", points: points)])
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
        return USeries(name: dataset.label ?? "Series", points: points)
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

// ---------- ECharts and Highcharts ----------
/// A series value: a number, an `[x, y]` pair or, in ECharts, an object such as
/// `{name, value}`. Anything else reads as 0.
private enum Datum {
    case number(Double)
    case pair([Double])
    case object([String: Any])

    init(_ value: Any, objects: Bool) {
        if let number = try? asNumber(value) {
            self = .number(number)
        } else if let pair = try? asNumbers(value) {
            self = .pair(pair)
        } else if objects, let object = value as? [String: Any] {
            self = .object(object)
        } else {
            self = .number(0)
        }
    }
}

private func series(_ root: JSONObject, objects: Bool) throws -> [(name: String?, type: String?, data: [Datum])] {
    try root.array("series").map { series in
        let series = try JSONObject(series)
        return try (series.optionalString("name"), series.optionalString("type"), series.array("data").map { Datum($0, objects: objects) })
    }
}

/// A series' points: values aligned with the categories, when there are any, and counted
/// from zero otherwise.
private func points(_ data: [Datum], categories: [String]?) -> [UPoint] {
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
private func eChartsAxis(_ root: JSONObject, _ key: String) throws -> [String]? {
    guard let axis = try root.optionalObject(key) else { return nil }
    _ = try axis.optionalString("type")
    return try axis.optionalStrings("data")
}

private func eCharts(_ root: JSONObject) throws -> USpec {
    let title = try root.optionalObject("title")?.optionalString("text")
    let categories = try eChartsAxis(root, "xAxis")
    _ = try eChartsAxis(root, "yAxis")
    let allSeries = try series(root, objects: true)
    let series = allSeries.map { series in
        guard series.type?.lowercased() == "pie" else {
            return USeries(name: series.name ?? "Series", points: points(series.data, categories: categories))
        }
        // ECharts pie often encodes data as [{name: "Android", value: 71.9}, ...]
        return USeries(name: series.name ?? "Series", points: series.data.compactMap { datum in
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

private func highcharts(_ root: JSONObject) throws -> USpec {
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
    let series = allSeries.map { USeries(name: $0.name ?? "Series", points: points($0.data, categories: categories)) }
    return USpec(title: title, kind: kind, series: series)
}

// ---------- Vega-Lite (tiny subset) ----------
private func vegaLite(_ root: JSONObject) throws -> USpec {
    _ = try root.optionalString("$schema")
    let values = try root.object("data")["values"].map(asArray)
    guard let mark = root.fields["mark"] else { throw ParsedSpecError.mismatch }
    let encoding = try root.object("encoding")
    func field(_ channel: String) throws -> String? {
        try encoding.optionalObject(channel)?.optionalString("field")
    }
    let xField = try field("x") ?? "x"
    let yField = try field("y") ?? "y"
    let colorField = try field("color")
    let sizeField = try field("size")
    // Without inline values there is nothing to draw, and no other format is tried.
    guard let values else { throw ParsedSpecError.unsupported }

    // Group by colorField into series
    var groups: [String: [UPoint]] = [:]
    for row in values {
        let row = row as? [String: Any] ?? [:]
        let x = looseString(row[xField]) ?? String(looseNumber(row[xField]) ?? 0)
        let key = colorField.flatMap { looseString(row[$0]) } ?? "Series"
        let size = sizeField.flatMap { looseNumber(row[$0]) }
        groups[key, default: []].append(UPoint(x: x, y: looseNumber(row[yField]) ?? 0, size: size))
    }

    // Determine kind from mark
    let kind: ChartKind = switch (mark as? String)?.lowercased() ?? "point" {
    case "line": .line
    case "bar": .bar
    case "area": .area
    case "point": .scatter
    case "rect": .heatmap
    default: .line
    }
    return USpec(title: nil, kind: kind, series: groups.map { USeries(name: $0.key, points: $0.value) })
}

// ---------- Plotly (heatmap) ----------
/// A Plotly title: a string, or an object of strings with its `text`.
private func plotlyTitle(_ value: Any?) -> String? {
    if let text = value as? String { return text }
    guard let object = value as? [String: Any], object.values.allSatisfy({ $0 is String }) else { return nil }
    return object["text"] as? String
}

private typealias PlotlyTitles = (title: String?, x: String?, y: String?)

private func plotlyLayout(_ root: JSONObject) throws -> PlotlyTitles {
    guard let layout = try root.optionalObject("layout") else { return (nil, nil, nil) }
    let xAxis = try layout.optionalObject("xaxis")
    let yAxis = try layout.optionalObject("yaxis")
    return (plotlyTitle(layout["title"]), plotlyTitle(xAxis?["title"]), plotlyTitle(yAxis?["title"]))
}

/// One series per row of `z`, named by `y`, with a point per column, named by `x`.
private func heatmap(z: [[Double]], x: [String]?, y: [String]?, titles: PlotlyTitles) -> USpec {
    let xCats = x ?? (z.first?.indices.map { String($0) } ?? [])
    let yCats = y ?? z.indices.map { String($0) }
    let series = z.enumerated().map { i, row in
        USeries(name: i < yCats.count ? yCats[i] : String(i), points: row.enumerated().map { j, value in
            UPoint(x: j < xCats.count ? xCats[j] : String(j), y: 0, z: value)
        })
    }
    return USpec(title: titles.title, kind: .heatmap, xLabel: titles.x, yLabel: titles.y, beginAtZeroY: false, series: series)
}

private func plotlySpec(_ root: JSONObject) throws -> USpec {
    let type = try root.string("type")
    let data = try root.object("data")
    let z = try data.array("z").map(asNumbers)
    let x = try data.optionalStrings("x")
    let y = try data.optionalStrings("y")
    let titles = try plotlyLayout(root)
    guard type.lowercased() == "heatmap" else { throw ParsedSpecError.mismatch }
    return heatmap(z: z, x: x, y: y, titles: titles)
}

private func plotlyFigure(_ root: JSONObject) throws -> USpec {
    let traces = try root.array("data").map { trace -> (type: String?, z: [[Double]]?, x: [String]?, y: [String]?) in
        let trace = try JSONObject(trace)
        _ = try trace.optionalString("name")
        return try (trace.optionalString("type"), trace["z"].map { try asArray($0).map(asNumbers) }, trace.optionalStrings("x"), trace.optionalStrings("y"))
    }
    let titles = try plotlyLayout(root)
    guard let trace = traces.first(where: { $0.type?.lowercased() == "heatmap" && $0.z != nil }), let z = trace.z else {
        throw ParsedSpecError.mismatch
    }
    return heatmap(z: z, x: trace.x, y: trace.y, titles: titles)
}

// ---------- AnyDecodable helper ----------
public struct AnyDecodable: Decodable {
    public let value: Any
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if let v = try? c.decode(Double.self) { value = v; return }
        if let v = try? c.decode(Int.self) { value = Double(v); return }
        if let v = try? c.decode(String.self) { value = v; return }
        if let v = try? c.decode(Bool.self) { value = v; return }
        if let v = try? c.decode([String: AnyDecodable].self) { value = v; return }
        if let v = try? c.decode([AnyDecodable].self) { value = v; return }
        value = NSNull()
    }

    public var string: String? { value as? String }
    public var double: Double? {
        if let d = value as? Double { return d }
        if let b = value as? Bool { return b ? 1 : 0 }
        return value as? Double
    }
}

// MARK: - Renderer

@available(iOS 16.0, *)
public struct USpecChartView: View {
    public let spec: USpec
    public init(spec: USpec) { self.spec = spec }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let title = spec.title { Text(title).font(.headline) }
            
            switch spec.kind {
            case .pie:
                PieChart(spec: spec).frame(height: 280)
                
            case .heatmap:
                HeatmapChart(spec: spec).frame(height: 280)
                
            case .histogram:
                HistogramChart(spec: spec).frame(height: 280)
                
            case .bubble:
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
                .frame(height: 280)
                
            case .scatter, .line, .bar, .area:
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
                .frame(height: 280)
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Specialized charts

// Pie / Donut
struct PieDatum: Identifiable { let id = UUID(); let label: String; let value: Double; let pct: Double }
func pieData(from spec: USpec) -> [PieDatum] {
    let pts = spec.series.first?.points ?? []
    let total = max(pts.reduce(0) { $0 + $1.y }, 0.000001)
    return pts.map { PieDatum(label: $0.x, value: $0.y, pct: $0.y / total) }
}

@available(iOS 16.0, *)
private struct PieChart: View {
    let spec: USpec
    var body: some View {
        let data = pieData(from: spec)
        Group {
            if #available(iOS 17.0, *) {
                Chart(data) { d in
                    SectorMark(angle: .value("Value", d.value), innerRadius: .ratio(0.0), angularInset: 1)
                        .foregroundStyle(by: .value("Category", d.label))
                        .annotation(position: .overlay, alignment: .center) {
                            if d.pct >= 0.08 { Text("\(d.label) \(Int(round(d.pct * 100)))%").font(.caption2).bold() }
                        }
                }
                .chartLegend(.visible)
            } else {
                // Swift Charts draws sectors from iOS 17, so iOS 16 shows each share as a bar.
                Chart(data) { d in
                    BarMark(x: .value("Category", d.label), y: .value("Value", d.value))
                        .foregroundStyle(by: .value("Category", d.label))
                        .annotation(position: .top) {
                            Text("\(Int(round(d.pct * 100)))%").font(.caption2).bold()
                        }
                }
                .chartLegend(.visible)
            }
        }
    }
}

// Heatmap (x category, y series.name or y extracted from point.x if encoded)
@available(iOS 16.0, *)
private struct HeatmapChart: View {
    let spec: USpec
    var body: some View {
        Chart {
            ForEach(spec.series) { s in
                ForEach(s.points) { p in
                    RectangleMark(
                        x: .value("X", p.x),
                        y: .value("Y", s.name),
                        width: .ratio(1.0),
                        height: .ratio(1.0)
                    )
                    .foregroundStyle(by: .value("Value", p.z ?? p.y))
                }
            }
        }
    }
}

// Histogram: expects one series with raw values in y; we bin in 10 buckets
@available(iOS 16.0, *)
private struct HistogramChart: View {
    let spec: USpec
    var body: some View {
        let raw = spec.series.first?.points.map { $0.y } ?? []
        let bins = makeBins(raw, targetBins: 10)
        Chart(bins) { b in
            BarMark(x: .value("Bin", b.label), y: .value("Count", b.count))
        }
    }
}

struct Bin: Identifiable { let id = UUID(); let label: String; let count: Int }
func makeBins(_ values: [Double], targetBins: Int) -> [Bin] {
    guard let minV = values.min(), let maxV = values.max(), maxV > minV else { return [] }
    let bins = max(targetBins, 1)
    let step = (maxV - minV) / Double(bins)
    var counts = Array(repeating: 0, count: bins)
    for v in values { let idx = min(Int((v - minV) / step), bins - 1); counts[idx] += 1 }
    return counts.enumerated().map { i, c in Bin(label: String(format: "%.1f–%.1f", minV + Double(i) * step, minV + Double(i + 1) * step), count: c) }
}

// MARK: - View helpers

@available(iOS 16.0, *)
private extension View {
    @ViewBuilder func applyBeginAtZero(_ include: Bool) -> some View {
        self.chartYScale(domain: include ? .automatic(includesZero: true) : .automatic(includesZero: false))
    }
}
