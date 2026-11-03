//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import SwiftUI
import Testing

@MainActor
@Suite("Basic catalog")
struct BasicCatalogTests {
    @Test("Every component of the v1.0 basic catalog is implemented")
    func components() {
        let expected = [
            "AudioPlayer", "Button", "Card", "CheckBox", "ChoicePicker", "Column",
            "DateTimeInput", "Divider", "Icon", "Image", "List", "Modal", "Row",
            "Slider", "Tabs", "Text", "TextField", "Video"
        ]
        #expect(BasicCatalog.catalog.components.keys.sorted() == expected)
    }

    @Test("Every function of the v1.0 basic catalog is implemented")
    func functions() {
        let expected = [
            "and", "email", "formatCurrency", "formatDate", "formatNumber", "formatString",
            "length", "not", "numeric", "openUrl", "or", "pluralize", "regex", "required"
        ]
        #expect(BasicCatalog.catalog.functions.keys.sorted() == expected)
    }

    @Test("The catalog id matches the specification")
    func catalogId() {
        #expect(BasicCatalog.catalogId == "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json")
        #expect(BasicCatalog.catalog.catalogId == BasicCatalog.catalogId)
    }

    @Test("Replacing a component's view keeps its properties and the other components")
    func replacingView() throws {
        let catalog = BasicCatalog.catalog.replacingView(of: "Card") { _ in AnyView(EmptyView()) }
        let card = try #require(catalog.component("Card"))
        let basicCard = try #require(BasicCatalog.catalog.component("Card"))

        #expect(card.requiredProperties == basicCard.requiredProperties)
        #expect(card.propertySchema.keys.sorted() == basicCard.propertySchema.keys.sorted())
        #expect(catalog.components.keys.sorted() == BasicCatalog.catalog.components.keys.sorted())
        #expect(catalog.catalogId == BasicCatalog.catalogId)

        let unchanged = BasicCatalog.catalog.replacingView(of: "Missing") { _ in AnyView(EmptyView()) }
        #expect(unchanged.components.keys.sorted() == BasicCatalog.catalog.components.keys.sorted())
    }

    @Test("The reserved Surface component type is not defined")
    func reservedComponentName() {
        #expect(BasicCatalog.catalog.component(A2UIProtocol.surfaceComponentType) == nil)
    }

    @Test("Every component declares its required properties")
    func requiredProperties() throws {
        let expectations = [
            "Text": ["text"],
            "Image": ["url"],
            "Icon": ["name"],
            "Row": ["children"],
            "Column": ["children"],
            "Card": ["child"],
            "Button": ["child", "action"],
            "TextField": ["label"],
            "CheckBox": ["label", "value"],
            "ChoicePicker": ["options", "value"],
            "Slider": ["value", "max"],
            "DateTimeInput": ["value"],
            "Modal": ["trigger", "content"],
            "Tabs": ["tabs"]
        ]
        for (name, required) in expectations {
            let definition = try #require(BasicCatalog.catalog.component(name))
            #expect(Set(definition.requiredProperties) == Set(required), "\(name) required properties")
        }
    }

    @Test("Every component and function name is a valid catalog identifier")
    func naming() {
        // The specification requires UAX #31 identifiers for catalog entities.
        let pattern = "^[A-Za-z_][A-Za-z0-9_]*$"
        for name in BasicCatalog.catalog.components.keys {
            #expect(name.range(of: pattern, options: .regularExpression) != nil, "component \(name)")
        }
        for name in BasicCatalog.catalog.functions.keys {
            #expect(name.range(of: pattern, options: .regularExpression) != nil, "function \(name)")
            #expect(!name.hasPrefix("@"), "catalogs must not define system functions")
        }
    }

    @Test("Component examples are valid component payloads with a root")
    func examples() throws {
        for definition in BasicCatalog.catalog.components.values {
            for example in definition.examples {
                let array = try #require(Json.decode(example) as? JsonArray, "\(definition.name) example is not an array")
                let components = A2UIMessageDecoder.components(from: array)
                #expect(components.count == array.count, "\(definition.name) example has invalid components")
                #expect(components.contains { $0.id == A2UIProtocol.rootComponentId }, "\(definition.name) example has no root")
            }
        }
    }
}

@MainActor
@Suite("Catalog schema generation")
struct CatalogSchemaTests {
    @Test("The catalog document follows the v1.0 layout")
    func document() throws {
        let schema = BasicCatalog.catalog.toJsonSchema()

        #expect(schema["catalogId"] as? String == BasicCatalog.catalogId)
        #expect(schema["$id"] as? String == BasicCatalog.catalogId)
        #expect(schema["protocolVersion"] as? String == "1.0")
        #expect(schema["instructions"] != nil)

        let allowedKeys: Set<String> = [
            "$schema", "$id", "protocolVersion", "title", "description",
            "catalogId", "instructions", "components", "functions", "$defs"
        ]
        #expect(Set(schema.keys).isSubset(of: allowedKeys))

        let defs = try #require(Json.map(schema["$defs"]))
        #expect(Set(defs.keys) == ["anyComponent", "anyFunction"])
        let anyComponent = try #require(Json.map(defs["anyComponent"]))
        #expect(Json.map(anyComponent["discriminator"])?["propertyName"] as? String == "component")
        #expect(Json.array(anyComponent["oneOf"])?.count == BasicCatalog.catalog.components.count)
    }

    @Test("Component schemas declare the component discriminator")
    func componentDiscriminator() throws {
        let schema = BasicCatalog.catalog.toJsonSchema()
        let components = try #require(Json.map(schema["components"]))

        for (name, value) in components {
            let componentSchema = try #require(Json.map(value))
            let properties = try #require(Json.map(componentSchema["properties"]))
            let discriminator = try #require(Json.map(properties["component"]))
            #expect(discriminator["const"] as? String == name)
            #expect(Json.stringArray(componentSchema["required"])?.contains("component") == true)
        }
    }

    @Test("Function schemas declare their call name, return type and callers")
    func functionSchemas() throws {
        let schema = BasicCatalog.catalog.toJsonSchema()
        let functions = try #require(Json.map(schema["functions"]))

        for (name, value) in functions {
            let functionSchema = try #require(Json.map(value))
            let properties = try #require(Json.map(functionSchema["properties"]))
            #expect(Json.map(properties["@call"])?["const"] as? String == name)
            #expect(functionSchema["returnType"] as? String != nil)
            #expect(functionSchema["allowedCallers"] as? String != nil)
        }

        let openUrl = try #require(Json.map(functions["openUrl"]))
        #expect(openUrl["requiresUserActivation"] as? Bool == true)
        #expect(openUrl["allowedCallers"] as? String == "rendererOnly")
    }

    @Test("Composition constraints are exported")
    func compositionConstraints() throws {
        let catalog = Catalog(
            catalogId: "app:catalog",
            components: [
                ComponentDefinition(name: "Menu", allowedChildren: ["MenuItem"]) { _ in AnyView(EmptyViewShim()) },
                ComponentDefinition(name: "MenuItem", allowedParents: ["Menu"]) { _ in AnyView(EmptyViewShim()) }
            ]
        )
        let components = try #require(Json.map(catalog.toJsonSchema()["components"]))

        #expect(Json.stringArray(Json.map(components["Menu"])?["allowedChildren"]) == ["MenuItem"])
        #expect(Json.stringArray(Json.map(components["MenuItem"])?["allowedParents"]) == ["Menu"])
    }
}

@MainActor
@Suite("Catalog registry")
struct CatalogRegistryTests {
    private var appCatalog: Catalog {
        Catalog(
            catalogId: "app:catalog",
            components: [ComponentDefinition(name: "Hero") { _ in AnyView(EmptyViewShim()) }],
            functions: [
                FunctionDefinition(name: "appOnly", description: "", returnType: .string) { _ in "x" }
            ]
        )
    }

    @Test("A component level catalog id wins over the surface default")
    func componentLevelCatalog() {
        let registry = CatalogRegistry(catalogs: [BasicCatalog.catalog, appCatalog])
        let component = Component(id: "hero", type: "Hero", catalogId: "app:catalog")

        #expect(registry.component(component, surfaceCatalogId: BasicCatalog.catalogId)?.name == "Hero")
    }

    @Test("Components fall back to the surface default catalog")
    func surfaceDefaultCatalog() {
        let registry = CatalogRegistry(catalogs: [BasicCatalog.catalog, appCatalog])
        let component = Component(id: "title", type: "Text")

        #expect(registry.component(component, surfaceCatalogId: BasicCatalog.catalogId)?.name == "Text")
    }

    @Test("There is no fallback to other supported catalogs")
    func noImplicitFallback() {
        let registry = CatalogRegistry(catalogs: [BasicCatalog.catalog, appCatalog])
        let component = Component(id: "title", type: "Text")

        #expect(registry.component(component, surfaceCatalogId: nil) == nil)
        #expect(registry.component(component, surfaceCatalogId: "app:catalog") == nil)
        #expect(registry.component(Component(id: "x", type: "Text", catalogId: "nope:catalog"), surfaceCatalogId: BasicCatalog.catalogId) == nil)
    }

    @Test("A renderer configured default keeps agents that omit the catalog working")
    func rendererDefault() {
        let registry = CatalogRegistry(catalogs: [BasicCatalog.catalog], defaultCatalogId: BasicCatalog.catalogId)
        #expect(registry.component(Component(id: "title", type: "Text"), surfaceCatalogId: nil)?.name == "Text")
    }

    @Test("Agent-initiated calls can name any supported catalog")
    func functionLookup() {
        let registry = CatalogRegistry(catalogs: [BasicCatalog.catalog, appCatalog])

        #expect(registry.function(named: "appOnly", catalogId: "app:catalog") != nil)
        #expect(registry.function(named: "appOnly", catalogId: BasicCatalog.catalogId) == nil)
        #expect(registry.function(named: "appOnly", catalogId: nil) != nil)
        #expect(registry.supportedCatalogIds == ["app:catalog", BasicCatalog.catalogId].sorted())
    }

    @Test("Catalogs can be extended and trimmed")
    func customization() {
        let extended = BasicCatalog.catalog.adding(
            components: [ComponentDefinition(name: "Hero") { _ in AnyView(EmptyViewShim()) }],
            catalogId: "app:catalog"
        )
        #expect(extended.catalogId == "app:catalog")
        #expect(extended.component("Hero") != nil)
        #expect(extended.component("Text") != nil)

        let trimmed = extended.removing(components: ["Video", "AudioPlayer"])
        #expect(trimmed.component("Video") == nil)
        #expect(trimmed.components.count == extended.components.count - 2)
    }
}

@MainActor
@Suite("Composition validation")
struct CompositionValidatorTests {
    private let child = ComponentDefinition(name: "MenuItem", allowedParents: ["Menu"]) { _ in AnyView(EmptyViewShim()) }
    private let container = ComponentDefinition(name: "Menu", allowedChildren: ["MenuItem"]) { _ in AnyView(EmptyViewShim()) }
    private let text = ComponentDefinition(name: "Text") { _ in AnyView(EmptyViewShim()) }

    @Test("An allowed nesting is allowed")
    func allowed() {
        #expect(CompositionValidator.allows(child, in: container))
        #expect(CompositionValidator.allows(text, in: container) == false)
        #expect(CompositionValidator.allows(child, in: text) == false)
    }

    @Test("The surface root is checked against the reserved Surface container")
    func surfaceParent() {
        let rootOnly = ComponentDefinition(name: "AppLayout", allowedParents: ["Surface"]) { _ in AnyView(EmptyViewShim()) }

        #expect(CompositionValidator.allows(rootOnly, in: nil))
        #expect(CompositionValidator.allows(rootOnly, in: text) == false)
    }

    @Test("test_composition_unallowed_parent_error: the error points at the child in the message")
    func unallowedParentPath() {
        let errors = compositionErrors([
            Component(id: "root", type: "Text", properties: ["children": ["item"]]),
            Component(id: "item", type: "MenuItem")
        ])

        #expect(errors.map(\.code) == [RendererError.Code.unallowedParent])
        #expect(errors.first?.path == "/components/1")
        #expect(errors.first?.message == "Component 'item' (MenuItem) cannot be placed under parent 'root' (Text). Allowed parents: ['Menu'].")
    }

    @Test("test_composition_unallowed_child_error: the error points at the parent's child slot")
    func unallowedChildPath() {
        let errors = compositionErrors([
            Component(id: "root", type: "Menu", properties: ["children": ["item", "label"]]),
            Component(id: "item", type: "MenuItem"),
            Component(id: "label", type: "Text")
        ])

        #expect(errors.map(\.code) == [RendererError.Code.unallowedChild])
        #expect(errors.first?.path == "/components/0/children/1")
        #expect(errors.first?.message == "Container 'root' (Menu) cannot contain child 'label' (Text). Allowed children: ['MenuItem'].")
    }

    @Test("test_composition_unallowed_parent_root_error: the root is checked against Surface")
    func unallowedRoot() {
        let errors = compositionErrors([Component(id: "root", type: "MenuItem")])

        #expect(errors.first?.path == "/components/0")
        #expect(errors.first?.message == "Component 'root' (MenuItem) cannot be placed under parent 'Surface' (Surface). Allowed parents: ['Menu'].")
    }

    @Test("test_composition_dropped_child_is_not_checked_against_surface: a component nothing holds isn't checked")
    func orphanNotChecked() {
        #expect(compositionErrors([
            Component(id: "root", type: "Menu", properties: ["children": [] as JsonArray]),
            Component(id: "item", type: "MenuItem")
        ]).isEmpty)
    }

    @Test("A parent from an earlier message is checked against a child arriving now")
    func earlierParent() {
        let surface = SurfaceDefinition(surfaceId: "s", catalogId: "c").merging([
            Component(id: "root", type: "Text", properties: ["children": ["item"]]),
            Component(id: "item", type: "MenuItem")
        ])
        let errors = CompositionValidator.errors(in: surface, batch: [Component(id: "item", type: "MenuItem")], catalogs: registry)

        #expect(errors.first?.path == "/components/0")
    }

    private var registry: CatalogRegistry {
        let children = ["children": JsonSchema.children()]
        return CatalogRegistry(catalogs: [
            Catalog(catalogId: "c", components: [
                ComponentDefinition(name: "MenuItem", allowedParents: ["Menu"]) { _ in AnyView(EmptyViewShim()) },
                ComponentDefinition(name: "Menu", properties: children, allowedChildren: ["MenuItem"]) { _ in AnyView(EmptyViewShim()) },
                ComponentDefinition(name: "Text", properties: children) { _ in AnyView(EmptyViewShim()) }
            ])
        ])
    }

    private func compositionErrors(_ components: [Component]) -> [RendererError] {
        let surface = SurfaceDefinition(surfaceId: "s", catalogId: "c").merging(components)
        return CompositionValidator.errors(in: surface, batch: components, catalogs: registry)
    }
}
