//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamChatA2UI
import Testing

/// Applies a specification example to a real processor and inspects the result.
///
/// The payloads in this file are taken from the A2UI v1.0 basic catalog
/// examples, so they exercise the renderer against content the specification
/// itself ships.
@MainActor
private final class ConformanceHarness {
    let processor: A2UIMessageProcessor
    private(set) var errors: [RendererError] = []
    private var cancellables: Set<AnyCancellable> = []
    let surfaceId: String

    init(_ json: String, surfaceId: String) throws {
        self.surfaceId = surfaceId
        processor = A2UIMessageProcessor(catalogs: [BasicCatalog.catalog], services: TestServices.make())
        processor.rendererMessages
            .sink { [weak self] message in
                if case let .error(error) = message {
                    self?.errors.append(error)
                }
            }
            .store(in: &cancellables)

        guard let values = Json.decode(json) as? JsonArray else {
            throw A2UIDecodingError.unknownMessageType([])
        }
        let result = A2UIMessageDecoder.decodeList(values)
        #expect(result.errors.isEmpty, "the example should decode cleanly")
        processor.handle(result.messages)
    }

    var definition: SurfaceDefinition? {
        processor.surfaceViewModel(surfaceId).definition
    }

    var evaluator: ExpressionEvaluator {
        ExpressionEvaluator(
            catalogs: processor.catalogs,
            surfaceId: surfaceId,
            surfaceCatalogId: definition?.catalogId,
            services: TestServices.make(),
            remoteRouter: processor
        )
    }

    var rootScope: DataContext {
        DataContext(processor.dataModel(for: surfaceId), "/")
    }

    /// Evaluates a component property in the root scope.
    func string(_ componentId: String, _ property: String) -> String? {
        guard let component = definition?.component(componentId) else { return nil }
        return evaluator.string(component.dynamic(property), in: rootScope)
    }

    /// Evaluates a component property in a collection scope.
    func string(_ componentId: String, _ property: String, collection: String, index: Int) -> String? {
        guard let component = definition?.component(componentId) else { return nil }
        let scope = rootScope.collectionScope(path: DataPath(collection), index: index)
        return evaluator.string(component.dynamic(property), in: scope)
    }

    /// Evaluates the failing checks of a component.
    func failingChecks(_ componentId: String) -> [ValidationResult] {
        guard let component = definition?.component(componentId) else { return [] }
        return evaluator.failingChecks(component.checks, in: rootScope)
    }

    /// Asserts every component of the surface resolves against the catalog.
    func expectAllComponentsResolve() {
        guard let definition else {
            Issue.record("The surface was not created")
            return
        }
        for component in definition.components.values {
            #expect(
                processor.catalogs.component(component, surfaceCatalogId: definition.catalogId) != nil,
                "component '\(component.id)' of type '\(component.type)' should resolve"
            )
        }
    }
}

@MainActor
@Suite("Specification conformance")
struct ConformanceTests {
    @Test("The advanced form validator example renders and validates")
    func advancedFormValidator() throws {
        let harness = try ConformanceHarness(Fixtures.advancedFormValidator, surfaceId: "gallery-advanced-validator")
        harness.expectAllComponentsResolve()

        #expect(harness.definition?.sendDataModel == true)
        #expect(harness.errors.isEmpty)

        // formatString with a nested formatDate call.
        #expect(harness.string("welcome_text", "text") == "Hello! Today is Monday, December 15.")

        // Empty optional fields pass their format checks.
        #expect(harness.failingChecks("email_field").isEmpty)
        #expect(harness.failingChecks("phone_field").isEmpty)

        // The submit button is disabled until the composed condition holds.
        let blocked = harness.failingChecks("submit_btn")
        #expect(blocked.count == 1)
        #expect(blocked[0].message == "You must agree to terms AND provide either Email or Phone, plus a Zip code.")

        // Filling the form in satisfies the same condition.
        let model = harness.processor.dataModel(for: harness.surfaceId)
        model.update(at: DataPath("/formData/agree"), value: true)
        model.update(at: DataPath("/formData/email"), value: "ada@example.com")
        model.update(at: DataPath("/formData/zip"), value: "94103")
        #expect(harness.failingChecks("submit_btn").isEmpty)

        // A malformed value fails its own check.
        model.update(at: DataPath("/formData/zip"), value: "941")
        #expect(harness.failingChecks("zip_field").map(\.message) == ["Must be exactly 5 digits"])
    }

    @Test("The coffee order example formats currency and repeats a template")
    func coffeeOrder() throws {
        let harness = try ConformanceHarness(Fixtures.coffeeOrder, surfaceId: "gallery-coffee-order")
        harness.expectAllComponentsResolve()
        #expect(harness.errors.isEmpty)

        #expect(harness.string("store_name", "text") == "Sunrise Coffee")
        #expect(harness.string("item_name", "text", collection: "/items", index: 0) == "Oat Milk Latte")
        #expect(harness.string("item_price", "text", collection: "/items", index: 0) == "$6.45")
        #expect(harness.string("item_price", "text", collection: "/items", index: 1) == "$4.25")
        #expect(harness.string("total_value", "text") == "$11.66")
        #expect(harness.string("total_label", "text") == "#### Total")
    }

    @Test("The child list template example converts numbers to strings")
    func childListTemplate() throws {
        let harness = try ConformanceHarness(Fixtures.childListTemplate, surfaceId: "gallery-child-list-template")
        harness.expectAllComponentsResolve()

        #expect(harness.string("item_name", "text", collection: "/items", index: 0) == "Apple")
        #expect(harness.string("item_qty", "text", collection: "/items", index: 0) == "10")
        #expect(harness.string("item_qty", "text", collection: "/items", index: 2) == "20")

        let list = try #require(harness.definition?.component("item_list"))
        #expect(ChildList(list.properties["children"]) == .template(componentId: "item_row", path: DataPath("/items")))
    }

    @Test("The modal example wires a trigger to its content")
    func modal() throws {
        let harness = try ConformanceHarness(Fixtures.modal, surfaceId: "gallery-modal")
        harness.expectAllComponentsResolve()

        let modal = try #require(harness.definition?.component("root"))
        #expect(modal.type == "Modal")
        #expect(modal.property("trigger") as? String == "open_button")
        #expect(modal.property("content") as? String == "modal_content")
        #expect(harness.errors.isEmpty)
    }

    @Test("The contact form example from the protocol document renders")
    func contactForm() throws {
        let harness = try ConformanceHarness(Fixtures.contactForm, surfaceId: "contact_form_1")
        harness.expectAllComponentsResolve()
        #expect(harness.errors.isEmpty)

        #expect(harness.string("first_name_field", "value") == "John")
        #expect(harness.failingChecks("email_field").isEmpty)
        #expect(harness.failingChecks("phone_field").isEmpty)

        let model = harness.processor.dataModel(for: harness.surfaceId)
        model.update(at: DataPath("/contact/phone"), value: "12345")
        #expect(harness.failingChecks("phone_field").map(\.message) == ["Phone number must be 10 digits."])

        // The submit button's action context mixes literals, bindings and calls.
        let submit = try #require(harness.definition?.component("submit_button"))
        let action = try #require(ActionDefinition(submit.properties["action"]))
        guard case let .event(event) = action else {
            Issue.record("Expected an event action")
            return
        }
        var resolved: JsonMap = [:]
        for (key, value) in event.context {
            resolved[key] = harness.evaluator.evaluate(value, in: harness.rootScope)
        }
        #expect(Json.string(resolved["formId"]) == "contact_form_1")
        #expect(Json.bool(resolved["isNewsletterSubscribed"]) == true)
        #expect(Json.string(resolved["rendererTime"]) == "Mon Feb 2, 2026 3:17 PM")
    }

    @Test("A deleteSurface message removes an example surface")
    func deleteSurface() throws {
        let harness = try ConformanceHarness(Fixtures.modal, surfaceId: "gallery-modal")
        harness.processor.handle(.deleteSurface(DeleteSurfaceMessage(surfaceId: "gallery-modal")))

        #expect(harness.processor.surfaceIds.isEmpty)
    }
}

/// Message payloads taken from the A2UI v1.0 specification examples.
@MainActor
private enum Fixtures {
    /// `specification/v1_0/catalogs/basic/examples/32_advanced-form-validator.json`
    static let advancedFormValidator = """
    [
      {
        "version": "1.0",
        "createSurface": {
          "surfaceId": "gallery-advanced-validator",
          "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json",
          "sendDataModel": true
        }
      },
      {
        "version": "1.0",
        "updateComponents": {
          "surfaceId": "gallery-advanced-validator",
          "components": [
            {"id": "root", "component": "Card", "child": "main_column"},
            {
              "id": "main_column",
              "component": "Column",
              "children": ["welcome_text", "email_field", "phone_field", "zip_field", "terms_checkbox", "submit_btn"],
              "align": "stretch"
            },
            {
              "id": "welcome_text",
              "component": "Text",
              "text": {
                "@call": "formatString",
                "args": {"value": "Hello! Today is ${formatDate(value: ${/now}, format: 'EEEE, MMMM d')}."}
              }
            },
            {
              "id": "email_field",
              "component": "TextField",
              "label": "Email Address",
              "value": {"@path": "/formData/email"},
              "checks": [
                {
                  "condition": {"@call": "email", "args": {"value": {"@path": "/formData/email"}}},
                  "message": "Invalid email format"
                }
              ]
            },
            {
              "id": "phone_field",
              "component": "TextField",
              "label": "Phone Number",
              "value": {"@path": "/formData/phone"},
              "checks": [
                {
                  "condition": {
                    "@call": "regex",
                    "args": {"value": {"@path": "/formData/phone"}, "pattern": "^\\\\+?[0-9]{10,15}$"}
                  },
                  "message": "Invalid phone format"
                }
              ]
            },
            {
              "id": "zip_field",
              "component": "TextField",
              "label": "Zip Code",
              "value": {"@path": "/formData/zip"},
              "checks": [
                {
                  "condition": {"@call": "regex", "args": {"value": {"@path": "/formData/zip"}, "pattern": "^[0-9]{5}$"}},
                  "message": "Must be exactly 5 digits"
                }
              ]
            },
            {
              "id": "terms_checkbox",
              "component": "CheckBox",
              "label": "I agree to the terms and conditions",
              "value": {"@path": "/formData/agree"}
            },
            {"id": "submit_btn_text", "component": "Text", "text": "Submit Registration"},
            {
              "id": "submit_btn",
              "component": "Button",
              "child": "submit_btn_text",
              "checks": [
                {
                  "condition": {
                    "@call": "and",
                    "args": {
                      "values": [
                        {"@path": "/formData/agree"},
                        {
                          "@call": "or",
                          "args": {
                            "values": [
                              {"@call": "required", "args": {"value": {"@path": "/formData/email"}}},
                              {"@call": "required", "args": {"value": {"@path": "/formData/phone"}}}
                            ]
                          }
                        },
                        {"@call": "required", "args": {"value": {"@path": "/formData/zip"}}}
                      ]
                    }
                  },
                  "message": "You must agree to terms AND provide either Email or Phone, plus a Zip code."
                }
              ],
              "action": {"event": {"name": "register", "context": {"data": {"@path": "/formData"}}}}
            }
          ]
        }
      },
      {
        "version": "1.0",
        "updateDataModel": {
          "surfaceId": "gallery-advanced-validator",
          "value": {
            "now": "2025-12-15T12:00:00Z",
            "formData": {"email": "", "phone": "", "zip": "", "agree": false}
          }
        }
      }
    ]
    """

    /// `specification/v1_0/catalogs/basic/examples/13_coffee-order.json`
    static let coffeeOrder = """
    [
      {
        "version": "1.0",
        "createSurface": {
          "surfaceId": "gallery-coffee-order",
          "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json",
          "sendDataModel": true
        }
      },
      {
        "version": "1.0",
        "updateComponents": {
          "surfaceId": "gallery-coffee-order",
          "components": [
            {"id": "root", "component": "Card", "child": "main_column"},
            {
              "id": "main_column",
              "component": "Column",
              "children": ["header", "items_list", "divider", "totals", "actions"]
            },
            {"id": "header", "component": "Row", "children": ["coffee_icon", "store_name"], "align": "center"},
            {"id": "coffee_icon", "component": "Icon", "name": "favorite"},
            {"id": "store_name", "component": "Text", "text": {"@path": "/storeName"}},
            {
              "id": "items_list",
              "component": "Column",
              "children": {"path": "/items", "componentId": "order_item_template"}
            },
            {
              "id": "order_item_template",
              "component": "Row",
              "children": ["item_details", "item_price"],
              "justify": "spaceBetween",
              "align": "start"
            },
            {"id": "item_details", "component": "Column", "children": ["item_name", "item_size"]},
            {"id": "item_name", "component": "Text", "text": {"@path": "name"}, "variant": "body"},
            {"id": "item_size", "component": "Text", "text": {"@path": "size"}, "variant": "caption"},
            {
              "id": "item_price",
              "component": "Text",
              "text": {"@call": "formatCurrency", "args": {"value": {"@path": "price"}, "currency": "USD"}},
              "variant": "body"
            },
            {"id": "divider", "component": "Divider"},
            {"id": "totals", "component": "Column", "children": ["total_row"]},
            {"id": "total_row", "component": "Row", "children": ["total_label", "total_value"], "justify": "spaceBetween"},
            {"id": "total_label", "component": "Text", "text": "#### Total"},
            {
              "id": "total_value",
              "component": "Text",
              "text": {"@call": "formatCurrency", "args": {"value": {"@path": "/total"}, "currency": "USD"}}
            },
            {"id": "actions", "component": "Row", "children": ["purchase_btn"]},
            {"id": "purchase_btn_text", "component": "Text", "text": "Purchase"},
            {
              "id": "purchase_btn",
              "component": "Button",
              "child": "purchase_btn_text",
              "action": {"event": {"name": "purchase", "context": {}}}
            }
          ]
        }
      },
      {
        "version": "1.0",
        "updateDataModel": {
          "surfaceId": "gallery-coffee-order",
          "value": {
            "storeName": "Sunrise Coffee",
            "items": [
              {"name": "Oat Milk Latte", "size": "Grande, Extra Shot", "price": 6.45},
              {"name": "Chocolate Croissant", "size": "Warmed", "price": 4.25}
            ],
            "subtotal": 10.7,
            "tax": 0.96,
            "total": 11.66
          }
        }
      }
    ]
    """

    /// `specification/v1_0/catalogs/basic/examples/34_child-list-template.json`
    static let childListTemplate = """
    [
      {
        "version": "1.0",
        "createSurface": {
          "surfaceId": "gallery-child-list-template",
          "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json",
          "sendDataModel": true
        }
      },
      {
        "version": "1.0",
        "updateComponents": {
          "surfaceId": "gallery-child-list-template",
          "components": [
            {"id": "root", "component": "Card", "child": "main_column"},
            {"id": "main_column", "component": "Column", "children": ["title_text", "item_list"], "align": "stretch"},
            {"id": "title_text", "component": "Text", "text": "### Dynamic Item List"},
            {"id": "item_list", "component": "List", "children": {"componentId": "item_row", "path": "/items"}},
            {"id": "item_row", "component": "Row", "children": ["item_name", "qty_label", "item_qty"]},
            {"id": "item_name", "component": "Text", "text": {"@path": "name"}},
            {"id": "qty_label", "component": "Text", "text": " - Qty: "},
            {"id": "item_qty", "component": "Text", "text": {"@path": "quantity"}}
          ]
        }
      },
      {
        "version": "1.0",
        "updateDataModel": {
          "surfaceId": "gallery-child-list-template",
          "value": {
            "items": [
              {"name": "Apple", "quantity": 10},
              {"name": "Banana", "quantity": 5},
              {"name": "Cherry", "quantity": 20}
            ]
          }
        }
      }
    ]
    """

    /// A `Modal` example, matching `36_modal.json`.
    static let modal = """
    [
      {
        "version": "1.0",
        "createSurface": {
          "surfaceId": "gallery-modal",
          "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json",
          "components": [
            {"id": "root", "component": "Modal", "trigger": "open_button", "content": "modal_content"},
            {
              "id": "open_button",
              "component": "Button",
              "child": "open_button_label",
              "variant": "primary",
              "action": {"event": {"name": "open_modal", "context": {}}}
            },
            {"id": "open_button_label", "component": "Text", "text": "Show details"},
            {"id": "modal_content", "component": "Text", "text": "### Details\\nEverything you need to know."}
          ]
        }
      }
    ]
    """

    /// The contact form stream from `docs/a2ui_protocol.md`, trimmed to the
    /// components the assertions use.
    static let contactForm = """
    [
      {
        "version": "1.0",
        "createSurface": {
          "surfaceId": "contact_form_1",
          "catalogId": "https://a2ui.org/specification/v1_0/catalogs/basic/catalog.json"
        }
      },
      {
        "version": "1.0",
        "updateComponents": {
          "surfaceId": "contact_form_1",
          "components": [
            {"id": "root", "component": "Card", "child": "form_container"},
            {
              "id": "form_container",
              "component": "Column",
              "children": ["header_row", "name_row", "email_group", "phone_group", "pref_group", "divider_1", "newsletter_checkbox", "submit_button"],
              "justify": "start",
              "align": "stretch"
            },
            {"id": "header_row", "component": "Row", "children": ["header_icon", "header_text"], "align": "center"},
            {"id": "header_icon", "component": "Icon", "name": "mail"},
            {"id": "header_text", "component": "Text", "text": "# Contact Us"},
            {"id": "name_row", "component": "Row", "children": ["first_name_group"], "justify": "spaceBetween"},
            {"id": "first_name_group", "component": "Column", "children": ["first_name_label", "first_name_field"], "weight": 1},
            {"id": "first_name_label", "component": "Text", "text": "First Name", "variant": "caption"},
            {
              "id": "first_name_field",
              "component": "TextField",
              "label": "First Name",
              "value": {"@path": "/contact/firstName"},
              "variant": "shortText"
            },
            {"id": "email_group", "component": "Column", "children": ["email_field"]},
            {
              "id": "email_field",
              "component": "TextField",
              "label": "Email",
              "value": {"@path": "/contact/email"},
              "variant": "shortText",
              "checks": [
                {
                  "condition": {"@call": "required", "args": {"value": {"@path": "/contact/email"}}},
                  "message": "Email is required."
                },
                {
                  "condition": {"@call": "email", "args": {"value": {"@path": "/contact/email"}}},
                  "message": "Please enter a valid email address."
                }
              ]
            },
            {"id": "phone_group", "component": "Column", "children": ["phone_field"]},
            {
              "id": "phone_field",
              "component": "TextField",
              "label": "Phone",
              "value": {"@path": "/contact/phone"},
              "variant": "shortText",
              "checks": [
                {
                  "condition": {
                    "@call": "regex",
                    "args": {"value": {"@path": "/contact/phone"}, "pattern": "^\\\\d{10}$"}
                  },
                  "message": "Phone number must be 10 digits."
                }
              ]
            },
            {"id": "pref_group", "component": "Column", "children": ["pref_picker"]},
            {
              "id": "pref_picker",
              "component": "ChoicePicker",
              "variant": "mutuallyExclusive",
              "options": [
                {"label": "Email", "value": "email"},
                {"label": "Phone", "value": "phone"},
                {"label": "SMS", "value": "sms"}
              ],
              "value": {"@path": "/contact/preference"}
            },
            {"id": "divider_1", "component": "Divider", "axis": "horizontal"},
            {
              "id": "newsletter_checkbox",
              "component": "CheckBox",
              "label": "Subscribe to our newsletter",
              "value": {"@path": "/contact/subscribe"}
            },
            {"id": "submit_button_label", "component": "Text", "text": "Send Message"},
            {
              "id": "submit_button",
              "component": "Button",
              "child": "submit_button_label",
              "variant": "primary",
              "action": {
                "event": {
                  "name": "submitContactForm",
                  "context": {
                    "formId": "contact_form_1",
                    "rendererTime": {
                      "@call": "formatDate",
                      "args": {"value": "2026-02-02T15:17:00Z", "format": "E MMM d, yyyy h:mm a"}
                    },
                    "isNewsletterSubscribed": {"@path": "/contact/subscribe"}
                  }
                }
              }
            }
          ]
        }
      },
      {
        "version": "1.0",
        "updateDataModel": {
          "surfaceId": "contact_form_1",
          "path": "/contact",
          "value": {
            "firstName": "John",
            "lastName": "Doe",
            "email": "john.doe@example.com",
            "phone": "1234567890",
            "preference": ["email"],
            "subscribe": true
          }
        }
      }
    ]
    """
}
