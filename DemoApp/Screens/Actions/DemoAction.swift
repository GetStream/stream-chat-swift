//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// An entry of a hierarchical actions menu. It is either a leaf action or a nested submenu.
enum DemoAction {
    case action(DemoActionItem)
    case group(DemoActionGroup)
}

/// A leaf action which performs `handler` when selected.
struct DemoActionItem {
    let title: String
    let subtitle: String?
    let isEnabled: Bool
    let isDestructive: Bool
    let handler: () -> Void

    func replacingSubtitle(_ subtitle: String?) -> DemoActionItem {
        DemoActionItem(
            title: title,
            subtitle: subtitle,
            isEnabled: isEnabled,
            isDestructive: isDestructive,
            handler: handler
        )
    }
}

/// A submenu containing other actions and submenus, split into sections.
struct DemoActionGroup {
    let title: String
    let subtitle: String?
    let icon: String?
    let sections: [DemoActionSection]

    init(title: String, subtitle: String? = nil, icon: String? = nil, sections: [DemoActionSection]) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.sections = sections.filter { !$0.items.isEmpty }
    }

    var isEmpty: Bool {
        sections.isEmpty
    }

    var numberOfActions: Int {
        sections.reduce(0) { partial, section in
            partial + section.items.reduce(0) { sectionPartial, entry in
                switch entry {
                case .action:
                    return sectionPartial + 1
                case .group(let group):
                    return sectionPartial + group.numberOfActions
                }
            }
        }
    }

    /// All the leaf actions of the whole hierarchy, each one paired with the path leading to it.
    func searchableItems(parentPath: [String] = []) -> [DemoActionSearchResult] {
        sections.flatMap { section -> [DemoActionSearchResult] in
            let path = parentPath + [section.title].compactMap { $0 }
            return section.items.flatMap { entry -> [DemoActionSearchResult] in
                switch entry {
                case .action(let item):
                    return [DemoActionSearchResult(item: item, breadcrumb: path.joined(separator: " › "))]
                case .group(let group):
                    return group.searchableItems(parentPath: parentPath + [group.title])
                }
            }
        }
    }
}

/// A group of entries displayed under an optional header.
struct DemoActionSection {
    let title: String?
    let items: [DemoAction]

    init(_ title: String? = nil, items: [DemoAction?]) {
        self.title = title
        self.items = items.compactMap { $0 }
    }
}

struct DemoActionSearchResult {
    let item: DemoActionItem
    let breadcrumb: String
}

extension DemoAction {
    static func item(
        _ title: String,
        subtitle: String? = nil,
        isVisible: Bool = true,
        isEnabled: Bool = true,
        isDestructive: Bool = false,
        handler: @escaping () -> Void
    ) -> DemoAction? {
        guard isVisible else { return nil }
        return .action(DemoActionItem(
            title: title,
            subtitle: subtitle,
            isEnabled: isEnabled,
            isDestructive: isDestructive,
            handler: handler
        ))
    }

    static func menu(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isVisible: Bool = true,
        sections: [DemoActionSection]
    ) -> DemoAction? {
        guard isVisible else { return nil }
        let group = DemoActionGroup(title: title, subtitle: subtitle, icon: icon, sections: sections)
        return group.isEmpty ? nil : .group(group)
    }

    static func menu(
        _ title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        isVisible: Bool = true,
        items: [DemoAction?]
    ) -> DemoAction? {
        menu(title, subtitle: subtitle, icon: icon, isVisible: isVisible, sections: [DemoActionSection(items: items)])
    }
}
