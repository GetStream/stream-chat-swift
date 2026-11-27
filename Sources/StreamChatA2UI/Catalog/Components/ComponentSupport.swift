//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Shared layout and styling helpers for the basic catalog components.
@available(iOS 15.0, macOS 12.0, *)
enum A2UILayout {
    /// Maps an A2UI cross-axis alignment onto a SwiftUI horizontal alignment.
    static func horizontalAlignment(_ align: String) -> HorizontalAlignment {
        switch align {
        case "center": return .center
        case "end": return .trailing
        default: return .leading
        }
    }

    /// Maps an A2UI cross-axis alignment onto a SwiftUI vertical alignment.
    static func verticalAlignment(_ align: String) -> VerticalAlignment {
        switch align {
        case "center": return .center
        case "end": return .bottom
        default: return .top
        }
    }

    /// Maps an A2UI cross-axis alignment onto a SwiftUI frame alignment.
    static func frameAlignment(_ align: String, axis: Axis) -> Alignment {
        switch axis {
        case .horizontal:
            switch align {
            case "center": return .center
            case "end": return .bottom
            default: return .top
            }
        case .vertical:
            switch align {
            case "center": return .center
            case "end": return .trailing
            default: return .leading
            }
        }
    }

    /// How many equal spacers go before, between and after the children of a stack.
    struct Spacers: Equatable {
        let leading: Int
        let between: Int
        let trailing: Int
    }

    // Equal spacers share the free space evenly, so `spaceAround` puts two between children for
    // half-size gaps at the edges. Weighted children absorb the free space, like `flex-grow`.
    static func spacersFor(justify: String, hasWeightedChild: Bool) -> Spacers {
        guard !hasWeightedChild else { return Spacers(leading: 0, between: 0, trailing: 0) }
        switch justify {
        case "center": return Spacers(leading: 1, between: 0, trailing: 1)
        case "end": return Spacers(leading: 1, between: 0, trailing: 0)
        case "spaceBetween": return Spacers(leading: 0, between: 1, trailing: 0)
        case "spaceAround": return Spacers(leading: 1, between: 2, trailing: 1)
        case "spaceEvenly": return Spacers(leading: 1, between: 1, trailing: 1)
        default: return Spacers(leading: 0, between: 0, trailing: 1)
        }
    }
}

// On iOS 15, where `A2UIFlexLayout` isn't available. A weighted child gets a lower layout priority
// than its siblings, or a weighted label starves a short sibling such as a price into zero width.
// Several weighted children share the remaining space equally.
@available(iOS 15.0, macOS 12.0, *)
struct WeightedChild: View {
    let child: ResolvedChild
    let content: AnyView
    let axis: Axis

    var body: some View {
        if let weight = child.weight, weight > 0 {
            content
                .frame(
                    maxWidth: axis == .horizontal ? .infinity : nil,
                    maxHeight: axis == .vertical ? .infinity : nil,
                    alignment: axis == .horizontal ? .leading : .top
                )
                .layoutPriority(-1)
        } else {
            content
        }
    }
}

/// Displays the failing checks of an input component.
@available(iOS 15.0, macOS 12.0, *)
struct ValidationMessages: View {
    let results: [ValidationResult]

    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        if results.isEmpty {
            EmptyView()
        } else {
            VStack(alignment: .leading, spacing: theme.spacing.xxs) {
                ForEach(Array(results.enumerated()), id: \.offset) { _, result in
                    if let message = result.message ?? result.code {
                        Text(message)
                            .font(theme.caption)
                            .foregroundColor(color(for: result.severity))
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func color(for severity: ValidationResult.Severity) -> Color {
        switch severity {
        case .error: return theme.error
        case .warning: return theme.warning
        case .info: return theme.secondaryText
        }
    }
}

// A rounded rectangle that is a capsule once its radius reaches half its height: a continuous
// corner larger than that leaves points at the ends, and design systems give fully rounded
// buttons a radius such as 9999.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIRoundedShape: InsettableShape {
    let cornerRadius: CGFloat
    var inset: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let rect = rect.insetBy(dx: inset, dy: inset)
        let radius = max(cornerRadius - inset, 0)
        if radius * 2 >= min(rect.width, rect.height) {
            return Capsule(style: .continuous).path(in: rect)
        }
        return RoundedRectangle(cornerRadius: radius, style: .continuous).path(in: rect)
    }

    func inset(by amount: CGFloat) -> A2UIRoundedShape {
        var shape = self
        shape.inset += amount
        return shape
    }
}

// Lays its children out in rows as wide as each wants, starting a new row when the next doesn't
// fit, the way chips wrap. A child wider than a row is given the row's width.
@available(iOS 16.0, macOS 13.0, *)
struct A2UIFlowLayout: Layout {
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(subviews, width: proposal.width).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let frames = arrange(subviews, width: bounds.width).frames
        for (subview, frame) in zip(subviews, frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(_ subviews: Subviews, width: CGFloat?) -> (frames: [CGRect], size: CGSize) {
        let available = width.flatMap { $0.isFinite ? $0 : nil } ?? .greatestFiniteMagnitude
        var frames: [CGRect] = []
        var origin = CGPoint.zero
        var rowHeight: CGFloat = 0
        var widest: CGFloat = 0
        for subview in subviews {
            var size = subview.sizeThatFits(.unspecified)
            if size.width > available {
                size = subview.sizeThatFits(ProposedViewSize(width: available, height: nil))
            }
            if origin.x > 0, origin.x + size.width > available {
                origin = CGPoint(x: 0, y: origin.y + rowHeight + spacing)
                rowHeight = 0
            }
            frames.append(CGRect(origin: origin, size: size))
            widest = max(widest, origin.x + size.width)
            origin.x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return (frames, CGSize(width: widest, height: frames.isEmpty ? 0 : origin.y + rowHeight))
    }
}
