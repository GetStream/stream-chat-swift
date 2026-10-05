//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

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
    var font: Font
    var colors: Colors.Reasoning

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
    ///   - font: The font of the reasoning. The header uses it in a medium weight.
    ///   - colors: The palette. The view uses its `reasoning` colors.
    public init(
        text: String,
        isThinking: Bool,
        duration: TimeInterval? = nil,
        summary: String? = nil,
        footnote: String? = nil,
        initiallyExpanded: Bool = false,
        showsLiveReasoning: Bool = true,
        maxExpandedHeight: CGFloat = 260,
        font: Font = .subheadline,
        colors: Colors = Colors()
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
        self.colors = colors.reasoning
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
                VStack(alignment: .leading, spacing: 8) {
                    ReasoningPanel(text: text, isLive: isThinking, maxHeight: maxExpandedHeight, color: colors.text)
                    // Only once the reader opens it: appearing as the reasoning folds by itself
                    // would push the reply down just as it starts.
                    if let footnote, !isThinking, choice == true || initiallyExpanded {
                        Text(footnote)
                            .font(.caption2)
                            .foregroundStyle(colors.footnote)
                    }
                }
                .padding(.top, 8)
                // Folding shrinks the panel in place rather than removing it, so what sits
                // below glides up with it instead of jumping.
                .frame(height: open ? nil : 0, alignment: .top)
                .clipped()
                .opacity(open ? 1 : 0)
                .accessibilityHidden(!open)
            }
        }
        .font(font)
        .padding(.leading, 12)
        .overlay(alignment: .leading) {
            Capsule().fill(isThinking ? colors.shimmer : colors.rule).frame(width: 2)
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
                ThinkingIcon(isActive: isThinking)
                Group {
                    if isThinking {
                        ThinkingTitle(duration: duration)
                    } else {
                        Text(title)
                    }
                }
                .modifier(Shimmer(isActive: isThinking, highlight: colors.shimmer))
                .layoutPriority(1)
                if let summary, !isThinking, !isOpen {
                    Text(summary)
                        .fontWeight(.regular)
                        .foregroundStyle(colors.text.opacity(0.8))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .rotationEffect(.degrees(isOpen ? 90 : 0))
            }
            .font(font.weight(.medium))
            .foregroundStyle(colors.title)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([title, isThinking ? nil : summary].compactMap { $0 }.joined(separator: ". "))
        .accessibilityHint(isOpen ? L10n.Reasoning.hideHint : L10n.Reasoning.showHint)
        .accessibilityAddTraits(.isButton)
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

/// The header while the model thinks, counting the seconds. A view opened midway counts
/// from how long the model had already thought.
struct ThinkingTitle: View {
    var duration: TimeInterval?
    @State private var appeared = Date()

    var body: some View {
        TimelineView(.periodic(from: appeared, by: 1)) { context in
            Text(StreamingReasoningView.thinkingTitle(elapsed: max(duration ?? 0, context.date.timeIntervalSince(appeared))))
                .monospacedDigit()
        }
    }
}

/// The brain, pulsing while the model thinks (on systems that animate symbols).
struct ThinkingIcon: View {
    var isActive: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if #available(iOS 17.0, *) {
            Image(systemName: "brain")
                .symbolEffect(.pulse, options: .repeating, isActive: isActive && !reduceMotion)
        } else {
            Image(systemName: "brain")
        }
    }
}

/// The reasoning, one paragraph at a time. It grows with the text up to `maxHeight`, then
/// scrolls, fading at the top so it reads as continuing above. While the reasoning is live,
/// new text is revealed smoothly and the newest stays in view unless the reader scrolls up.
struct ReasoningPanel: View {
    let text: String
    let isLive: Bool
    let maxHeight: CGFloat
    let color: Color

    @StateObject private var reveal = TextReveal()
    @State private var contentHeight: CGFloat = 0
    @State private var following = true
    private let bottom = "reasoning.bottom"

    var body: some View {
        let overflowing = contentHeight > maxHeight
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(ReasoningParagraph.split(reveal.shown)) { paragraph in
                        ReasoningParagraphView(text: paragraph.text, color: color)
                            .equatable()
                    }
                    Color.clear.frame(height: 1).id(bottom)
                }
                .background {
                    GeometryReader { geometry in
                        Color.clear.preference(key: ReasoningHeightKey.self, value: geometry.size.height)
                    }
                }
            }
            .frame(height: min(max(contentHeight, 1), maxHeight))
            .mask(
                LinearGradient(
                    stops: [.init(color: overflowing ? .clear : .black, location: 0), .init(color: .black, location: 0.14)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .onPreferenceChange(ReasoningHeightKey.self) { contentHeight = $0 }
            .modifier(FollowsReader(following: $following))
            .onAppear {
                reveal.update(text, animated: false)
                if isLive { proxy.scrollTo(bottom, anchor: .bottom) }
            }
            .modifier(OnChange(value: text) {
                reveal.update(text, animated: isLive)
            })
            // The last thoughts can land as the model stops thinking, so new text keeps a
            // reader who is following at the end either way. A finished trace opens at its start.
            .modifier(OnChange(value: reveal.shown) {
                if following { proxy.scrollTo(bottom, anchor: .bottom) }
            })
        }
    }
}

/// Reveals new text a little at a time, so thoughts that arrive in bursts read as a steady
/// stream. Text that does not carry on from what is shown replaces it at once.
@MainActor
final class TextReveal: ObservableObject {
    @Published private(set) var shown = ""
    private var target = ""
    private var pending: [Character] = []
    private var timer: Timer?

    func update(_ text: String, animated: Bool) {
        guard animated, text.utf8.count > target.utf8.count, text.utf8.starts(with: target.utf8) else {
            if text != shown || !pending.isEmpty { show(text) }
            return
        }
        pending.append(contentsOf: String(decoding: text.utf8.dropFirst(target.utf8.count), as: UTF8.self))
        target = text
        guard timer == nil else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30, repeats: true) { [weak self] timer in
            guard let self else { return timer.invalidate() }
            MainActor.assumeIsolated {
                self.tick()
            }
        }
    }

    /// Shows a fifth of the backlog at a time: new thoughts arrive about that often.
    func tick() {
        guard !pending.isEmpty else {
            timer?.invalidate()
            timer = nil
            return
        }
        let count = max(1, pending.count / 6)
        shown.append(contentsOf: pending.prefix(count))
        pending.removeFirst(count)
    }

    private func show(_ text: String) {
        timer?.invalidate()
        timer = nil
        pending = []
        target = text
        shown = text
    }
}

/// One paragraph of reasoning. It is equatable so that only the paragraph still being
/// written is rendered again as the reasoning grows.
struct ReasoningParagraphView: View, Equatable {
    let text: String
    let color: Color

    var body: some View {
        Text(ReasoningParagraph.attributed(text))
            .foregroundStyle(color)
            .lineSpacing(3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .textSelection(.enabled)
    }
}

struct ReasoningParagraph: Identifiable, Equatable {
    let id: Int
    let text: String

    /// Splits reasoning at blank lines. Reasoning only grows at its end, so a paragraph's
    /// position is a stable identity.
    static func split(_ text: String) -> [ReasoningParagraph] {
        text.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .enumerated()
            .map { ReasoningParagraph(id: $0.offset, text: $0.element) }
    }

    /// Inline Markdown as reasoning models write it: bold, italics, code and links. A
    /// heading reads as a bold line, since a paragraph of thinking has no document to
    /// structure.
    static func attributed(_ paragraph: String) -> AttributedString {
        let source = paragraph
            .split(separator: "\n", omittingEmptySubsequences: false)
            .map { line -> String in
                let trimmed = line.drop { $0 == " " }
                guard trimmed.hasPrefix("#") else { return String(line) }
                let heading = trimmed.drop { $0 == "#" }.trimmingCharacters(in: .whitespaces)
                return heading.isEmpty ? String(line) : "**\(heading)**"
            }
            .joined(separator: "\n")
        let options = AttributedString.MarkdownParsingOptions(
            interpretedSyntax: .inlineOnlyPreservingWhitespace,
            failurePolicy: .returnPartiallyParsedIfPossible
        )
        return (try? AttributedString(markdown: source, options: options)) ?? AttributedString(paragraph)
    }
}

private struct ReasoningHeightKey: PreferenceKey {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

/// Stops following new text while the reader has scrolled up, and resumes once they are
/// back at the end. Only the reader's own scrolling counts: the panel growing, or the
/// list around it moving, never stops it following. Earlier systems always follow.
private struct FollowsReader: ViewModifier {
    @Binding var following: Bool

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.onScrollPhaseChange { old, phase, context in
                guard phase == .idle, old == .interacting || old == .decelerating else { return }
                let geometry = context.geometry
                following = geometry.contentOffset.y + geometry.containerSize.height >= geometry.contentSize.height - 24
            }
        } else {
            content
        }
    }
}

private struct OnChange<Value: Equatable>: ViewModifier {
    let value: Value
    let action: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 17.0, *) {
            content.onChange(of: value) { action() }
        } else {
            content.onChange(of: value) { _ in action() }
        }
    }
}

/// A highlight sweeping across the content while something is in progress. It stays
/// still when Reduce Motion is on.
struct Shimmer: ViewModifier {
    let isActive: Bool
    let highlight: Color

    @State private var moving = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if isActive && !reduceMotion {
            content
                .overlay {
                    GeometryReader { geometry in
                        let width = geometry.size.width
                        LinearGradient(colors: [.clear, highlight, .clear], startPoint: .leading, endPoint: .trailing)
                            .frame(width: width * 0.6)
                            .offset(x: moving ? width : -width * 0.6)
                            .animation(.linear(duration: 1.4).repeatForever(autoreverses: false), value: moving)
                    }
                    .mask(content)
                    .allowsHitTesting(false)
                }
                .onAppear { moving = true }
                .onDisappear { moving = false }
        } else {
            content
        }
    }
}
