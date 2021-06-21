//
// Copyright © 2021 Stream.io Inc. All rights reserved.
//

import UIKit

/// A view that draws a gradient
open class GradientView: _View {
    /// A type representing gradient drawing options
    public struct Content {
        /// A type representing gradient direction
        public enum Direction {
            case vertical
            case horizontal
            case topRightBottomLeft
            case topLeftBottomRight
            case custom(startPoint: CGPoint, endPoint: CGPoint)
        }
        
        /// The gradient direction.
        public var direction: Direction
        /// The gradient colors.
        public var colors: [UIColor]
        /// The gradient color locations.
        public var locations: [CGFloat]?
        
        public init(
            direction: Direction,
            colors: [UIColor],
            locations: [CGFloat]? = nil
        ) {
            self.direction = direction
            self.colors = colors
            self.locations = locations
        }
    }
    
    /// The gradient to draw
    open var content: Content? {
        didSet { updateContentIfNeeded() }
    }
    
    override open class var layerClass: AnyClass {
        CAGradientLayer.self
    }
    
    /// Returns the layer casted to gradient layer.
    open var gradientLayer: CAGradientLayer {
        layer as! CAGradientLayer
    }
    
    override open func updateContent() {
        super.updateContent()
        
        gradientLayer.colors = content?.colors.map(\.cgColor)
        gradientLayer.startPoint = content?.direction.startPoint ?? .zero
        gradientLayer.endPoint = content?.direction.endPoint ?? .zero
        gradientLayer.locations = content?.locations.map { $0.map(NSNumber.init) }
    }
}

extension GradientView.Content.Direction {
    var startPoint: CGPoint {
        switch self {
        case .topRightBottomLeft:
            return .init(x: 0.0, y: 1.0)
        case .topLeftBottomRight:
            return .init(x: 0.0, y: 0.0)
        case .horizontal:
            return .init(x: 0.0, y: 0.5)
        case .vertical:
            return .init(x: 0.0, y: 0.0)
        case let .custom(startPoint, _):
            return startPoint
        }
    }
    
    var endPoint: CGPoint {
        switch self {
        case .topRightBottomLeft:
            return .init(x: 1.0, y: 0.0)
        case .topLeftBottomRight:
            return .init(x: 1, y: 1)
        case .horizontal:
            return .init(x: 1.0, y: 0.5)
        case .vertical:
            return .init(x: 0.0, y: 1.0)
        case let .custom(_, endPoint):
            return endPoint
        }
    }
}
