//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The button component of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum ButtonComponent {
    /// All button components, in catalog order.
    static var all: [ComponentDefinition] {
        [button]
    }

    /// A button that dispatches an action when tapped.
    ///
    /// When the button declares `checks`, it disables itself while any check
    /// fails and shows the first failure message, as required by the
    /// specification's button validation behaviour.
    static let button = ComponentDefinition(
        name: "Button",
        description: "A clickable button that dispatches an action. Supports 'primary' and 'borderless' variants.",
        properties: [
            "child": JsonSchema.child(
                description: "The ID of the child component. Use a 'Text' component for a labeled button. "
                    + "Only use an 'Icon' if the requirements explicitly ask for an icon-only button."
            ),
            "variant": JsonSchema.string(
                description: "A hint for the button style. 'primary' indicates the main call to action; "
                    + "'borderless' renders the child like a link.",
                enumValues: ["default", "primary", "borderless"],
                defaultValue: "default"
            ),
            "action": JsonSchema.action(),
            "checks": JsonSchema.array(
                description: "Checks that must pass for the button to be enabled.",
                items: JsonSchema.commonType("CheckRule")
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["child", "action"],
        examples: [
            """
            [
              {
                "id": "root",
                "component": "Button",
                "child": "label",
                "variant": "primary",
                "action": {"event": {"name": "submit", "context": {}}}
              },
              {"id": "label", "component": "Text", "text": "Submit"}
            ]
            """
        ]
    ) { context in
        AnyView(A2UIButtonView(context: context))
    }

    // A modal's trigger opens the modal in place of telling the agent, though a call it makes still
    // runs. Any other button, such as one inside a trigger that isn't a button, acts as usual.
    @MainActor
    static func activate(_ context: ComponentRenderContext, in modalPresenter: A2UIModalPresenter?) {
        guard let modalPresenter, modalPresenter.triggerId == context.id else {
            context.performAction()
            return
        }
        modalPresenter.present()
        if case .functionCall = context.action {
            context.performAction()
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
private struct A2UIButtonView: View {
    let context: ComponentRenderContext

    @Environment(\.a2uiModalPresenter) private var modalPresenter
    @Environment(\.a2uiTheme) private var theme

    var body: some View {
        let failures = context.failingChecks
        let isDisabled = failures.contains { $0.severity == .error }

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
            Button {
                ButtonComponent.activate(context, in: modalPresenter)
            } label: {
                context.childView(context.childId())
                    .modifier(A2UIButtonLabelStyle(variant: context.option("variant", default: "default")))
            }
            .buttonStyle(.plain)
            .disabled(isDisabled)
            .opacity(isDisabled ? 0.5 : 1)
            ValidationMessages(results: failures)
        }
    }
}

/// Applies the visual style of an A2UI button variant.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIButtonLabelStyle: ViewModifier {
    let variant: String

    @Environment(\.a2uiTheme) private var theme

    // Borderless buttons are as tall as the others, so a row of them lines up, but sit at the
    // edge of their container like a link.
    func body(content: Content) -> some View {
        let shape = A2UIRoundedShape(cornerRadius: theme.buttonCornerRadius)
        content
            .modifier(A2UIButtonTitleWeight())
            .padding(.horizontal, variant == "borderless" ? 0 : theme.buttonHorizontalPadding)
            .padding(.vertical, theme.buttonVerticalPadding)
            .foregroundColor(foreground)
            .background(background, in: shape)
            .overlay {
                if variant != "primary" && variant != "borderless" {
                    shape.strokeBorder(theme.border, lineWidth: 1)
                }
            }
            .contentShape(shape)
    }

    private var foreground: Color {
        switch variant {
        case "primary": return theme.onAccent
        case "borderless": return theme.accent
        default: return theme.text
        }
    }

    private var background: Color {
        switch variant {
        case "primary": return theme.accent
        case "borderless": return .clear
        default: return theme.subtleSurface
        }
    }
}

// A button's title is semibold, whatever font its text has.
@available(iOS 15.0, macOS 12.0, *)
private struct A2UIButtonTitleWeight: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 16.0, macOS 13.0, *) {
            content.fontWeight(.semibold)
        } else {
            content
        }
    }
}
