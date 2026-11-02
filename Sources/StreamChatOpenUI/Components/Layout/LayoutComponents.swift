//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// Item props shared by `TabItem`, `AccordionItem` and `SectionItem`.
@available(iOS 17.0, macOS 14.0, *)
private struct ContainerItem {
    let value: String
    let trigger: String
    let content: OpenUIValue

    init?(_ element: ElementNode, index: Int, requireValue: Bool = true) {
        let props = ComponentProps(element.props)
        guard let value = props.text("value") ?? (requireValue ? nil : "\(index)") else { return nil }
        self.value = value
        self.trigger = props.text("trigger") ?? ""
        self.content = element.props["content"] ?? .array([])
    }

    /// A cheap size measure used to follow content as it streams in.
    var contentSize: Int {
        OpenUIJSON.stringify(content.plainJSON).utf8.count
    }
}

// MARK: - Tabs

/// `Tabs(items)` with `TabItem(value, trigger, content)`.
@available(iOS 17.0, macOS 14.0, *)
struct TabsView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var selection: String?
    @State private var userInteracted = false
    @State private var previousSizes: [String: Int] = [:]

    private var items: [ContainerItem] {
        context.props.elements("items").enumerated().compactMap { ContainerItem($1, index: $0) }
    }

    var body: some View {
        let items = self.items
        if !items.isEmpty {
            let active = selection.flatMap { value in items.first { $0.value == value }?.value } ?? items[0].value
            VStack(alignment: .leading, spacing: theme.spacing.m) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.spacing.xs) {
                        ForEach(items, id: \.value) { item in
                            Button {
                                userInteracted = true
                                withAnimation(.snappy(duration: 0.2)) { selection = item.value }
                            } label: {
                                Text(item.trigger)
                                    .font(theme.fonts.bodySmall.weight(.semibold))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .foregroundStyle(item.value == active ? theme.colors.textPrimary : theme.colors.textSecondary)
                                    .background {
                                        if item.value == active {
                                            Capsule().fill(theme.colors.surface).shadow(color: .black.opacity(0.08), radius: 2, y: 1)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(3)
                    .background(theme.colors.sunkenSurface, in: Capsule())
                }
                if let current = items.first(where: { $0.value == active }) {
                    VStack(alignment: .leading, spacing: theme.spacing.m) {
                        context.render(current.content)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(current.value)
                    .transition(.opacity)
                }
            }
            .onChange(of: items.map(\.contentSize)) { _, _ in followStreamingContent(items) }
            .onAppear { followStreamingContent(items) }
        }
    }

    /// While the user hasn't picked a tab, switch to the tab whose content is growing.
    private func followStreamingContent(_ items: [ContainerItem]) {
        guard !userInteracted else { return }
        var candidate: String?
        var sizes: [String: Int] = [:]
        for item in items {
            let size = item.contentSize
            if size > (previousSizes[item.value] ?? 0) { candidate = item.value }
            sizes[item.value] = size
        }
        previousSizes = sizes
        if context.isStreaming, let candidate, candidate != selection {
            selection = candidate
        } else if selection == nil {
            selection = items.first?.value
        }
    }
}

// MARK: - Accordion

/// `Accordion(items)` with `AccordionItem(value, trigger, content)` — one section open at a time.
@available(iOS 17.0, macOS 14.0, *)
struct AccordionView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var openItem: String?
    @State private var userInteracted = false
    @State private var previousCount = 0

    var body: some View {
        let items = context.props.elements("items").enumerated().compactMap { ContainerItem($1, index: $0) }
        if !items.isEmpty {
            VStack(spacing: 0) {
                ForEach(Array(items.enumerated()), id: \.element.value) { index, item in
                    DisclosureRow(
                        title: item.trigger,
                        isExpanded: Binding(
                            get: { openItem == item.value },
                            set: { expanded in
                                userInteracted = true
                                withAnimation(.snappy(duration: 0.25)) { openItem = expanded ? item.value : nil }
                            }
                        )
                    ) {
                        context.render(item.content)
                    }
                    if index < items.count - 1 { Divider() }
                }
            }
            .onChange(of: items.count) { _, count in autoOpen(items, count: count) }
            .onAppear { autoOpen(items, count: items.count) }
        }
    }

    /// Auto-opens the newest item while it streams in (until the user interacts).
    private func autoOpen(_ items: [ContainerItem], count: Int) {
        defer { previousCount = count }
        guard !userInteracted, count > previousCount, let newest = items.last else { return }
        openItem = newest.value
    }
}

/// A disclosure row with a chevron header.
@available(iOS 17.0, macOS 14.0, *)
struct DisclosureRow<Content: View>: View {
    let title: String
    @Binding var isExpanded: Bool
    var font: Font?
    @ViewBuilder let content: () -> Content
    @Environment(\.openUITheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                isExpanded.toggle()
            } label: {
                HStack {
                    Text(InlineMarkdown.attributed(title))
                        .font(font ?? theme.fonts.bodySmall.weight(.semibold))
                        .foregroundStyle(theme.colors.textPrimary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: theme.spacing.s)
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.colors.textSecondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, theme.spacing.m)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            .accessibilityValue(Text(isExpanded ? L10n.Disclosure.expanded : L10n.Disclosure.collapsed))
            if isExpanded {
                VStack(alignment: .leading, spacing: theme.spacing.m) {
                    content()
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, theme.spacing.m)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .clipped()
    }
}

// MARK: - Sections

/// `SectionBlock(sections, isFoldable?)` with `SectionItem(value, trigger, content)`.
@available(iOS 17.0, macOS 14.0, *)
struct SectionBlockView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var openItems: Set<String> = []
    @State private var userInteracted = false
    @State private var previousCount = 0
    @State private var wasStreaming = false

    var body: some View {
        let sections = context.props.elements("sections").enumerated().compactMap { ContainerItem($1, index: $0, requireValue: false) }
        let foldable = context.props.bool("isFoldable") ?? true
        if foldable {
            VStack(spacing: 0) {
                ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                    DisclosureRow(
                        title: section.trigger,
                        isExpanded: Binding(
                            get: { openItems.contains(section.value) },
                            set: { expanded in
                                userInteracted = true
                                withAnimation(.snappy(duration: 0.25)) {
                                    if expanded { openItems.insert(section.value) } else { openItems.remove(section.value) }
                                }
                            }
                        ),
                        font: theme.fonts.heading
                    ) {
                        context.render(section.content)
                    }
                    if index < sections.count - 1 { Divider() }
                }
            }
            .onChange(of: sections.count) { _, _ in updateOpenSections(sections) }
            .onChange(of: context.isStreaming) { _, streaming in streamingChanged(streaming, sections) }
            .onAppear {
                wasStreaming = context.isStreaming
                updateOpenSections(sections)
            }
        } else {
            VStack(alignment: .leading, spacing: theme.spacing.l) {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: theme.spacing.s) {
                        Text(InlineMarkdown.attributed(section.trigger))
                            .font(theme.fonts.heading)
                            .foregroundStyle(theme.colors.textPrimary)
                            .accessibilityAddTraits(.isHeader)
                        context.render(section.content)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func updateOpenSections(_ sections: [ContainerItem]) {
        defer { previousCount = sections.count }
        guard !sections.isEmpty else { return }
        if context.isStreaming, sections.count > previousCount, !userInteracted, let last = sections.last {
            openItems.insert(last.value)
        } else if openItems.isEmpty, let first = sections.first {
            openItems = [first.value]
        }
    }

    /// When streaming ends, collapse back to the first section (unless the user interacted).
    private func streamingChanged(_ streaming: Bool, _ sections: [ContainerItem]) {
        if wasStreaming, !streaming, !userInteracted, let first = sections.first {
            withAnimation { openItems = [first.value] }
        }
        wasStreaming = streaming
    }
}

// MARK: - Steps

/// `Steps(items)` with `StepsItem(title, details)`.
@available(iOS 17.0, macOS 14.0, *)
struct StepsView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let items = context.props.elements("items")
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                let props = ComponentProps(item.props)
                HStack(alignment: .top, spacing: theme.spacing.m) {
                    VStack(spacing: 0) {
                        Text("\(index + 1)")
                            .font(.caption.weight(.bold))
                            .monospacedDigit()
                            .foregroundStyle(theme.colors.onAccent)
                            .frame(width: 24, height: 24)
                            .background(theme.colors.accent, in: Circle())
                        if index < items.count - 1 {
                            Rectangle()
                                .fill(theme.colors.border)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                                .padding(.vertical, 4)
                        }
                    }
                    VStack(alignment: .leading, spacing: theme.spacing.xs) {
                        Text(InlineMarkdown.attributed(props.text("title") ?? ""))
                            .font(theme.fonts.bodySmall.weight(.semibold))
                            .foregroundStyle(theme.colors.textPrimary)
                        if let details = props["details"] {
                            if let text = details.stringValue {
                                MarkdownView(text, font: theme.fonts.bodySmall, foreground: theme.colors.textSecondary)
                            } else {
                                context.render(details)
                            }
                        }
                    }
                    .padding(.bottom, index < items.count - 1 ? theme.spacing.l : 0)
                    Spacer(minLength: 0)
                }
                .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Carousel

/// `Carousel(children, variant?)` — horizontally paged slides.
@available(iOS 17.0, macOS 14.0, *)
struct CarouselView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme
    @State private var position: Int? = 0

    var body: some View {
        let slides = context.props.array("children")
        let variant = context.props.string("variant") ?? "card"
        if !slides.isEmpty {
            VStack(spacing: theme.spacing.s) {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(alignment: .top, spacing: theme.spacing.m) {
                        ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                            VStack(alignment: .leading, spacing: theme.spacing.s) {
                                context.render(slide)
                            }
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                            .openUISurface(variant == "sunk" ? "sunk" : "card", padding: theme.spacing.m)
                            .containerRelativeFrame(.horizontal, count: 1, span: 1, spacing: theme.spacing.m)
                            .id(index)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $position)
                if slides.count > 1 {
                    HStack(spacing: theme.spacing.m) {
                        pagerButton("chevron.left", disabled: (position ?? 0) == 0) { position = max(0, (position ?? 0) - 1) }
                        HStack(spacing: 6) {
                            ForEach(0..<slides.count, id: \.self) { index in
                                Circle()
                                    .fill(index == (position ?? 0) ? theme.colors.accent : theme.colors.border)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        pagerButton("chevron.right", disabled: (position ?? 0) >= slides.count - 1) { position = min(slides.count - 1, (position ?? 0) + 1) }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func pagerButton(_ systemName: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation { action() }
        } label: {
            Image(systemName: systemName).font(.caption.weight(.semibold))
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .controlSize(.small)
        .disabled(disabled)
    }
}

// MARK: - Modal

/// `Modal(title, open, children, size?)` — `open` is a `$boolean` binding.
@available(iOS 17.0, macOS 14.0, *)
struct ModalView: View {
    let context: ComponentContext
    @Environment(\.openUITheme) private var theme

    var body: some View {
        let field = context.runtime.stateField(name: "open", binding: context.props["open"], formName: nil)
        let isOpen = field.value == .bool(true) || field.value == .string("true")
        Color.clear
            .frame(height: 0)
            .sheet(isPresented: Binding(get: { isOpen }, set: { presented in if !presented { field.set(.bool(false)) } })) {
                NavigationStack {
                    ScrollView {
                        VStack(alignment: .leading, spacing: theme.spacing.m) {
                            context.render(prop: "children")
                        }
                        .padding()
                    }
                    .navigationTitle(context.props.text("title") ?? "")
                    #if os(iOS)
                        .navigationBarTitleDisplayMode(.inline)
                    #endif
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button {
                                    field.set(.bool(false))
                                } label: {
                                    Image(systemName: "xmark")
                                }
                                .accessibilityLabel(Text(L10n.Modal.close))
                            }
                        }
                }
                .environment(context.runtime)
                .presentationDetents(context.props.string("size") == "sm" ? [.medium, .large] : [.large])
            }
    }
}
