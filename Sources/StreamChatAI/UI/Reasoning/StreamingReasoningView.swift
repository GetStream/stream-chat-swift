//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A model's reasoning (its "thinking"), shown alongside its reply.
///
/// While the model thinks, the reasoning is open under a "Thinking… 7s" header: a panel that
/// grows with the thoughts, up to `maxExpandedHeight`, then keeps the newest in view, revealing
/// new text smoothly as it arrives. When the model is done the view folds into "Thought for
/// 12s" and its summary, unless the reader opened or closed it themselves, and tapping the
/// header opens the whole reasoning again.
///
/// Reasoning can run to tens of kilobytes and grow many times a second, so the view only
/// lays out what changes: the text is split into paragraphs that render lazily, and only the
/// paragraph still being written is laid out again.
///
/// ```swift
/// StreamingReasoningView(text: reasoning, isThinking: answer.isEmpty, duration: 12)
/// ```
public struct StreamingReasoningView: View {
    var text: String
    var isThinking: Bool
    var duration: TimeInterval?
    var summary: String?
    var footnote: String?
    var initiallyExpanded: Bool
    var showsLiveReasoning: Bool
    var maxExpandedHeight: CGFloat
    var font: Font?

    @Injected(\.aiAppearance.colors) private var colors
    @Injected(\.aiAppearance.images) private var images
    @Injected(\.aiAppearance.fonts) private var fonts
    @Injected(\.aiAppearance.tokens.layout) private var layout

    /// What the reader chose by tapping the header. Until they do, the reasoning is open
    /// while the model thinks and folded once it is done.
    @State private var choice: Bool?
    /// Whether the reasoning is open. It changes inside an animation, so the whole layout
    /// around the view glides with it.
    @State private var open: Bool
    /// Whether the panel is in the layout. It stays, at no height, while it folds.
    @State private var mounted: Bool
    /// How long the model had thought when this view saw it stop, for a header whose
    /// finished step does not say.
    @State private var thinkingSince = Date()
    @State private var thoughtFor: TimeInterval?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// How the reasoning folds and opens. Everything the change moves, such as the reply
    /// below the reasoning, moves with it; use it for your own changes that should match.
    public static let foldAnimation = Animation.spring(response: 0.45, dampingFraction: 0.95)

    /// Creates a reasoning view.
    /// - Parameters:
    ///   - text: The reasoning so far. Blank lines separate paragraphs, and inline Markdown
    ///     (bold, italics, code and links) is rendered.
    ///   - isThinking: Whether the model is still thinking. While it is, the header counts the
    ///     seconds and the reasoning streams into view.
    ///   - duration: How long the model has thought, shown as "Thought for 12s" once it is done.
    ///   - summary: A one-line summary shown beside the header once the model is done.
    ///   - footnote: A note under the open reasoning, such as how long it is kept.
    ///   - initiallyExpanded: Whether the reasoning is open once the model is done.
    ///   - showsLiveReasoning: Whether the reasoning is open while the model thinks.
    ///   - maxExpandedHeight: How tall the reasoning grows before it scrolls.
    ///   - font: The font of the reasoning, `AIAppearance.fonts.messagePart` by default. The
    ///     header uses it in a medium weight.
    public init(
        text: String,
        isThinking: Bool,
        duration: TimeInterval? = nil,
        summary: String? = nil,
        footnote: String? = nil,
        initiallyExpanded: Bool = false,
        showsLiveReasoning: Bool = true,
        maxExpandedHeight: CGFloat = 260,
        font: Font? = nil
    ) {
        self.text = text
        self.isThinking = isThinking
        self.duration = duration
        self.summary = summary
        self.footnote = footnote
        self.initiallyExpanded = initiallyExpanded
        self.showsLiveReasoning = showsLiveReasoning
        self.maxExpandedHeight = maxExpandedHeight
        self.font = font
        let initial = Self.opens(isThinking: isThinking, showsLiveReasoning: showsLiveReasoning, initiallyExpanded: initiallyExpanded)
        // Live reasoning joins the layout at no height and unfolds once it appears, rather
        // than pushing everything below it aside in one frame.
        _open = State(initialValue: initial && !isThinking)
        _mounted = State(initialValue: initial)
    }

    var isOpen: Bool { open }

    /// Whether the reasoning is open when the reader has not chosen: while the model thinks
    /// if `showsLiveReasoning`, and once it is done if `initiallyExpanded`.
    static func opens(isThinking: Bool, showsLiveReasoning: Bool, initiallyExpanded: Bool) -> Bool {
        isThinking ? showsLiveReasoning : initiallyExpanded
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            if mounted && !text.isEmpty {
                VStack(alignment: .leading, spacing: layout.spacingXs) {
                    ReasoningPanel(text: text, isLive: isThinking, maxHeight: maxExpandedHeight, color: Color(colors.reasoningText))
                    // Only once the reader opens it: appearing as the reasoning folds by itself
                    // would push the reply down just as it starts.
                    if let footnote, !isThinking, choice == true || initiallyExpanded {
                        Text(footnote)
                            .font(fonts.reasoningFootnote)
                            .foregroundStyle(Color(colors.reasoningFootnote))
                    }
                }
                .padding(.top, layout.spacingXs)
                // Folding shrinks the panel in place rather than removing it, so what sits
                // below glides up with it instead of jumping.
                .frame(height: open ? nil : 0, alignment: .top)
                .clipped()
                .opacity(open ? 1 : 0)
                .accessibilityHidden(!open)
            }
        }
        .font(resolvedFont)
        .padding(.leading, layout.spacingSm)
        .overlay(alignment: .leading) {
            Capsule().fill(Color(isThinking ? colors.reasoningShimmer : colors.reasoningRule)).frame(width: 2)
        }
        .onAppear {
            if mounted && !open && choice == nil { setOpen(true, unfolding: true) }
        }
        .modifier(OnChange(value: isThinking) {
            if isThinking {
                thinkingSince = Date()
            } else {
                thoughtFor = max(duration ?? 0, Date().timeIntervalSince(thinkingSince))
            }
            let opens = choice ?? Self.opens(isThinking: isThinking, showsLiveReasoning: showsLiveReasoning, initiallyExpanded: initiallyExpanded)
            guard !opens else { return setOpen(true) }
            // Folded in its own animated change, after the update that ended the thinking,
            // so the whole layout glides with it.
            DispatchQueue.main.async {
                if choice == nil && !isThinking { setOpen(false) }
            }
        })
    }

    /// How long the reasoning takes to fold once the model stops thinking. A reply that
    /// shows its answer only after this lets the reasoning fold first, then types the
    /// answer below it, rather than the two moving against each other.
    public static let foldDuration: TimeInterval = 0.45

    /// Opens or folds the reasoning in one animated change of the whole layout. An opening
    /// panel first joins the layout at no height, so it unfolds rather than appears.
    private func setOpen(_ value: Bool, unfolding: Bool = false) {
        guard value != open else { return }
        let animation = reduceMotion ? nil : Self.foldAnimation
        if value && (!mounted || unfolding) {
            mounted = true
            DispatchQueue.main.async { withAnimation(animation) { open = true } }
            return
        }
        withAnimation(animation) { open = value }
        if !value {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if !open { mounted = false }
            }
        }
    }

    private var header: some View {
        let title = Self.title(isThinking: isThinking, duration: duration ?? thoughtFor)
        return Button {
            choice = !open
            setOpen(!open)
        } label: {
            HStack(spacing: 6) {
                ThinkingIcon(image: images.reasoning, isActive: isThinking)
                Group {
                    if isThinking {
                        ThinkingTitle(duration: duration)
                    } else {
                        Text(title)
                    }
                }
                .modifier(Shimmer(isActive: isThinking, highlight: Color(colors.reasoningShimmer)))
                .layoutPriority(1)
                if let summary, !isThinking, !isOpen {
                    Text(summary)
                        .fontWeight(.regular)
                        .foregroundStyle(Color(colors.reasoningText).opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                images.reasoningDisclosure
                    .font(.caption2.weight(.semibold))
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
            }
            .font(resolvedFont.weight(.medium))
            .foregroundStyle(Color(colors.reasoningTitle))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, isThinking ? nil : summary].compactMap { $0 }.joined(separator: ". "))
        .accessibilityHint(isOpen ? L10n.Reasoning.hideHint : L10n.Reasoning.showHint)
        .accessibilityAddTraits(.isButton)
    }

    private var resolvedFont: Font {
        font ?? fonts.messagePart
    }

    /// "Thinking…" while the model thinks, then how long it thought.
    static func title(isThinking: Bool, duration: TimeInterval?, locale: Locale = .autoupdatingCurrent) -> String {
        if isThinking { return L10n.Reasoning.thinking }
        guard let duration else { return L10n.Reasoning.thought }
        return L10n.Reasoning.thoughtFor(seconds(max(1, duration), locale: locale))
    }

    /// "Thinking…", then "Thinking… 7s" once a second has passed.
    static func thinkingTitle(elapsed: TimeInterval, locale: Locale = .autoupdatingCurrent) -> String {
        guard elapsed >= 1 else { return L10n.Reasoning.thinking }
        return L10n.Reasoning.thinkingFor(seconds(elapsed, locale: locale))
    }

    private static func seconds(_ duration: TimeInterval, locale: Locale) -> String {
        DurationFormatting.minutesAndSeconds(Int(duration.rounded(.down)), locale: locale)
    }
}
