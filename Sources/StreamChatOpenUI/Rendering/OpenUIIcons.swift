//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Maps lucide icon names (used by OpenUI's `Icon(name, category)`) to SF Symbols.
///
/// Resolution mirrors the reference renderer: the exact name, then the category's representative
/// icon, then a generic fallback.
@available(iOS 17.0, macOS 14.0, *)
enum OpenUIIcons {
    /// Resolves a lucide name (and optional category) to an SF Symbol name that exists on this platform.
    static func symbolName(for name: String?, category: String? = nil) -> String {
        let key = (name ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if let symbol = lucideToSymbol[key], symbolExists(symbol) { return symbol }
        // Accept SF Symbol names directly.
        if !key.isEmpty, symbolExists(key) { return key }
        // Loose matching: drop numeric/variant suffixes such as "-2", "-off", "-circle".
        for candidate in looseCandidates(key) {
            if let symbol = lucideToSymbol[candidate], symbolExists(symbol) { return symbol }
        }
        let categoryKey = (category ?? "").trimmingCharacters(in: .whitespaces).lowercased()
        if let fallback = categoryFallbacks[categoryKey], let symbol = lucideToSymbol[fallback], symbolExists(symbol) {
            return symbol
        }
        return "circle.dashed"
    }

    // What VoiceOver reads for an icon: its name in words, such as "arrow right" for `arrow-right`.
    static func accessibilityName(for name: String?) -> String {
        (name ?? "")
            .split { $0 == "-" || $0 == "." || $0 == "_" || $0 == " " }
            .filter { Int($0) == nil }
            .joined(separator: " ")
            .lowercased()
    }

    private static func looseCandidates(_ key: String) -> [String] {
        var parts = key.split(separator: "-").map(String.init)
        var candidates: [String] = []
        while parts.count > 1 {
            parts.removeLast()
            candidates.append(parts.joined(separator: "-"))
        }
        let withoutDigits = key.split(separator: "-").filter { Int($0) == nil }.joined(separator: "-")
        if withoutDigits != key { candidates.insert(withoutDigits, at: 0) }
        return candidates
    }

    private static let cacheLock = NSLock()
    private nonisolated(unsafe) static var existenceCache: [String: Bool] = [:]

    static func symbolExists(_ name: String) -> Bool {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        if let cached = existenceCache[name] { return cached }
        #if canImport(UIKit)
        let exists = UIImage(systemName: name) != nil
        #elseif canImport(AppKit)
        let exists = NSImage(systemSymbolName: name, accessibilityDescription: nil) != nil
        #else
        let exists = false
        #endif
        existenceCache[name] = exists
        return exists
    }

    /// Category → representative lucide icon (from the reference `categoryFallbacks`).
    static let categoryFallbacks: [String: String] = [
        "accessibility": "accessibility", "account": "user", "animals": "cat", "arrows": "arrow-right",
        "brands": "box", "buildings": "building", "charts": "chart-line", "communication": "message-square",
        "connectivity": "wifi", "cursors": "mouse-pointer", "design": "palette", "development": "code",
        "devices": "smartphone", "emoji": "smile", "files": "file", "finance": "dollar-sign",
        "food-beverage": "cooking-pot", "gaming": "gamepad", "home": "house", "layout": "layout",
        "mail": "mail", "math": "calculator", "medical": "heart-pulse", "multimedia": "music",
        "nature": "tree-pine", "navigation": "map-pin", "notifications": "bell", "people": "users",
        "photography": "camera", "science": "microscope", "seasons": "sun", "security": "shield",
        "shapes": "circle", "shopping": "shopping-cart", "social": "share-2", "sports": "trophy",
        "sustainability": "leaf", "text": "type", "time": "clock", "tools": "wrench",
        "transportation": "car", "travel": "plane", "weather": "cloud"
    ]

    /// lucide name → SF Symbol.
    static let lucideToSymbol: [String: String] = [
        // Arrows & navigation
        "arrow-right": "arrow.right", "arrow-left": "arrow.left", "arrow-up": "arrow.up", "arrow-down": "arrow.down",
        "arrow-up-right": "arrow.up.right", "arrow-down-right": "arrow.down.right", "arrow-up-left": "arrow.up.left",
        "chevron-right": "chevron.right", "chevron-left": "chevron.left", "chevron-up": "chevron.up", "chevron-down": "chevron.down",
        "chevrons-right": "chevron.right.2", "chevrons-left": "chevron.left.2", "move": "arrow.up.and.down.and.arrow.left.and.right",
        "external-link": "arrow.up.right.square", "link": "link", "link-2": "link", "refresh-cw": "arrow.clockwise",
        "rotate-cw": "arrow.clockwise", "rotate-ccw": "arrow.counterclockwise", "repeat": "repeat", "shuffle": "shuffle",
        "undo": "arrow.uturn.backward", "redo": "arrow.uturn.forward", "corner-down-right": "arrow.turn.down.right",
        "navigation": "location.north.fill", "compass": "safari", "map": "map", "map-pin": "mappin.and.ellipse",
        "map-pinned": "mappin.and.ellipse", "locate": "location", "route": "point.topleft.down.to.point.bottomright.curvepath",
        "signpost": "signpost.right", "milestone": "signpost.right", "flag": "flag", "globe": "globe", "earth": "globe.europe.africa",
        "mouse-pointer": "cursorarrow", "pointer": "hand.point.up.left",
        // Status & feedback
        "check": "checkmark", "check-circle": "checkmark.circle", "circle-check": "checkmark.circle", "check-circle-2": "checkmark.circle.fill",
        "circle-check-big": "checkmark.circle", "badge-check": "checkmark.seal", "x": "xmark", "x-circle": "xmark.circle",
        "circle-x": "xmark.circle", "plus": "plus", "plus-circle": "plus.circle", "circle-plus": "plus.circle", "minus": "minus",
        "minus-circle": "minus.circle", "circle-minus": "minus.circle", "alert-triangle": "exclamationmark.triangle",
        "triangle-alert": "exclamationmark.triangle", "alert-circle": "exclamationmark.circle", "circle-alert": "exclamationmark.circle",
        "info": "info.circle", "help-circle": "questionmark.circle", "circle-help": "questionmark.circle", "ban": "nosign",
        "loader": "hourglass", "hourglass": "hourglass", "thumbs-up": "hand.thumbsup", "thumbs-down": "hand.thumbsdown",
        "star": "star", "stars": "sparkles", "sparkles": "sparkles", "sparkle": "sparkle", "heart": "heart",
        "heart-pulse": "heart.text.square", "activity": "waveform.path.ecg", "zap": "bolt", "flame": "flame", "fire": "flame",
        "award": "rosette", "medal": "medal", "trophy": "trophy", "crown": "crown", "gem": "diamond", "target": "target",
        "goal": "flag.checkered", "rocket": "paperplane", "lightbulb": "lightbulb", "bell": "bell", "bell-ring": "bell.badge",
        "circle": "circle", "circle-dot": "smallcircle.filled.circle", "square": "square", "triangle": "triangle",
        "hexagon": "hexagon", "diamond": "diamond", "dot": "circle.fill",
        // People & communication
        "user": "person", "users": "person.2", "user-plus": "person.badge.plus", "user-minus": "person.badge.minus",
        "user-check": "person.crop.circle.badge.checkmark", "user-round": "person.crop.circle", "users-round": "person.3",
        "contact": "person.crop.rectangle", "baby": "figure.and.child.holdinghands", "smile": "face.smiling",
        "message-square": "bubble.left", "message-circle": "bubble.left", "messages-square": "bubble.left.and.bubble.right",
        "mail": "envelope", "send": "paperplane", "phone": "phone", "phone-call": "phone.arrow.up.right", "video": "video",
        "mic": "mic", "megaphone": "megaphone", "share": "square.and.arrow.up", "share-2": "square.and.arrow.up",
        "at-sign": "at", "inbox": "tray", "headphones": "headphones", "speech": "text.bubble", "languages": "character.bubble",
        // Time & calendar
        "clock": "clock", "clock-3": "clock", "timer": "timer", "alarm-clock": "alarm", "calendar": "calendar",
        "calendar-days": "calendar", "calendar-check": "calendar.badge.checkmark", "calendar-clock": "calendar.badge.clock",
        "calendar-range": "calendar", "history": "clock.arrow.circlepath", "watch": "applewatch",
        // Finance & commerce
        "dollar-sign": "dollarsign", "circle-dollar-sign": "dollarsign.circle", "euro": "eurosign", "pound-sterling": "sterlingsign",
        "japanese-yen": "yensign", "indian-rupee": "indianrupeesign", "coins": "dollarsign.circle", "banknote": "banknote",
        "credit-card": "creditcard", "wallet": "wallet.pass", "piggy-bank": "banknote", "receipt": "doc.text", "landmark": "building.columns",
        "shopping-cart": "cart", "shopping-bag": "bag", "store": "storefront", "tag": "tag", "tags": "tag", "ticket": "ticket",
        "percent": "percent", "badge-percent": "percent", "gift": "gift", "package": "shippingbox", "box": "shippingbox",
        "boxes": "shippingbox", "truck": "box.truck", "barcode": "barcode", "scale": "scalemass",
        // Charts & data
        "chart-line": "chart.xyaxis.line", "line-chart": "chart.xyaxis.line", "chart-bar": "chart.bar", "bar-chart": "chart.bar",
        "bar-chart-2": "chart.bar", "bar-chart-3": "chart.bar", "chart-column": "chart.bar", "chart-pie": "chart.pie",
        "pie-chart": "chart.pie", "chart-area": "chart.line.uptrend.xyaxis", "trending-up": "chart.line.uptrend.xyaxis",
        "trending-down": "chart.line.downtrend.xyaxis", "gauge": "gauge.with.dots.needle.33percent", "database": "cylinder",
        "server": "server.rack", "table": "tablecells", "sheet": "tablecells", "list": "list.bullet", "list-checks": "checklist",
        "list-ordered": "list.number", "layout": "rectangle.3.group", "layout-grid": "square.grid.2x2", "grid": "square.grid.3x3",
        "kanban": "rectangle.split.3x1", "filter": "line.3.horizontal.decrease.circle", "sliders": "slider.horizontal.3",
        "sliders-horizontal": "slider.horizontal.3", "calculator": "plus.forwardslash.minus", "sigma": "sum", "hash": "number",
        // Files & content
        "file": "doc", "file-text": "doc.text", "files": "doc.on.doc", "folder": "folder", "folder-open": "folder",
        "clipboard": "clipboard", "clipboard-list": "list.clipboard", "notebook": "book.closed", "book": "book",
        "book-open": "book", "bookmark": "bookmark", "newspaper": "newspaper", "pen": "pencil", "pencil": "pencil",
        "edit": "square.and.pencil", "type": "textformat", "text": "text.alignleft", "quote": "quote.opening",
        "image": "photo", "images": "photo.on.rectangle", "camera": "camera", "palette": "paintpalette", "brush": "paintbrush",
        "paintbrush": "paintbrush", "figma": "pencil.and.outline", "download": "arrow.down.circle", "upload": "arrow.up.circle",
        "save": "square.and.arrow.down", "copy": "doc.on.doc", "trash": "trash", "trash-2": "trash", "archive": "archivebox",
        "printer": "printer", "search": "magnifyingglass", "zoom-in": "plus.magnifyingglass", "eye": "eye", "eye-off": "eye.slash",
        // Development & devices
        "code": "chevron.left.forwardslash.chevron.right", "code-2": "chevron.left.forwardslash.chevron.right",
        "terminal": "terminal", "bug": "ladybug", "git-branch": "arrow.triangle.branch", "github": "chevron.left.forwardslash.chevron.right",
        "cpu": "cpu", "smartphone": "iphone", "tablet": "ipad", "laptop": "laptopcomputer", "monitor": "desktopcomputer",
        "tv": "tv", "keyboard": "keyboard", "mouse": "computermouse", "wifi": "wifi", "bluetooth": "dot.radiowaves.left.and.right",
        "battery": "battery.100", "plug": "powerplug", "power": "power", "radio": "radio", "satellite": "antenna.radiowaves.left.and.right",
        "cloud": "cloud", "cloud-upload": "icloud.and.arrow.up", "settings": "gearshape", "settings-2": "gearshape.2",
        "cog": "gearshape", "wrench": "wrench.adjustable", "hammer": "hammer", "tool": "wrench.and.screwdriver",
        "construction": "cone", "lock": "lock", "unlock": "lock.open", "key": "key", "shield": "shield", "shield-check": "checkmark.shield",
        "fingerprint": "touchid", "scan": "viewfinder", "qr-code": "qrcode", "bot": "brain", "brain": "brain", "microscope": "microscope",
        "flask-conical": "flask", "atom": "atom", "dna": "allergens",
        // Media
        "music": "music.note", "disc-3": "opticaldisc", "disc": "opticaldisc", "film": "film", "clapperboard": "film",
        "play": "play", "pause": "pause", "volume-2": "speaker.wave.2", "gamepad": "gamecontroller", "gamepad-2": "gamecontroller",
        "dice": "dice", "puzzle": "puzzlepiece", "podcast": "mic",
        // Home, buildings & places
        "home": "house", "house": "house", "building": "building", "building-2": "building.2", "hotel": "bed.double",
        "bed": "bed.double", "bed-double": "bed.double", "school": "graduationcap", "graduation-cap": "graduationcap",
        "hospital": "cross.case", "church": "building.columns", "castle": "building.columns", "factory": "building.2",
        "warehouse": "house.lodge", "tent": "tent", "sofa": "sofa", "lamp": "lamp.desk", "door-open": "door.left.hand.open",
        "key-round": "key", "briefcase": "briefcase", "briefcase-business": "briefcase",
        // Travel & transportation
        "plane": "airplane", "plane-takeoff": "airplane.departure", "plane-landing": "airplane.arrival", "car": "car",
        "car-front": "car.side", "bus": "bus", "train": "tram", "train-front": "train.side.front.car", "tram-front": "tram",
        "ship": "ferry", "sailboat": "sailboat", "bike": "bicycle", "bicycle": "bicycle", "fuel": "fuelpump", "parking": "parkingsign",
        "luggage": "suitcase.rolling", "backpack": "backpack", "passport": "person.text.rectangle", "umbrella": "beach.umbrella",
        "palmtree": "beach.umbrella", "tree-palm": "beach.umbrella", "anchor": "anchor", "footprints": "shoeprints.fill",
        // Food & drink
        "utensils": "fork.knife", "utensils-crossed": "fork.knife", "chef-hat": "frying.pan", "cooking-pot": "frying.pan",
        "soup": "takeoutbag.and.cup.and.straw", "coffee": "cup.and.saucer", "cup-soda": "cup.and.straw", "wine": "wineglass",
        "beer": "mug", "martini": "wineglass", "pizza": "fork.knife", "sandwich": "fork.knife", "salad": "leaf",
        "apple": "applelogo", "cherry": "leaf", "carrot": "carrot", "egg": "oval", "fish": "fish", "drumstick": "fork.knife",
        "croissant": "birthday.cake", "cake": "birthday.cake", "cookie": "circle.hexagongrid", "ice-cream": "snowflake",
        "candy": "gift", "milk": "waterbottle", "wheat": "leaf", "flame-kindling": "flame", "refrigerator": "refrigerator",
        "microwave": "microwave", "timer-reset": "timer",
        // Nature, weather & seasons
        "sun": "sun.max", "moon": "moon", "sunrise": "sunrise", "sunset": "sunset", "cloud-rain": "cloud.rain",
        "cloud-snow": "cloud.snow", "cloud-sun": "cloud.sun", "cloud-lightning": "cloud.bolt", "cloud-drizzle": "cloud.drizzle",
        "snowflake": "snowflake", "wind": "wind", "thermometer": "thermometer.medium", "droplet": "drop", "droplets": "drop",
        "waves": "water.waves", "mountain": "mountain.2", "mountain-snow": "mountain.2", "tree-pine": "tree", "tree": "tree",
        "trees": "tree", "leaf": "leaf", "flower": "camera.macro", "flower-2": "camera.macro", "sprout": "leaf",
        "recycle": "arrow.3.trianglepath", "earth-lock": "globe", "rainbow": "rainbow",
        // Animals
        "cat": "cat", "dog": "dog", "paw-print": "pawprint", "bird": "bird", "rabbit": "hare", "turtle": "tortoise",
        // Health & sports
        "stethoscope": "stethoscope", "pill": "pills", "syringe": "syringe", "dumbbell": "dumbbell", "bike-2": "bicycle",
        "person-standing": "figure.stand", "accessibility": "accessibility", "running": "figure.run", "swimming": "figure.pool.swim",
        "volleyball": "volleyball", "football": "football", "trophy-2": "trophy",
        // Misc
        "user-cog": "person.crop.circle.badge", "log-in": "rectangle.portrait.and.arrow.right", "log-out": "rectangle.portrait.and.arrow.right",
        "menu": "line.3.horizontal", "more-horizontal": "ellipsis", "ellipsis": "ellipsis", "grip": "square.grid.3x3",
        "maximize": "arrow.up.left.and.arrow.down.right", "minimize": "arrow.down.right.and.arrow.up.left",
        "layers": "square.3.layers.3d", "component": "square.on.square", "magnet": "magnet", "paperclip": "paperclip",
        "glasses": "eyeglasses", "shirt": "tshirt", "scissors": "scissors", "umbrella-off": "umbrella", "infinity": "infinity"
    ]
}

/// Renders an `Icon` element value (or a lucide name) as an SF Symbol.
@available(iOS 17.0, macOS 14.0, *)
struct OpenUIIconImage: View {
    let name: String?
    let category: String?

    init(name: String?, category: String? = nil) {
        self.name = name
        self.category = category
    }

    /// From an `Icon(name, category)` element.
    init(element: ElementNode?) {
        self.name = element?.props["name"]?.stringValue
        self.category = element?.props["category"]?.stringValue
    }

    var body: some View {
        let label = OpenUIIcons.accessibilityName(for: name)
        Image(systemName: OpenUIIcons.symbolName(for: name, category: category))
            .accessibilityLabel(Text(label))
            .accessibilityHidden(label.isEmpty)
    }
}
