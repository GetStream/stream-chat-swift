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

/// An async image with a neutral placeholder and a failure state.
@available(iOS 17.0, macOS 14.0, *)
struct RemoteImage: View {
    let url: String?
    var contentMode: ContentMode = .fill
    var alt: String?
    @Environment(\.openUITheme) private var theme

    var body: some View {
        if let url, let resolved = URL(string: url), resolved.scheme?.hasPrefix("http") == true {
            AsyncImage(url: resolved, transaction: Transaction(animation: .easeInOut(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().aspectRatio(contentMode: contentMode)
                case .failure:
                    placeholder(systemImage: "photo")
                default:
                    placeholder(systemImage: nil)
                }
            }
            .accessibilityLabel(Text(alt ?? ""))
        } else {
            placeholder(systemImage: "photo")
        }
    }

    private func placeholder(systemImage: String?) -> some View {
        ZStack {
            theme.colors.sunkenSurface
            if let systemImage {
                VStack(spacing: 4) {
                    Image(systemName: systemImage)
                        .font(.title3)
                    if let alt, !alt.isEmpty {
                        Text(alt)
                            .font(theme.fonts.caption)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                    }
                }
                .foregroundStyle(theme.colors.textTertiary)
                .padding(8)
            } else {
                ProgressView()
            }
        }
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension RemoteImage {
    /// Fills a full-width box of the given height without letting the image's size affect layout.
    func filling(height: CGFloat, cornerRadius: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay { self }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Fills a full-width box with the given aspect ratio.
    func filling(aspectRatio: CGFloat, cornerRadius: CGFloat) -> some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .aspectRatio(aspectRatio, contentMode: .fit)
            .overlay { self }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
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
    var spacing: CGFloat = 12
    var minItemWidth: CGFloat = 150
    var maxColumns: Int = 4

    private func columns(for width: CGFloat, count: Int) -> Int {
        guard width.isFinite, width > 0 else { return max(1, min(count, 2)) }
        let fitting = Int((width + spacing) / (minItemWidth + spacing))
        return max(1, min(maxColumns, min(fitting, max(count, 1))))
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
            HStack(alignment: verticalAlignment, spacing: justify == "between" || justify == "around" || justify == "evenly" ? 0 : gap) {
                if justify == "center" || justify == "end" || justify == "around" || justify == "evenly" { Spacer(minLength: 0) }
                content()
                if justify == "center" || justify == "around" || justify == "evenly" { Spacer(minLength: 0) }
            }
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
