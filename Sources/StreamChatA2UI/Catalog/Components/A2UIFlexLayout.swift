//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

// Children with a weight, or every child under `justify: stretch`, share the free space in
// proportion to their weights, like CSS `flex-grow`. SwiftUI stacks can only share it equally,
// so those containers use `A2UIFlexLayout` where it is available, and the stacks on iOS 15.
@available(iOS 15.0, macOS 12.0, *)
struct A2UIFlexStack: View {
    let axis: Axis
    let justify: String
    let align: String
    let children: [ResolvedChild]
    let context: ComponentRenderContext

    var body: some View {
        if sharesFreeSpace {
            if #available(iOS 16, macOS 13, tvOS 16, watchOS 9, *) {
                A2UIFlexLayout(axis: axis, justify: justify, align: align, spacing: A2UILayout.spacing) {
                    ForEach(children) { child in
                        context.childView(child)
                            .layoutValue(key: A2UIFlexWeight.self, value: flexWeight(child))
                    }
                }
            } else {
                stack
            }
        } else {
            stack
        }
    }

    @ViewBuilder
    private var stack: some View {
        if axis == .horizontal {
            row
        } else {
            column
        }
    }

    private var sharesFreeSpace: Bool {
        justify == "stretch" || children.contains { ($0.weight ?? 0) > 0 }
    }

    private func flexWeight(_ child: ResolvedChild) -> Double {
        if let weight = child.weight, weight > 0 { return weight }
        return justify == "stretch" ? 1 : 0
    }

    private var spacers: A2UILayout.Spacers {
        A2UILayout.spacersFor(justify: justify, hasWeightedChild: sharesFreeSpace)
    }

    // `align: stretch` gives every child the row's height, so a vertical
    // divider spans it; the row itself stays as tall as its tallest child.
    private var row: some View {
        let stretches = align == "stretch"
        return HStack(alignment: A2UILayout.verticalAlignment(align), spacing: A2UILayout.spacing) {
            A2UISpacers(count: spacers.leading)
            ForEach(Array(children.enumerated()), id: \.element.id) { offset, child in
                WeightedChild(child: child, content: context.childView(child), axis: .horizontal)
                    .frame(maxHeight: stretches ? .infinity : nil, alignment: .top)
                if offset < children.count - 1 { A2UISpacers(count: spacers.between) }
            }
            A2UISpacers(count: spacers.trailing)
        }
        .fixedSize(horizontal: false, vertical: stretches)
    }

    private var column: some View {
        let stretches = align == "stretch"
        return VStack(alignment: A2UILayout.horizontalAlignment(align), spacing: A2UILayout.spacing) {
            A2UISpacers(count: spacers.leading)
            ForEach(Array(children.enumerated()), id: \.element.id) { offset, child in
                WeightedChild(child: child, content: context.childView(child), axis: .vertical)
                    .frame(
                        maxWidth: stretches ? .infinity : nil,
                        alignment: A2UILayout.frameAlignment(align, axis: .vertical)
                    )
                if offset < children.count - 1 { A2UISpacers(count: spacers.between) }
            }
            A2UISpacers(count: spacers.trailing)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UISpacers: View {
    let count: Int

    var body: some View {
        ForEach(0..<count, id: \.self) { _ in
            Spacer(minLength: 0)
        }
    }
}

@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
struct A2UIFlexWeight: LayoutValueKey {
    static let defaultValue: Double = 0
}

// Children without a weight keep their natural length, shrinking in proportion when they don't
// fit. The weighted children share what is left, like Compose's `weight`, or CSS `flex-grow`
// from a zero basis.
@available(iOS 16, macOS 13, tvOS 16, watchOS 9, *)
struct A2UIFlexLayout: Layout {
    let axis: Axis
    let justify: String
    let align: String
    let spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal, subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let arrangement = arrange(ProposedViewSize(bounds.size), subviews)
        for (subview, frame) in zip(subviews, arrangement.frames) {
            subview.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading,
                proposal: ProposedViewSize(frame.size)
            )
        }
    }

    private func arrange(_ proposal: ProposedViewSize, _ subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let availableMain = finite(axis == .horizontal ? proposal.width : proposal.height)
        let availableCross = finite(axis == .horizontal ? proposal.height : proposal.width)
        let weights = subviews.map { $0[A2UIFlexWeight.self] }

        let natural = subviews.enumerated().map { index, subview -> CGFloat in
            if weights[index] > 0, availableMain != nil { return 0 }
            return main(of: subview.sizeThatFits(offer(main: nil, cross: availableCross)))
        }
        let slots = A2UIFlex.slots(natural: natural, weights: weights, available: availableMain, spacing: spacing)
        let sizes = subviews.enumerated().map { index, subview in
            subview.sizeThatFits(offer(main: slots[index], cross: availableCross))
        }
        let lengths = sizes.enumerated().map { index, size in weights[index] > 0 ? slots[index] : main(of: size) }

        let contentMain = lengths.reduce(0, +) + spacing * CGFloat(max(0, subviews.count - 1))
        let mainLength = availableMain ?? contentMain
        let stretches = align == "stretch"
        let tallestCross = sizes.map { cross(of: $0) }.max() ?? 0
        let crossLength = axis == .vertical && stretches ? availableCross ?? tallestCross : tallestCross

        let offsets = A2UIFlex.offsets(lengths: lengths, length: mainLength, justify: justify, spacing: spacing)
        let frames = subviews.indices.map { index -> CGRect in
            let childCross = stretches ? crossLength : cross(of: sizes[index])
            let crossOffset: CGFloat
            switch align {
            case "center": crossOffset = (crossLength - childCross) / 2
            case "end": crossOffset = crossLength - childCross
            default: crossOffset = 0
            }
            return axis == .horizontal
                ? CGRect(x: offsets[index], y: crossOffset, width: lengths[index], height: childCross)
                : CGRect(x: crossOffset, y: offsets[index], width: childCross, height: lengths[index])
        }
        let size = axis == .horizontal
            ? CGSize(width: mainLength, height: crossLength)
            : CGSize(width: crossLength, height: mainLength)
        return (size, frames)
    }

    private func finite(_ value: CGFloat?) -> CGFloat? {
        guard let value, value.isFinite else { return nil }
        return value
    }

    private func offer(main: CGFloat?, cross: CGFloat?) -> ProposedViewSize {
        axis == .horizontal ? ProposedViewSize(width: main, height: cross) : ProposedViewSize(width: cross, height: main)
    }

    private func main(of size: CGSize) -> CGFloat {
        axis == .horizontal ? size.width : size.height
    }

    private func cross(of size: CGSize) -> CGFloat {
        axis == .horizontal ? size.height : size.width
    }
}

@available(iOS 15.0, macOS 12.0, *)
enum A2UIFlex {
    static func slots(natural: [CGFloat], weights: [Double], available: CGFloat?, spacing: CGFloat) -> [CGFloat] {
        guard let available else { return natural }
        let free = max(0, available - spacing * CGFloat(max(0, natural.count - 1)))
        let fixed = zip(natural, weights).filter { $0.1 <= 0 }.map(\.0).reduce(0, +)
        let scale = fixed > free && fixed > 0 ? free / fixed : 1
        let remaining = max(0, free - fixed * scale)
        let totalWeight = weights.filter { $0 > 0 }.reduce(0, +)
        return zip(natural, weights).map { length, weight in
            guard weight > 0 else { return length * scale }
            return totalWeight > 0 ? remaining * CGFloat(weight / totalWeight) : 0
        }
    }

    static func offsets(lengths: [CGFloat], length: CGFloat, justify: String, spacing: CGFloat) -> [CGFloat] {
        let count = CGFloat(lengths.count)
        let free = max(0, length - lengths.reduce(0, +) - spacing * max(0, count - 1))
        var start: CGFloat = 0
        var gap = spacing
        switch justify {
        case "center":
            start = free / 2
        case "end":
            start = free
        case "spaceBetween" where lengths.count > 1:
            gap += free / (count - 1)
        case "spaceAround" where lengths.count > 0:
            start = free / count / 2
            gap += free / count
        case "spaceEvenly":
            start = free / (count + 1)
            gap += free / (count + 1)
        default:
            break
        }
        var offsets: [CGFloat] = []
        var position = start
        for childLength in lengths {
            offsets.append(position)
            position += childLength + gap
        }
        return offsets
    }
}
