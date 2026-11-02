//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Renders a component from its evaluated props.
@available(iOS 17.0, macOS 14.0, *)
public typealias ComponentRenderer = @MainActor @Sendable (ComponentContext) -> AnyView

/// A component: its schema (the model-facing contract) and its SwiftUI renderer.
@available(iOS 17.0, macOS 14.0, *)
public struct ComponentDefinition: Sendable {
    public var schema: ComponentSchema
    /// `nil` for data-only components that are consumed by their parent (e.g. `SelectItem`, `Series`).
    public var renderer: ComponentRenderer?

    public var name: String { schema.name }

    public init(_ schema: ComponentSchema, renderer: ComponentRenderer?) {
        self.schema = schema
        self.renderer = renderer
    }

    /// Defines a component with a SwiftUI view builder.
    public init<Content: View>(_ schema: ComponentSchema, @ViewBuilder view: @escaping @MainActor @Sendable (ComponentContext) -> Content) {
        self.schema = schema
        self.renderer = { context in AnyView(view(context)) }
    }
}

/// A component library: the set of components the model may use, how to render them, and the
/// metadata needed to generate the system prompt (mirrors `createLibrary` in `@openuidev/react-lang`).
@available(iOS 17.0, macOS 14.0, *)
public struct ComponentLibrary: Sendable {
    /// Root component name (e.g. `"Card"` for chat, `"Stack"` for the standard library).
    public let root: String?
    /// Components in library order.
    public let components: [ComponentDefinition]
    public let componentGroups: [ComponentGroup]
    /// Prompt examples and rules recommended for this library.
    public let defaultPromptOptions: PromptOptions

    /// The library JSON Schema (`library.toJSONSchema()`).
    public let jsonSchema: OpenUIValue
    /// Compiled positional parameters used by the parser.
    public let paramMap: ParamMap

    private let definitionsByName: [String: ComponentDefinition]
    private let reactiveProps: [String: Set<String>]

    public init(
        root: String?,
        components: [ComponentDefinition],
        componentGroups: [ComponentGroup] = [],
        defaultPromptOptions: PromptOptions = PromptOptions()
    ) {
        var byName: [String: ComponentDefinition] = [:]
        var ordered: [ComponentDefinition] = []
        for component in components {
            if byName[component.name] == nil {
                ordered.append(component)
            } else if let index = ordered.firstIndex(where: { $0.name == component.name }) {
                ordered[index] = component
            }
            byName[component.name] = component
        }
        if let root {
            precondition(byName[root] != nil, "Root component \"\(root)\" was not found in components.")
        }
        self.root = root
        self.components = ordered
        self.componentGroups = componentGroups
        self.defaultPromptOptions = defaultPromptOptions
        self.definitionsByName = byName
        self.reactiveProps = byName.mapValues(\.schema.reactiveProps)
        let schema = Self.buildJSONSchema(ordered.map(\.schema))
        self.jsonSchema = schema
        self.paramMap = OpenUIParser.compileSchema(schema)
    }

    public var componentNames: [String] { components.map(\.name) }

    public func component(named name: String) -> ComponentDefinition? {
        definitionsByName[name]
    }

    /// A parser for this library.
    public var parser: OpenUIParser {
        OpenUIParser(paramMap: paramMap, rootName: root)
    }

    /// A streaming parser for this library.
    public func makeStreamParser() -> OpenUIStreamParser {
        OpenUIStreamParser(paramMap: paramMap, rootName: root)
    }

    // MARK: - Customization

    /// Returns a library with `components` added (or replacing same-named components).
    public func adding(_ components: [ComponentDefinition], groups: [ComponentGroup] = []) -> ComponentLibrary {
        ComponentLibrary(
            root: root,
            components: self.components + components,
            componentGroups: componentGroups + groups,
            defaultPromptOptions: defaultPromptOptions
        )
    }

    /// Returns a library where the renderer of `name` is replaced (the schema is kept).
    public func replacingRenderer(for name: String, with renderer: @escaping ComponentRenderer) -> ComponentLibrary {
        let updated = components.map { definition -> ComponentDefinition in
            guard definition.name == name else { return definition }
            return ComponentDefinition(definition.schema, renderer: renderer)
        }
        return ComponentLibrary(root: root, components: updated, componentGroups: componentGroups, defaultPromptOptions: defaultPromptOptions)
    }

    /// Returns a library without the given components.
    public func removing(_ names: Set<String>) -> ComponentLibrary {
        ComponentLibrary(
            root: root,
            components: components.filter { !names.contains($0.name) },
            componentGroups: componentGroups.map { group in
                ComponentGroup(name: group.name, components: group.components.filter { !names.contains($0) }, notes: group.notes)
            },
            defaultPromptOptions: defaultPromptOptions
        )
    }

    // MARK: - Prompt & spec

    /// Generates the system prompt for this library. Uses ``defaultPromptOptions`` when `options` is `nil`.
    public func systemPrompt(_ options: PromptOptions? = nil) -> String {
        PromptGenerator.generate(promptSpec(options ?? defaultPromptOptions))
    }

    public func promptSpec(_ options: PromptOptions) -> PromptSpec {
        PromptSpec(
            root: root,
            components: components.map { PromptSpec.Component(name: $0.name, signature: $0.schema.signature, description: $0.schema.description) },
            componentGroups: componentGroups,
            options: options
        )
    }

    /// The library spec in the `LibrarySpec` format of `@openuidev/lang-core` (`library.toSpec()`),
    /// suitable for generating prompts on a server with `generateSystemPrompt({ library })`.
    public var specJSON: OpenUIValue {
        var spec = OpenUIObject()
        if let root { spec["root"] = .string(root) }
        spec["components"] = .object(OpenUIObject(components.map { component in
            (component.name, ["signature": .string(component.schema.signature), "description": .string(component.schema.description)])
        }))
        spec["componentGroups"] = .array(componentGroups.map { group in
            var object: OpenUIObject = ["name": .string(group.name), "components": .array(group.components.map(OpenUIValue.string))]
            if !group.notes.isEmpty { object["notes"] = .array(group.notes.map(OpenUIValue.string)) }
            return .object(object)
        })
        spec["schema"] = jsonSchema
        return .object(spec)
    }

    // MARK: - Schema

    static func buildJSONSchema(_ schemas: [ComponentSchema]) -> OpenUIValue {
        let byName = Dictionary(schemas.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })
        // $defs are emitted in depth-first, first-encounter order (as Zod's toJSONSchema does).
        var order: [String] = []
        var seen = Set<String>()
        func visit(_ name: String) {
            guard let schema = byName[name], seen.insert(name).inserted else { return }
            order.append(name)
            for field in schema.props {
                for reference in field.type.componentReferences {
                    visit(reference)
                }
            }
        }
        schemas.forEach { visit($0.name) }

        var defs = OpenUIObject()
        for name in order {
            defs[name] = byName[name]?.jsonSchema
        }
        return [
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "type": "object",
            "properties": .object(OpenUIObject(schemas.map { ($0.name, ["$ref": .string("#/$defs/\($0.name)")]) })),
            "required": .array(schemas.map { .string($0.name) }),
            "additionalProperties": false,
            "$defs": .object(defs)
        ]
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension ComponentLibrary: ReactivePropResolver {
    public func isReactiveProp(component: String, prop: String) -> Bool {
        reactiveProps[component]?.contains(prop) ?? false
    }
}
