//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

@testable import StreamChat
import StreamChatTestTools
@testable import StreamChatUI
import SwiftUI
import XCTest

public enum DescriptionPosition {
    case top, left, bottom, right
    case topLeft, topRight
    case bottomLeft, bottomRight
}

/// Annotation of a view, describes what color should be used for the description labels, lines which point to them and what should be position of label describing it.
public struct Annotation {
    /// A subview of UIComponent which will be annotated
    let view: UIView
    /// Color of line pointing to description label showing its property name
    let lineColor: UIColor
    /// Color of label showing property name, by default is nil so dark/light trait in the label is set automatically allowing dark mode to adapt.
    /// tip: Use color which is in contrast with both dark and light environment.
    let textColor: UIColor?
    /// Color to highlight the subview of UIComponent
    let highlightColor: UIColor?
    /// Whether the subview should have description of its property name inside the UIComponent
    let isNameIncluded: Bool
    /// Position of the label describing the property name,
    /// see `DescriptionPosition` enumeration and sample test `test_generateDocs_channelListItemView_namedLabelsWithPointers`
    let descriptionLabelPosition: DescriptionPosition?
    
    init(
        view: UIView,
        lineColor: UIColor = .blue,
        textColor: UIColor? = nil,
        highlightColor: UIColor? = nil,
        isNameIncluded: Bool = true,
        descriptionLabelPosition: DescriptionPosition?
    ) {
        self.view = view
        self.lineColor = lineColor
        self.textColor = textColor
        self.highlightColor = highlightColor
        self.isNameIncluded = isNameIncluded
        self.descriptionLabelPosition = descriptionLabelPosition
    }
}

/// Generates documentation for given UIView subclass.
///
/// This method creates canvas with size of 700x700 which will be used as background for annotating the views subviews. After creating the canvas,
/// it generates either highlighting given elements or describing property names in the view with pointing lines.
/// - Parameters:
///   - view: Parent view which we want to annotate containing subviews to describe
///   - annotations: Annotation structs containing details which subviews we want to describe and how
///   - name: Name of the snapshot documentation.
///   - variants: Variants to snapshot, this is to support dark mode.
///   - file: File reference which will be passed to snapshot to generate folder if needed.
/// - Returns: A UIView instance which contains all annotations and possibly description of properties outside the annotated view.
func generateDocs(
    for view: UIView,
    parentView: UIView? = nil,
    annotations: [Annotation],
    name: String,
    variants: [SnapshotVariant],
    file: StaticString = #file
) {
    let container = UIView().withoutAutoresizingMaskConstraints
    container.backgroundColor = .clear
    
    container.addSubview(view.withoutAutoresizingMaskConstraints)
    view.centerYAnchor.constraint(equalTo: container.centerYAnchor).isActive = true
    view.centerXAnchor.constraint(equalTo: container.centerXAnchor).isActive = true
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor.gray.cgColor

    container.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 3).isActive = true
    container.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 3).isActive = true
    
    container.layoutIfNeeded()
    for annotation in annotations {
        // Create labels describing the properties if needed
        if let position = annotation.descriptionLabelPosition, annotation.isNameIncluded {
            createLineAndLabelWithPropertyName(
                for: [annotation.view: position],
                in: container,
                parentView: parentView ?? view,
                lineColor: annotation.lineColor,
                textColor: annotation.textColor
            )
        }
        
        // Highlight the given view/container if needed
        if let highlightColor = annotation.highlightColor {
            annotation.view.backgroundColor = highlightColor
        }
    }
    AssertSnapshot(container, variants: variants, file: file, function: name)
}

private func createLineAndLabelWithPropertyName(
    for subviewsWithPosition: [UIView: DescriptionPosition],
    in container: UIView,
    parentView: UIView,
    lineColor: UIColor,
    textColor: UIColor?
) {
    let lineDistance: CGFloat = 50
    
    for (view, position) in subviewsWithPosition {
        view.layer.borderWidth = 1
        view.layer.borderColor = lineColor.cgColor
        
        let translated = view.convert(view.bounds, to: container)
        var end: CGPoint
        
        let mirror = Mirror(reflecting: parentView)
        let mirroredView = mirror.children.first { $0.value as? UIView === view }
        
        let propertyDescription = mirroredView!.label!.deletingPrefix("$__lazy_storage_$_")
        
        // Get fontSize and size of the text to adjust position of the label:
        let descriptionLabelSize = (propertyDescription as NSString).size(withAttributes: [.font: UILabel().font!])
        
        switch position {
        case .top:
            end = addLine(
                fromPoint: .init(x: translated.midX, y: translated.minY),
                toPoint: .init(x: translated.midX, y: translated.minY - lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: -descriptionLabelSize.width / 2, dy: -descriptionLabelSize.height)
        case .left:
            end = addLine(
                fromPoint: .init(x: translated.minX, y: translated.midY),
                toPoint: .init(x: translated.midX - lineDistance, y: translated.midY),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: -descriptionLabelSize.width, dy: -descriptionLabelSize.height / 2)
        case .bottom:
            end = addLine(
                fromPoint: .init(x: translated.midX, y: translated.maxY),
                toPoint: .init(x: translated.midX, y: translated.maxY + lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: -descriptionLabelSize.width / 2, dy: -descriptionLabelSize.height / 2)
        case .right:
            end = addLine(
                fromPoint: .init(x: translated.maxX, y: translated.midY),
                toPoint: .init(x: translated.maxX + lineDistance, y: translated.midY),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: 0, dy: -descriptionLabelSize.height / 2)
        case .topLeft:
            end = addLine(
                fromPoint: .init(x: translated.minX, y: translated.minY),
                toPoint: .init(x: translated.minX - lineDistance, y: translated.minY - lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: -descriptionLabelSize.width, dy: -descriptionLabelSize.height / 2)
        case .topRight:
            end = addLine(
                fromPoint: .init(x: translated.maxX, y: translated.minY),
                toPoint: .init(x: translated.maxX + lineDistance, y: translated.minY - lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: 0, dy: -descriptionLabelSize.height / 2)
        case .bottomLeft:
            end = addLine(
                fromPoint: .init(x: translated.minX, y: translated.maxY),
                toPoint: .init(x: translated.minX - lineDistance, y: translated.maxY + lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: -descriptionLabelSize.width, dy: -descriptionLabelSize.height / 2)
        case .bottomRight:
            end = addLine(
                fromPoint: .init(x: translated.maxX, y: translated.maxY),
                toPoint: .init(x: translated.maxX + lineDistance, y: translated.maxY + lineDistance),
                in: container,
                color: lineColor
            )
            .offsetBy(dx: 0, dy: -descriptionLabelSize.height / 2)
        }

        let descriptionLabel = UILabel(frame: .init(origin: end, size: .zero))
        
        descriptionLabel.text = mirroredView?.label?.deletingPrefix("$__lazy_storage_$_") ?? "Should never happen"
        descriptionLabel.sizeToFit()
        
        container.addSubview(descriptionLabel)
        if let textColor = textColor {
            descriptionLabel.textColor = textColor
        }
    }
}

private func addLine(fromPoint start: CGPoint, toPoint end: CGPoint, in container: UIView, color: UIColor) -> CGPoint {
    let line = CAShapeLayer()
    let linePath = UIBezierPath()
    linePath.move(to: start)
    linePath.addLine(to: end)
    line.path = linePath.cgPath
    line.strokeColor = color.cgColor
    line.fillColor = color.cgColor
    line.lineWidth = 0.5
    container.layer.addSublayer(line)
    
    return end
}

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard hasPrefix(prefix) else { return self }
        return String(dropFirst(prefix.count))
    }
}

public extension _ChatChannel {
    /// Creates a new `_ChatChannel` object from the provided data.
    static func documentationMock(
        cid: ChannelId,
        name: String? = "channelName",
        imageURL: URL? = XCTestCase.TestImages.yoda.url,
        lastMessageAt: Date? = .init(timeIntervalSince1970: 1_168_332_060),
        createdAt: Date = .init(timeIntervalSince1970: 1_168_332_060),
        updatedAt: Date = .init(timeIntervalSince1970: 1_168_332_060),
        deletedAt: Date? = nil,
        createdBy: _ChatUser<ExtraData.User>? = nil,
        config: ChannelConfig = .mock(),
        isFrozen: Bool = false,
        lastActiveMembers: [_ChatChannelMember<ExtraData.User>] = [],
        membership: _ChatChannelMember<ExtraData.User>? = nil,
        currentlyTypingUsers: Set<_ChatUser<ExtraData.User>> = [],
        lastActiveWatchers: [_ChatUser<ExtraData.User>] = [],
        unreadCount: ChannelUnreadCount = .noUnread,
        watcherCount: Int = 0,
        memberCount: Int = 2,
        reads: [_ChatChannelRead<ExtraData>] = [],
        extraData: ExtraData.Channel = .defaultValue,
        latestMessages: [_ChatMessage<ExtraData>] = [],
        muteDetails: MuteDetails? = nil
    ) -> Self {
        self.init(
            cid: cid,
            name: name,
            imageURL: imageURL,
            lastMessageAt: lastMessageAt,
            createdAt: createdAt,
            updatedAt: updatedAt,
            deletedAt: deletedAt,
            createdBy: createdBy,
            config: config,
            isFrozen: isFrozen,
            lastActiveMembers: { lastActiveMembers },
            membership: membership,
            currentlyTypingUsers: currentlyTypingUsers,
            lastActiveWatchers: { lastActiveWatchers },
            unreadCount: { unreadCount },
            watcherCount: watcherCount,
            memberCount: memberCount,
            reads: reads,
            extraData: extraData,
            latestMessages: { latestMessages },
            muteDetails: { muteDetails },
            underlyingContext: nil
        )
    }
}
