//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

/// The text and icon components of the A2UI basic catalog.
@available(iOS 15.0, macOS 12.0, *)
enum TextComponents {
    /// All text components, in catalog order.
    static var all: [ComponentDefinition] {
        [text, icon]
    }

    /// Displays text, optionally formatted with simple Markdown.
    static let text = ComponentDefinition(
        name: "Text",
        description: "Displays text. Simple Markdown formatting is supported.",
        properties: [
            "text": JsonSchema.dynamicString(
                description: "The text content to display. While simple Markdown formatting is supported "
                    + "(i.e. without HTML, images, or links), utilizing dedicated UI components is generally "
                    + "preferred for a richer and more structured presentation."
            ),
            "variant": JsonSchema.string(
                description: "A hint for the base text style.",
                enumValues: ["caption", "body"],
                defaultValue: "body"
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["text"],
        examples: [
            """
            [
              {"id": "root", "component": "Text", "text": "## Hello World"}
            ]
            """
        ]
    ) { context in
        AnyView(
            A2UIMarkdownText(
                text: context.string("text", default: ""),
                isCaption: context.option("variant", default: "body") == "caption"
            )
        )
    }

    /// Displays one of the catalog's system icons.
    static let icon = ComponentDefinition(
        name: "Icon",
        description: "Displays a system-provided icon from a predefined list.",
        properties: [
            "name": JsonSchema.oneOf(
                [
                    JsonSchema.string(enumValues: A2UIIcon.allNames),
                    JsonSchema.object(
                        properties: ["svgPath": JsonSchema.dynamicString()],
                        required: ["svgPath"],
                        additionalProperties: false
                    ),
                    JsonSchema.commonType("DataBinding")
                ],
                description: "The name of the icon to display."
            ),
            "weight": JsonSchema.weight()
        ],
        required: ["name"],
        examples: [
            """
            [
              {"id": "root", "component": "Icon", "name": "star"}
            ]
            """
        ]
    ) { context in
        // `name` may be a literal enum value, a data binding, or an object
        // carrying a raw SVG path. Only the first two forms can be rendered
        // with SF Symbols, so an unknown name degrades to a neutral glyph.
        let name: String?
        if let map = Json.map(context.component.property("name")), map["svgPath"] != nil {
            name = nil
            a2uiLogger.warning("Icon '\(context.id)' uses an svgPath, which this renderer does not support.")
        } else {
            name = context.string("name")
        }
        return AnyView(
            Image(systemName: A2UIIcon.systemName(for: name))
                .imageScale(.medium)
                .accessibilityLabel(Text(name ?? "icon"))
        )
    }
}

/// The icon names defined by the A2UI basic catalog.
///
/// Names are mapped onto SF Symbols so agent-provided icons look native.
@available(iOS 15.0, macOS 12.0, *)
enum A2UIIcon: String, CaseIterable {
    case accountCircle
    case add
    case arrowBack
    case arrowForward
    case attachFile
    case calendarToday
    case call
    case camera
    case check
    case close
    case delete
    case download
    case edit
    case event
    case error
    case fastForward
    case favorite
    case favoriteOff
    case folder
    case help
    case home
    case info
    case locationOn
    case lock
    case lockOpen
    case mail
    case menu
    case moreVert
    case moreHoriz
    case notificationsOff
    case notifications
    case pause
    case payment
    case person
    case phone
    case photo
    case play
    case print
    case refresh
    case rewind
    case search
    case send
    case settings
    case share
    case shoppingCart
    case skipNext
    case skipPrevious
    case star
    case starHalf
    case starOff
    case stop
    case upload
    case visibility
    case visibilityOff
    case volumeDown
    case volumeMute
    case volumeOff
    case volumeUp
    case warning

    /// The SF Symbol used to render this icon.
    var systemName: String {
        switch self {
        case .accountCircle: return "person.crop.circle"
        case .add: return "plus"
        case .arrowBack: return "arrow.backward"
        case .arrowForward: return "arrow.forward"
        case .attachFile: return "paperclip"
        case .calendarToday: return "calendar"
        case .call: return "phone"
        case .camera: return "camera"
        case .check: return "checkmark"
        case .close: return "xmark"
        case .delete: return "trash"
        case .download: return "arrow.down.circle"
        case .edit: return "pencil"
        case .event: return "calendar.badge.clock"
        case .error: return "exclamationmark.octagon"
        case .fastForward: return "forward.fill"
        case .favorite: return "heart.fill"
        case .favoriteOff: return "heart"
        case .folder: return "folder"
        case .help: return "questionmark.circle"
        case .home: return "house"
        case .info: return "info.circle"
        case .locationOn: return "location.fill"
        case .lock: return "lock"
        case .lockOpen: return "lock.open"
        case .mail: return "envelope"
        case .menu: return "line.3.horizontal"
        case .moreVert: return "ellipsis"
        case .moreHoriz: return "ellipsis"
        case .notificationsOff: return "bell.slash"
        case .notifications: return "bell"
        case .pause: return "pause.fill"
        case .payment: return "creditcard"
        case .person: return "person"
        case .phone: return "phone"
        case .photo: return "photo"
        case .play: return "play.fill"
        case .print: return "printer"
        case .refresh: return "arrow.clockwise"
        case .rewind: return "backward.fill"
        case .search: return "magnifyingglass"
        case .send: return "paperplane"
        case .settings: return "gearshape"
        case .share: return "square.and.arrow.up"
        case .shoppingCart: return "cart"
        case .skipNext: return "forward.end.fill"
        case .skipPrevious: return "backward.end.fill"
        case .star: return "star.fill"
        case .starHalf: return "star.leadinghalf.filled"
        case .starOff: return "star"
        case .stop: return "stop.fill"
        case .upload: return "arrow.up.circle"
        case .visibility: return "eye"
        case .visibilityOff: return "eye.slash"
        case .volumeDown: return "speaker.wave.1"
        case .volumeMute: return "speaker.slash"
        case .volumeOff: return "speaker"
        case .volumeUp: return "speaker.wave.3"
        case .warning: return "exclamationmark.triangle"
        }
    }

    /// Every icon name the catalog accepts.
    static var allNames: [String] {
        allCases.map { $0.rawValue }.sorted()
    }

    /// Maps an A2UI icon name onto an SF Symbol.
    /// Unknown names fall back to a question mark glyph.
    @MainActor
    static func systemName(for name: String?) -> String {
        guard let name, let icon = A2UIIcon(rawValue: name) else {
            if let name, !name.isEmpty {
                a2uiLogger.warning("Unknown icon name '\(name)'.")
            }
            return "questionmark.circle"
        }
        return icon.systemName
    }
}
