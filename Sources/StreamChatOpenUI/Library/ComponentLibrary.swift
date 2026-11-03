//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftUI

/// Renders a component from its evaluated props.
@available(iOS 17.0, macOS 14.0, *)
typealias ComponentRenderer = @MainActor @Sendable (ComponentContext) -> AnyView

/// A component: its schema (the model-facing contract) and its SwiftUI renderer.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIComponentDefinition: Sendable {
    var schema: ComponentSchema
    /// `nil` for data-only components that are consumed by their parent (e.g. `SelectItem`, `Series`).
    var renderer: ComponentRenderer?

    var name: String { schema.name }

    init(_ schema: ComponentSchema, renderer: ComponentRenderer?) {
        self.schema = schema
        self.renderer = renderer
    }

    /// Defines a component with a SwiftUI view builder.
    init<Content: View>(_ schema: ComponentSchema, @ViewBuilder view: @escaping @MainActor @Sendable (ComponentContext) -> Content) {
        self.schema = schema
        self.renderer = { context in AnyView(view(context)) }
    }
}

/// A component library: the set of components the model may use, how to render them, and the
/// metadata needed to generate the system prompt (mirrors `createLibrary` in `@openuidev/react-lang`).
@available(iOS 17.0, macOS 14.0, *)
public struct ComponentLibrary: Sendable {
    /// Root component name (e.g. `"Card"` for chat, `"Stack"` for the standard library).
    let root: String?
    /// Components in library order.
    let components: [OpenUIComponentDefinition]
    let componentGroups: [ComponentGroup]
    /// Prompt examples and rules recommended for this library.
    let defaultPromptOptions: PromptOptions
    /// The app's functions, called as `@Name(...)` in programs.
    let functions: [OpenUIFunction]
    /// The app's action steps, used as `@Name(...)` in action props.
    let customActions: [OpenUICustomAction]

    /// The library JSON Schema (`library.toJSONSchema()`).
    let jsonSchema: OpenUIValue
    /// Compiled positional parameters used by the parser.
    let paramMap: ParamMap

    // Tells this library from one made apart from it, whose renderers, functions and actions
    // are closures that can't be compared.
    let identity = UUID()
    private let definitionsByName: [String: OpenUIComponentDefinition]
    private let reactiveProps: [String: Set<String>]

    init(
        root: String?,
        components: [OpenUIComponentDefinition],
        componentGroups: [ComponentGroup] = [],
        defaultPromptOptions: PromptOptions = PromptOptions(),
        functions: [OpenUIFunction] = [],
        customActions: [OpenUICustomAction] = []
    ) {
        var byName: [String: OpenUIComponentDefinition] = [:]
        var ordered: [OpenUIComponentDefinition] = []
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
        // A function or action can't share a name with a built-in, a component or another call.
        var names = Set(byName.keys)
        func claim(_ name: String) -> Bool {
            guard !Builtins.isBuiltin(name), !Builtins.isReservedCall(name), names.insert(name).inserted else {
                assertionFailure("\(name) collides with a built-in, component, function or action of the same name")
                return false
            }
            return true
        }
        self.functions = functions.filter { claim($0.name) }
        self.customActions = customActions.filter { claim($0.name) }
        let schema = Self.buildJSONSchema(ordered.map(\.schema), functions: self.functions, actions: self.customActions)
        self.jsonSchema = schema
        self.paramMap = OpenUIParser.compileSchema(schema)
    }

    // A library that parses with a given JSON Schema and renders nothing, such as the OpenUI
    // spec's test library.
    init(
        specSchema: OpenUIValue,
        root: String?,
        reactiveProps: [String: Set<String>],
        functions: [OpenUIFunction] = [],
        customActions: [OpenUICustomAction] = []
    ) {
        self.root = root
        components = []
        componentGroups = []
        defaultPromptOptions = PromptOptions()
        self.functions = functions
        self.customActions = customActions
        jsonSchema = specSchema
        paramMap = OpenUIParser.compileSchema(specSchema)
        definitionsByName = [:]
        self.reactiveProps = reactiveProps
    }

    public var componentNames: [String] { components.map(\.name) }

    // Whether programs parse the same with `other`, which can still render, compute or act
    // differently.
    func parses(like other: ComponentLibrary) -> Bool {
        identity == other.identity || (root == other.root && jsonSchema == other.jsonSchema)
    }

    func component(named name: String) -> OpenUIComponentDefinition? {
        definitionsByName[name]
    }

    /// A parser for this library.
    var parser: OpenUIParser {
        OpenUIParser(paramMap: paramMap, rootName: root)
    }

    /// A streaming parser for this library.
    func makeStreamParser() -> OpenUIStreamParser {
        OpenUIStreamParser(paramMap: paramMap, rootName: root)
    }

    // MARK: - Customization

    /// Returns a library with `components` added. A component is left out when the library already
    /// has one of that name, or its name can't be called in a program: it must start with an upper
    /// case letter and not be a built-in, `Query` or `Mutation`.
    func adding(_ components: [OpenUIComponentDefinition], groups: [ComponentGroup] = []) -> ComponentLibrary {
        ComponentLibrary(
            root: root,
            components: self.components + addable(components),
            componentGroups: componentGroups + groups,
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: customActions
        )
    }

    /// Returns a library in which `view` shows the component named `name`, which keeps its props,
    /// such as to restyle the chat library's buttons. The view's context has the component's
    /// props, and the library's own view of it, ``ComponentContext/defaultView``, to wrap or
    /// restyle. It is the same library when it has no such component.
    ///
    /// ```swift
    /// let library = ComponentLibrary.openUIChat.replacingView(of: .button) { context in
    ///     context.defaultView.tint(.orange)
    /// }
    /// OpenUIRenderer(library: library)
    /// ```
    public func replacingView<Content: View>(
        of name: OpenUIComponentName,
        with view: @escaping @MainActor @Sendable (ComponentContext) -> Content
    ) -> ComponentLibrary {
        guard let original = components.first(where: { $0.name == name.rawValue }), let renderer = original.renderer else {
            return self
        }
        return replacingRenderer(for: name.rawValue) { context in
            var context = context
            context.defaultRenderer = renderer
            return AnyView(view(context))
        }
    }

    /// Returns a library where the renderer of `name` is replaced (the schema is kept).
    func replacingRenderer(for name: String, with renderer: @escaping ComponentRenderer) -> ComponentLibrary {
        let updated = components.map { definition -> OpenUIComponentDefinition in
            guard definition.name == name else { return definition }
            return OpenUIComponentDefinition(definition.schema, renderer: renderer)
        }
        return ComponentLibrary(
            root: root,
            components: updated,
            componentGroups: componentGroups,
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: customActions
        )
    }

    /// Returns a library without the given components. They are also removed from every slot that
    /// takes several types, and groups left empty are dropped. The root component, and a type that
    /// is the only one a slot takes, stay.
    public func removing(_ names: Set<String>) -> ComponentLibrary {
        var names = names
        if let root { names.remove(root) }
        // A component that is all a remaining slot takes stays, and so do the ones its slots need.
        while true {
            let needed = components.filter { !names.contains($0.name) }.flatMap { definition in
                definition.schema.props.flatMap { $0.type.neededComponents(removing: names) }
            }
            let next = names.subtracting(needed)
            if next == names { break }
            names = next
        }
        let remaining = components.filter { !names.contains($0.name) }.map { definition in
            var schema = definition.schema
            schema.props = schema.props.map { field in
                var field = field
                field.type = field.type.removingComponents(names)
                return field
            }
            return OpenUIComponentDefinition(schema, renderer: definition.renderer)
        }
        let groups = componentGroups.compactMap { group -> ComponentGroup? in
            let kept = group.components.filter { !names.contains($0) }
            return kept.isEmpty ? nil : ComponentGroup(name: group.name, components: kept, notes: group.notes)
        }
        return ComponentLibrary(
            root: root,
            components: remaining,
            componentGroups: groups,
            defaultPromptOptions: defaultPromptOptions,
            functions: functions,
            customActions: customActions
        )
    }

    // MARK: - Prompt & spec

    /// Generates the system prompt for this library. Uses ``defaultPromptOptions`` when `options` is `nil`.
    func systemPrompt(_ options: PromptOptions? = nil) -> String {
        PromptGenerator.generate(promptSpec(options ?? defaultPromptOptions))
    }

    func promptSpec(_ options: PromptOptions) -> PromptSpec {
        PromptSpec(
            root: root,
            components: components.map { PromptSpec.Component(name: $0.name, signature: $0.schema.signature, description: $0.schema.description) },
            componentGroups: componentGroups,
            functions: functions.map { PromptSpec.Component(name: $0.name, signature: $0.signature, description: $0.description) },
            actions: customActions.map { PromptSpec.Component(name: $0.name, signature: $0.signature, description: $0.description) },
            options: options
        )
    }

    /// The components of `candidates` that can join this library.
    func addable(_ candidates: [OpenUIComponentDefinition]) -> [OpenUIComponentDefinition] {
        var names = Set(componentNames)
        names.formUnion(functions.map(\.name))
        names.formUnion(customActions.map(\.name))
        return candidates.filter { candidate in
            Self.isCallableName(candidate.name)
                && !Builtins.isBuiltin(candidate.name)
                && !Builtins.isReservedCall(candidate.name)
                && names.insert(candidate.name).inserted
        }
    }

    /// Whether programs can call a component by `name`: an upper case letter, then letters and digits.
    static func isCallableName(_ name: String) -> Bool {
        guard let first = name.unicodeScalars.first, ("A"..."Z").contains(first) else { return false }
        return name.unicodeScalars.allSatisfy { ("A"..."Z").contains($0) || ("a"..."z").contains($0) || ("0"..."9").contains($0) }
    }

    /// The library spec in the `LibrarySpec` format of `@openuidev/lang-core` (`library.toSpec()`),
    /// suitable for generating prompts on a server with `generateSystemPrompt({ library })`.
    var specJSON: OpenUIValue {
        var spec = OpenUIObject()
        if let root { spec["root"] = .string(root) }
        spec["components"] = .object(OpenUIObject(components.map { component in
            (component.name, ["signature": .string(component.schema.signature), "description": .string(component.schema.description)])
        }))
        if !componentGroups.isEmpty {
            spec["componentGroups"] = .array(componentGroups.map { group in
                var object: OpenUIObject = ["name": .string(group.name), "components": .array(group.components.map(OpenUIValue.string))]
                if !group.notes.isEmpty { object["notes"] = .array(group.notes.map(OpenUIValue.string)) }
                return .object(object)
            })
        }
        if !functions.isEmpty {
            spec["functions"] = .object(OpenUIObject(functions.map { function in
                (function.name, ["signature": .string(function.signature), "description": .string(function.description)])
            }))
        }
        if !customActions.isEmpty {
            spec["actions"] = .object(OpenUIObject(customActions.map { action in
                (action.name, ["signature": .string(action.signature), "description": .string(action.description)])
            }))
        }
        spec["schema"] = jsonSchema
        return .object(spec)
    }

    // MARK: - Schema

    static func buildJSONSchema(_ schemas: [ComponentSchema], functions: [OpenUIFunction] = [], actions: [OpenUICustomAction] = []) -> OpenUIValue {
        let byName = Dictionary(schemas.map { ($0.name, $0) }, uniquingKeysWith: { _, last in last })
        // The JSON shapes of the actions slots refer to; a component of the same name wins.
        var actionShapes: [String: OpenUIValue] = [
            PropType.actionExpressionName: PropType.actionSchema,
            "OpenUrl": PropType.openURLSchema,
            "ToAssistant": PropType.toAssistantSchema
        ]
        for action in actions {
            actionShapes[action.name] = action.stepSchema
        }
        // $defs are emitted in depth-first, first-encounter order (as Zod's toJSONSchema does).
        var defs = OpenUIObject()
        var seen = Set<String>()
        func visit(_ reference: PropType.Definition) {
            switch reference {
            case .component(let name):
                guard let schema = byName[name], seen.insert(name).inserted else { return }
                defs[name] = schema.jsonSchema
                for field in schema.props {
                    field.type.definitionReferences.forEach(visit)
                }
            case .action(let name):
                if byName[name] != nil {
                    visit(.component(name))
                    return
                }
                guard let shape = actionShapes[name], seen.insert(name).inserted else { return }
                defs[name] = shape
            }
        }
        schemas.forEach { visit(.component($0.name)) }
        var schema: OpenUIObject = [
            "$schema": "https://json-schema.org/draft/2020-12/schema",
            "type": "object",
            "properties": .object(OpenUIObject(schemas.map { ($0.name, ["$ref": .string("#/$defs/\($0.name)")]) })),
            "required": .array(schemas.map { .string($0.name) }),
            "additionalProperties": false,
            "$defs": .object(defs)
        ]
        if !functions.isEmpty {
            schema["functions"] = .object(OpenUIObject(functions.map { function in
                var entry: OpenUIObject = ["description": .string(function.description), "params": function.paramsSchema]
                if let returns = function.returns { entry["returns"] = returns.jsonSchema }
                return (function.name, .object(entry))
            }))
        }
        if !actions.isEmpty {
            schema["actions"] = .object(OpenUIObject(actions.map { action in
                (action.name, ["description": .string(action.description), "params": action.paramsSchema])
            }))
        }
        return .object(schema)
    }
}

@available(iOS 17.0, macOS 14.0, *)
extension ComponentLibrary: ReactivePropResolver {
    func isReactiveProp(component: String, prop: String) -> Bool {
        reactiveProps[component]?.contains(prop) ?? false
    }
}
