//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The composite container components of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum ContainerComponents {
    /// All container components, in catalog order.
    static var all: [ComponentDefinition] {
        [tabs, modal]
    }

    /// A set of tabs, each with a title and a child component.
    static let tabs = ComponentDefinition(
        name: "Tabs",
        description: "A set of tabs, each with a title and child component.",
        properties: [
            "tabs": JsonSchema.array(
                description: "An array of objects, where each object defines a tab with a title and a child component.",
                items: JsonSchema.object(
                    properties: [
                        "title": JsonSchema.dynamicString(description: "The tab title."),
                        "child": JsonSchema.child(description: "The ID of the child component.")
                    ],
                    required: ["title", "child"],
                    additionalProperties: false
                ),
                minItems: 1
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["tabs"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "Tabs",
                "tabs": [
                  {"title": "Details", "child": "details"},
                  {"title": "Reviews", "child": "reviews"}
                ]
              },
              {"id": "details", "component": "Text", "text": "Details"},
              {"id": "reviews", "component": "Text", "text": "Reviews"}
            ]
            """
        ]
    ) { context in
        let items = (Json.array(context.component.property("tabs")) ?? []).compactMap { entry -> A2UITab? in
            guard let map = Json.map(entry), let child = map["child"] as? String else { return nil }
            let title = context.evaluator.string(DynamicValue(map["title"]), in: context.dataContext) ?? ""
            return A2UITab(title: title, childId: child)
        }
        return AnyView(A2UITabsView(tabs: items, context: context))
    }

    /// A dialog opened by a trigger component.
    ///
    /// The trigger is rendered inline; interacting with it presents the content
    /// as a sheet. The trigger's own action, if it has one, still fires, and a
    /// disabled button trigger doesn't open the modal.
    static let modal = ComponentDefinition(
        name: "Modal",
        description: "A dialog that appears over the main content, triggered by a component in the main content.",
        properties: [
            "trigger": JsonSchema.child(
                description: "The ID of the component that opens the modal when interacted with (e.g., a button)."
            ),
            "content": JsonSchema.child(description: "The ID of the component to be displayed inside the modal."),
            "weight": JsonSchema.weight()
        ],
        required: ["trigger", "content"],
        examples: [
            """
            [
              {"id": "root", "component": "Modal", "trigger": "openButton", "content": "details"},
              {
                "id": "openButton",
                "component": "Button",
                "child": "openLabel",
                "action": {"event": {"name": "open_details", "context": {}}}
              },
              {"id": "openLabel", "component": "Text", "text": "Details"},
              {"id": "details", "component": "Text", "text": "More information."}
            ]
            """
        ]
    ) { context in
        let triggerId = context.childId("trigger")
        return AnyView(
            A2UIModalView(
                trigger: context.childView(triggerId),
                content: context.childView(context.childId("content")),
                triggerIsButton: triggerId.flatMap { context.renderer.component($0)?.type } == ButtonComponent.button.name
            )
        )
    }
}

/// One entry of an A2UI `Tabs` component.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UITab: Identifiable {
    let title: String
    let childId: String

    var id: String { childId }
}

/// Renders tab headers and the selected tab's content.
///
/// A custom header is used instead of `TabView` so that tabs compose inside
/// scrollable agent-driven layouts.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UITabsView: View {
    let tabs: [A2UITab]
    let context: ComponentRenderContext

    @State private var selection: String?
    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let selected = selection ?? tabs.first?.id

        return VStack(alignment: .leading, spacing: A2UILayout.spacing) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        Button {
                            selection = tab.id
                        } label: {
                            Text(tab.title)
                                .font(theme.label)
                                .foregroundColor(selected == tab.id ? theme.accent : theme.secondaryText)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    selected == tab.id ? theme.accent.opacity(0.15) : Color.clear
                                )
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected == tab.id ? [.isSelected, .isButton] : .isButton)
                    }
                }
            }
            if let selected, let tab = tabs.first(where: { $0.id == selected }) {
                context.childView(tab.childId)
            }
        }
    }
}

// Buttons in the trigger open the modal from their own action, so VoiceOver, keyboard and pointer
// activation all open it. Any other trigger is made a button for assistive technologies.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIModalView: View {
    let trigger: AnyView
    let content: AnyView
    let triggerIsButton: Bool

    @State private var isPresented = false

    var body: some View {
        interactiveTrigger
            .environment(\.a2uiModalPresenter, A2UIModalPresenter { isPresented = true })
            .sheet(isPresented: $isPresented) {
                sheet.environment(\.a2uiModalPresenter, nil)
            }
    }

    @ViewBuilder
    private var interactiveTrigger: some View {
        if triggerIsButton {
            trigger
        } else {
            trigger
                .contentShape(Rectangle())
                .simultaneousGesture(TapGesture().onEnded { isPresented = true })
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { isPresented = true }
        }
    }

    @ViewBuilder
    private var sheet: some View {
        #if os(iOS) || os(tvOS)
        NavigationView {
            ScrollView {
                content.padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { isPresented = false }
                }
            }
        }
        #else
        VStack(alignment: .trailing) {
            Button("Close") { isPresented = false }
            ScrollView { content }
        }
        .padding()
        .frame(minWidth: 320, minHeight: 240)
        #endif
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct A2UIModalPresenter {
    let present: @MainActor () -> Void
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UIModalPresenterKey: EnvironmentKey {
    static var defaultValue: A2UIModalPresenter? { nil }
}

@available(iOS 15.0, macOS 12.0, *)
extension EnvironmentValues {
    var a2uiModalPresenter: A2UIModalPresenter? {
        get { self[A2UIModalPresenterKey.self] }
        set { self[A2UIModalPresenterKey.self] = newValue }
    }
}
