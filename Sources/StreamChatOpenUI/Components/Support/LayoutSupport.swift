//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Container surfaces used by `Card`, `MarkDownRenderer`, `SwitchGroup`, ... (`card` | `sunk` | `clear`).
@available(iOS 17.0, macOS 14.0, *)
struct SurfaceBackground: ViewModifier {
    let variant: String?
    var padding: CGFloat?
    @Environment(\.openUITheme) private var theme

    func body(content: Content) -> some View {
        switch variant {
        case "clear":
            content
        case "sunk":
            content
                .padding(padding ?? theme.spacing.l)
                .background(theme.colors.sunkenSurface, in: RoundedRectangle(cornerRadius: theme.radius.medium, style: .continuous))
        default:
            content
                .padding(padding ?? theme.spacing.l)
                .background(theme.colors.surface, in: RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: theme.radius.large, style: .continuous)
                        .stroke(theme.colors.border.opacity(0.6), lineWidth: 0.5)
                )
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension View {
    func openUISurface(_ variant: String?, padding: CGFloat? = nil) -> some View {
        modifier(SurfaceBackground(variant: variant, padding: padding))
    }

    /// A rounded, tinted background for semantic variants.
    func tinted(_ color: Color, cornerRadius: CGFloat, opacity: Double = 0.12) -> some View {
        background(color.opacity(opacity), in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }
}

/// Wraps children onto multiple lines (content-sized items).
@available(iOS 17.0, macOS 14.0, *)
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8
    var alignment: HorizontalAlignment = .leading

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = arrange(subviews: subviews, maxWidth: maxWidth)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + CGFloat(max(0, rows.count - 1)) * verticalSpacing
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x: CGFloat
            switch alignment {
            case .center: x = bounds.minX + (bounds.width - row.width) / 2
            case .trailing: x = bounds.maxX - row.width
            default: x = bounds.minX
            }
            for (index, size) in zip(row.indices, row.sizes) {
                subviews[index].place(at: CGPoint(x: x, y: y + (row.height - size.height) / 2), proposal: ProposedViewSize(size))
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var sizes: [CGSize] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()
        for index in subviews.indices {
            var size = subviews[index].sizeThatFits(.unspecified)
            if size.width > maxWidth {
                size = subviews[index].sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
            }
            let needed = current.indices.isEmpty ? size.width : current.width + horizontalSpacing + size.width
            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
            }
            current.width = current.indices.isEmpty ? size.width : current.width + horizontalSpacing + size.width
            current.indices.append(index)
            current.sizes.append(size)
            current.height = max(current.height, size.height)
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}

/// A responsive grid: as many equal-width columns as fit `minItemWidth`.
@available(iOS 17.0, macOS 14.0, *)
struct ResponsiveGridLayout: Layout {
    let spacing: CGFloat
    let minItemWidth: CGFloat
    let maxColumns: Int

    // The model writes the gap, so one that is negative or not finite is no gap.
    init(spacing: CGFloat = 12, minItemWidth: CGFloat = 150, maxColumns: Int = 4) {
        self.spacing = spacing.isFinite ? max(spacing, 0) : 0
        self.minItemWidth = minItemWidth.isFinite ? max(minItemWidth, 1) : 150
        self.maxColumns = max(maxColumns, 1)
    }

    private func columns(for width: CGFloat, count: Int) -> Int {
        guard width.isFinite, width > 0 else { return max(1, min(count, 2)) }
        let fitting = ((width + spacing) / (minItemWidth + spacing)).rounded(.down)
        return max(1, min(maxColumns, max(count, 1), Int(min(fitting, CGFloat(maxColumns)))))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? (minItemWidth * 2 + spacing)
        let columnCount = columns(for: width, count: subviews.count)
        let itemWidth = (width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        var height: CGFloat = 0
        var index = 0
        var rowCount = 0
        while index < subviews.count {
            let row = subviews[index..<min(index + columnCount, subviews.count)]
            height += row.map { $0.sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }.max() ?? 0
            index += columnCount
            rowCount += 1
        }
        height += CGFloat(max(0, rowCount - 1)) * spacing
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnCount = columns(for: bounds.width, count: subviews.count)
        let itemWidth = (bounds.width - CGFloat(columnCount - 1) * spacing) / CGFloat(columnCount)
        var y = bounds.minY
        var index = 0
        while index < subviews.count {
            let range = index..<min(index + columnCount, subviews.count)
            let rowHeight = range.map { subviews[$0].sizeThatFits(ProposedViewSize(width: itemWidth, height: nil)).height }.max() ?? 0
            for (column, subviewIndex) in range.enumerated() {
                let x = bounds.minX + CGFloat(column) * (itemWidth + spacing)
                subviews[subviewIndex].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: itemWidth, height: rowHeight))
            }
            y += rowHeight + spacing
            index += columnCount
        }
    }
}

/// Flexbox-like container for `Stack` and the standard `Card` (direction, gap, align, justify, wrap).
@available(iOS 17.0, macOS 14.0, *)
struct FlexContainer<Content: View>: View {
    let direction: String?
    let gap: CGFloat
    let align: String?
    let justify: String?
    let wrap: Bool
    /// Children that should share space equally in rows (e.g. cards).
    let flexibleChildren: Bool
    let itemCount: Int
    @ViewBuilder let content: () -> Content

    var body: some View {
        if direction == "row" {
            if wrap {
                if flexibleChildren {
                    ResponsiveGridLayout(spacing: gap, minItemWidth: itemCount > 2 ? 140 : 160).callAsFunction(content)
                } else {
                    FlowLayout(horizontalSpacing: gap, verticalSpacing: gap, alignment: horizontalJustification).callAsFunction(content)
                }
            } else {
                rowStack
            }
        } else {
            VStack(alignment: horizontalAlignment, spacing: gap) {
                content()
                    .frame(maxWidth: align == nil || align == "stretch" ? .infinity : nil, alignment: frameAlignment)
            }
            .frame(maxWidth: .infinity, alignment: frameAlignment)
        }
    }

    @ViewBuilder
    private var rowStack: some View {
        switch justify {
        case "center", "end", "between", "around", "evenly":
            JustifiedRowLayout(justify: justify, gap: gap, alignment: verticalAlignment)
                .callAsFunction(content)
                .frame(maxWidth: .infinity)
        default:
            HStack(alignment: verticalAlignment, spacing: gap) {
                content()
                    .frame(maxWidth: flexibleChildren ? .infinity : nil, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var horizontalAlignment: HorizontalAlignment {
        switch align {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }

    private var horizontalJustification: HorizontalAlignment {
        switch justify {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }

    private var frameAlignment: Alignment {
        switch align {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }

    private var verticalAlignment: VerticalAlignment {
        switch align {
        case "start": return .top
        case "end": return .bottom
        case "baseline": return .firstTextBaseline
        default: return .center
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
struct JustifiedRowLayout: Layout {
    var justify: String?
    var gap: CGFloat
    var alignment: VerticalAlignment = .center

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let sizes = measure(subviews, width: proposal.width)
        let contentWidth = sizes.map(\.width).reduce(0, +) + gap * CGFloat(max(0, sizes.count - 1))
        let width = proposal.width.flatMap { $0.isFinite ? $0 : nil } ?? contentWidth
        return CGSize(width: width, height: rowMetrics(subviews, sizes: sizes).height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let sizes = measure(subviews, width: bounds.width)
        let offsets = Self.offsets(widths: sizes.map(\.width), available: bounds.width, gap: gap, justify: justify)
        let metrics = rowMetrics(subviews, sizes: sizes)
        for index in subviews.indices {
            let size = sizes[index]
            let y: CGFloat
            switch alignment {
            case .top: y = bounds.minY
            case .bottom: y = bounds.maxY - size.height
            case .firstTextBaseline: y = bounds.minY + metrics.baseline - baseline(subviews[index], size: size)
            default: y = bounds.minY + (metrics.height - size.height) / 2
            }
            subviews[index].place(at: CGPoint(x: bounds.minX + offsets[index], y: y), proposal: ProposedViewSize(size))
        }
    }

    // Like a flexbox row's justify-content: the free space left after the items and their gaps
    // goes before, between and after them.
    static func offsets(widths: [CGFloat], available: CGFloat, gap: CGFloat, justify: String?) -> [CGFloat] {
        guard !widths.isEmpty else { return [] }
        let count = CGFloat(widths.count)
        let free = max(0, available - widths.reduce(0, +) - gap * (count - 1))
        let start: CGFloat
        let extra: CGFloat
        switch justify {
        case "center": (start, extra) = (free / 2, 0)
        case "end": (start, extra) = (free, 0)
        case "between": (start, extra) = (0, widths.count > 1 ? free / (count - 1) : 0)
        case "around": (start, extra) = (free / (2 * count), free / count)
        case "evenly": (start, extra) = (free / (count + 1), free / (count + 1))
        default: (start, extra) = (0, 0)
        }
        var offsets: [CGFloat] = []
        var x = start
        for width in widths {
            offsets.append(x)
            x += width + gap + extra
        }
        return offsets
    }

    // Items keep their ideal widths, shrinking in proportion when the row is too narrow for them.
    private func measure(_ subviews: Subviews, width: CGFloat?) -> [CGSize] {
        let ideal = subviews.map { $0.sizeThatFits(.unspecified) }
        guard let width, width.isFinite else { return ideal }
        let available = max(0, width - gap * CGFloat(max(0, subviews.count - 1)))
        let total = ideal.map(\.width).reduce(0, +)
        guard total > available, total > 0 else { return ideal }
        return subviews.indices.map { index in
            subviews[index].sizeThatFits(ProposedViewSize(width: available * ideal[index].width / total, height: nil))
        }
    }

    private func baseline(_ subview: LayoutSubview, size: CGSize) -> CGFloat {
        subview.dimensions(in: ProposedViewSize(size))[VerticalAlignment.firstTextBaseline]
    }

    private func rowMetrics(_ subviews: Subviews, sizes: [CGSize]) -> (height: CGFloat, baseline: CGFloat) {
        guard alignment == .firstTextBaseline else {
            return (sizes.map(\.height).max() ?? 0, 0)
        }
        let baselines = subviews.indices.map { baseline(subviews[$0], size: sizes[$0]) }
        let ascent = baselines.max() ?? 0
        let descent = subviews.indices.map { sizes[$0].height - baselines[$0] }.max() ?? 0
        return (ascent + descent, ascent)
    }
}
