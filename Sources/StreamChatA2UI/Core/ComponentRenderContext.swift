//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// One child of a container component, resolved for rendering.
///
/// Static child lists produce one entry per id. Templates produce one entry per
/// item of the bound collection, each with its own collection scope so that
/// relative bindings resolve against that item.
@available(iOS 15.0, macOS 12.0, *)
public struct ResolvedChild: Identifiable {
    /// A stable identity for SwiftUI list diffing.
    public let id: String

    /// The id of the component to render.
    public let componentId: String

    /// The data scope the child renders in.
    let dataContext: DataContext

    /// The layout weight declared by the child component.
    public let weight: Double?

    /// Creates a resolved child.
    /// The renderer builds these from a ``ChildList``.
    init(id: String, componentId: String, dataContext: DataContext, weight: Double?) {
        self.id = id
        self.componentId = componentId
        self.dataContext = dataContext
        self.weight = weight
    }
}

/// Everything a component builder needs to render one component instance.
///
/// The context resolves properties against the data model, builds child views
/// and dispatches actions, so component implementations stay declarative.
@available(iOS 15.0, macOS 12.0, *)
@MainActor
public struct ComponentRenderContext {
    /// The component instance being rendered.
    let component: Component

    /// The catalog definition of the component being rendered.
    let definition: ComponentDefinition

    /// The surface the component belongs to.
    let surfaceId: String

    /// The data scope this instance renders in.
    let dataContext: DataContext

    /// The evaluator used to resolve dynamic values and functions.
    let evaluator: ExpressionEvaluator

    /// The renderer that builds children and dispatches actions.
    let renderer: SurfaceRenderer

    /// The ids of the components from the surface's root down to this one, used to stop a
    /// component from containing itself.
    let ancestors: [String]

    /// How deeply nested this component is.
    var depth: Int {
        ancestors.count - 1
    }

    /// Creates a render context.
    /// The renderer creates these while walking the component tree.
    init(
        component: Component,
        definition: ComponentDefinition,
        surfaceId: String,
        dataContext: DataContext,
        evaluator: ExpressionEvaluator,
        renderer: SurfaceRenderer,
        ancestors: [String]
    ) {
        self.component = component
        self.definition = definition
        self.surfaceId = surfaceId
        self.dataContext = dataContext
        self.evaluator = evaluator
        self.renderer = renderer
        self.ancestors = ancestors
    }

    /// The id of the component being rendered.
    public var id: String {
        component.id
    }

    /// Host capabilities such as the current locale.
    var services: RendererServices {
        evaluator.services
    }

    // MARK: - Property access

    /// Reads a property as a dynamic value.
    /// Missing properties produce ``DynamicValue/missing``.
    func dynamic(_ key: String) -> DynamicValue {
        component.dynamic(key)
    }

    /// Evaluates a property and coerces it to a string.
    /// Returns `nil` when the property is missing or unresolved.
    public func string(_ key: String) -> String? {
        evaluator.string(dynamic(key), in: dataContext)
    }

    /// Evaluates a property and coerces it to a string, with a fallback.
    public func string(_ key: String, default defaultValue: String) -> String {
        string(key) ?? defaultValue
    }

    /// Evaluates a property and coerces it to a number.
    public func double(_ key: String) -> Double? {
        evaluator.double(dynamic(key), in: dataContext)
    }

    /// Evaluates a property and coerces it to a number, with a fallback.
    public func double(_ key: String, default defaultValue: Double) -> Double {
        double(key) ?? defaultValue
    }

    /// Evaluates a property and coerces it to an integer.
    public func int(_ key: String) -> Int? {
        double(key).flatMap { Int(exactly: $0.rounded(.towardZero)) }
    }

    /// Evaluates a property and coerces it to a boolean.
    public func bool(_ key: String) -> Bool? {
        evaluator.bool(dynamic(key), in: dataContext)
    }

    /// Evaluates a property and coerces it to a boolean, with a fallback.
    public func bool(_ key: String, default defaultValue: Bool) -> Bool {
        bool(key) ?? defaultValue
    }

    /// Evaluates a property and coerces it to a list of strings.
    public func stringArray(_ key: String) -> [String]? {
        evaluator.stringArray(dynamic(key), in: dataContext)
    }

    /// Evaluates a property and returns its raw value.
    func value(_ key: String) -> (any Sendable)? {
        evaluator.evaluate(dynamic(key), in: dataContext)
    }

    /// Reads a string property that is always a literal on the wire.
    /// Used for enumerated style hints such as `variant` or `align`.
    public func literalString(_ key: String) -> String? {
        Json.string(component.property(key))
    }

    /// Reads an enumerated style hint with a fallback.
    public func option(_ key: String, default defaultValue: String) -> String {
        literalString(key) ?? defaultValue
    }

    /// The layout weight of this component inside a `Row` or `Column`.
    public var weight: Double? {
        component.weight
    }

    // MARK: - Children

    /// Reads a child list property.
    /// Defaults to the conventional `children` property.
    func childList(_ key: String = "children") -> ChildList {
        ChildList(component.properties[key])
    }

    /// Reads a single child id property.
    /// Defaults to the conventional `child` property.
    public func childId(_ key: String = "child") -> String? {
        component.property(key) as? String
    }

    /// Resolves a child list into renderable children.
    ///
    /// Template child lists are expanded against the bound collection, giving
    /// each item its own scope and `@index` value.
    public func resolvedChildren(_ key: String = "children") -> [ResolvedChild] {
        switch childList(key) {
        case let .ids(ids):
            return ids.enumerated().map { offset, componentId in
                ResolvedChild(
                    id: "\(componentId)#\(offset)",
                    componentId: componentId,
                    dataContext: dataContext,
                    weight: renderer.component(componentId)?.weight
                )
            }
        case let .template(componentId, path):
            let items = Json.array(dataContext.value(at: path)) ?? []
            let weight = renderer.component(componentId)?.weight
            return items.indices.map { index in
                ResolvedChild(
                    id: "\(componentId)#\(index)",
                    componentId: componentId,
                    dataContext: dataContext.collectionScope(path: path, index: index),
                    weight: weight
                )
            }
        case .none:
            return []
        }
    }

    /// Builds the view for a child component.
    /// Missing components render a diagnostic placeholder.
    public func childView(_ componentId: String?) -> AnyView {
        childView(componentId, dataContext: nil)
    }

    func childView(_ componentId: String?, dataContext childContext: DataContext?) -> AnyView {
        guard let componentId else { return AnyView(EmptyView()) }
        return renderer.view(
            componentId: componentId,
            dataContext: childContext ?? dataContext,
            parent: definition,
            ancestors: ancestors
        )
    }

    /// Builds the view for a resolved child.
    public func childView(_ child: ResolvedChild) -> AnyView {
        renderer.view(
            componentId: child.componentId,
            dataContext: child.dataContext,
            parent: definition,
            ancestors: ancestors
        )
    }

    // MARK: - Actions and validation

    /// The action declared by this component, if any.
    var action: ActionDefinition? {
        ActionDefinition(component.properties["action"])
    }

    /// Performs an action, dispatching an event or calling a function.
    /// Call this from a component's interaction handler.
    func perform(_ action: ActionDefinition?) {
        guard let action else { return }
        renderer.perform(action, componentId: component.id, dataContext: dataContext)
    }

    /// Performs this component's declared action.
    public func performAction() {
        perform(action)
    }

    /// The checks of this component that currently fail.
    var failingChecks: [ValidationResult] {
        evaluator.failingChecks(component.checks, in: dataContext)
    }

    /// The messages of failing checks with error severity.
    public var validationErrors: [String] {
        failingChecks
            .filter { $0.severity == .error }
            .compactMap { $0.message ?? $0.code }
    }

    /// Whether every check of this component passes.
    public var isValid: Bool {
        !failingChecks.contains { $0.severity == .error }
    }

    // MARK: - Two-way bindings

    /// A two-way binding for a bound string property.
    /// Literal properties are read-only and log a warning when written.
    public func stringBinding(_ key: String = "value", default defaultValue: String = "") -> Binding<String> {
        binding(key, default: defaultValue, read: { Json.string($0) })
    }

    /// A two-way binding for a bound boolean property.
    public func boolBinding(_ key: String = "value", default defaultValue: Bool = false) -> Binding<Bool> {
        binding(key, default: defaultValue, read: { Json.bool($0) })
    }

    /// A two-way binding for a bound numeric property.
    public func doubleBinding(_ key: String = "value", default defaultValue: Double = 0) -> Binding<Double> {
        binding(key, default: defaultValue, read: { Json.double($0) })
    }

    /// A two-way binding for a bound string list property.
    public func stringArrayBinding(_ key: String = "value", default defaultValue: [String] = []) -> Binding<[String]> {
        binding(key, default: defaultValue, read: { Json.stringArray($0) })
    }

    /// Writes a value to a bound property.
    /// Does nothing when the property is not a data binding.
    func write(_ value: (any Sendable)?, to key: String) {
        guard let path = dynamic(key).bindingPath else {
            a2uiLogger.warning(
                "Component '\(component.id)' cannot write '\(key)' because it is not bound to a data model path."
            )
            return
        }
        dataContext.update(path, value)
    }

    private func binding<Value: Sendable>(
        _ key: String,
        default defaultValue: Value,
        read: @escaping ((any Sendable)?) -> Value?
    ) -> Binding<Value> {
        Binding(
            get: { read(self.value(key)) ?? defaultValue },
            set: { newValue in self.write(newValue, to: key) }
        )
    }
}
