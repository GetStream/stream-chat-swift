//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
import SwiftUI

/// A view of the app's that the agent can place in a reply's generated UI: its description, and
/// how it looks for the arguments the agent wrote.
///
/// Every format places it by name, so one component works whichever format the agent writes.
/// Its arguments decode into a type of its own, with snake_case keys and dates as a day or a
/// moment. A component can load data of its own, such as the person's calendar, which then
/// never reaches the agent.
///
/// ```swift
/// struct PlaceCardComponent: AIUIComponent {
///     struct Arguments: Decodable {
///         let title: String
///     }
///
///     let definition = AIUIComponentDefinition(
///         name: "place_card",
///         description: "A photo and a short summary of a place.",
///         parameters: [.required("title", .string)],
///         events: [.init(name: "ask_about", description: "The person asks about the place.")]
///     )
///
///     func body(arguments: Arguments, context: AIUIComponentContext) -> some View {
///         PlaceCard(title: arguments.title) {
///             context.emit("ask_about", label: "Tell me more about \(arguments.title)")
///         }
///     }
/// }
/// ```
@MainActor
public protocol AIUIComponent: Sendable {
    /// What the agent fills in, decoded from the JSON it writes.
    associatedtype Arguments: Decodable
    /// The view it shows.
    associatedtype Body: View

    /// Its description, the same on every platform and for the agent.
    var definition: AIUIComponentDefinition { get }

    /// How it looks for the arguments the agent wrote. It tells the agent what the person does
    /// in it through `context`.
    @ViewBuilder func body(arguments: Arguments, context: AIUIComponentContext) -> Body
}

public extension AIUIComponent {
    /// The name the agent places it by.
    var name: String { definition.name }

    /// The component for the arguments the agent wrote, coming in as it shows (see
    /// `aiUIEntrance()`), or `nil` while they don't fit its parameters, such as while they are
    /// still streaming in.
    func view(arguments: [String: RawJSON], context: AIUIComponentContext) -> (some View)? {
        (try? AIUIArguments.decode(Arguments.self, from: arguments)).map { arguments in
            body(arguments: arguments, context: context).aiUIEntrance()
        }
    }
}
