//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation
import StreamChat
import UIKit

public class AudioVisualizationView: _View, ComponentsProvider, AppearanceProvider {
    public enum AudioVisualizationMode {
        case read
        case write
    }

    private enum LevelBarType {
        case upper
        case lower
        case single
    }

    public enum FillType {
        case gradient
        case full
    }

    public var meteringLevelBarWidth: CGFloat = 1.5 {
        didSet {
            setNeedsDisplay()
        }
    }

    public var meteringLevelBarInterItem: CGFloat = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    public var meteringLevelBarCornerRadius: CGFloat = 0.75 {
        didSet {
            setNeedsDisplay()
        }
    }

    public var meteringLevelBarSingleStick: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    public var audioVisualizationMode: AudioVisualizationMode = .read

    public var audioVisualizationFillType: FillType = .gradient

    // Specify a `gradientPercentage` to have the width of gradient be that percentage of the view width (starting from left)
    // The rest of the screen will be filled by `self.gradientStartColor` to display nicely.
    // Do not specify any `gradientPercentage` for gradient calculating fitting size automatically.
    public var currentGradientPercentage: Float?

    private var meteringLevelsArray: [Float] = [] // Mutating recording array (values are percentage: 0.0 to 1.0)
    private var meteringLevelsClusteredArray: [Float] = [] // Generated read mode array (values are percentage: 0.0 to 1.0)

    private var currentMeteringLevelsArray: [Float] {
        if !meteringLevelsClusteredArray.isEmpty {
            return meteringLevelsClusteredArray
        }
        return meteringLevelsArray
    }

    public var meteringLevels: [Float]? {
        didSet {
            if let meteringLevels = self.meteringLevels {
                meteringLevelsClusteredArray = meteringLevels
                currentGradientPercentage = 0.0
                _ = scaleSoundDataToFitScreen()
            }
        }
    }

    static var audioVisualizationDefaultGradientStartColor: UIColor {
        UIColor(red: 61.0 / 255.0, green: 20.0 / 255.0, blue: 117.0 / 255.0, alpha: 1.0)
    }

    static var audioVisualizationDefaultGradientEndColor: UIColor {
        UIColor(red: 166.0 / 255.0, green: 150.0 / 255.0, blue: 225.0 / 255.0, alpha: 1.0)
    }

    public var gradientStartColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientStartColor {
        didSet {
            setNeedsDisplay()
        }
    }

    public var gradientEndColor: UIColor = AudioVisualizationView.audioVisualizationDefaultGradientEndColor {
        didSet {
            self.setNeedsDisplay()
        }
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)

        if let context = UIGraphicsGetCurrentContext() {
            drawLevelBarsMaskAndGradient(inContext: context)
        }
    }

    public func reset() {
        meteringLevels = nil
        currentGradientPercentage = nil
        meteringLevelsClusteredArray.removeAll()
        meteringLevelsArray.removeAll()
        setNeedsDisplay()
    }

    // MARK: - Record Mode Handling

    public func add(meteringLevel: Float) {
        guard audioVisualizationMode == .write else {
            fatalError("trying to populate audio visualization view in read mode")
        }

        meteringLevelsArray.append(meteringLevel)
        setNeedsDisplay()
    }

    public func scaleSoundDataToFitScreen() -> [Float] {
        if meteringLevelsArray.isEmpty {
            return []
        }

        meteringLevelsClusteredArray.removeAll()
        var lastPosition: Int = 0

        for index in 0..<maximumNumberBars {
            let position: Float = Float(index) / Float(maximumNumberBars) * Float(meteringLevelsArray.count)
            var height: Float = 0.0

            if maximumNumberBars > meteringLevelsArray.count && floor(position) != position {
                let low: Int = Int(floor(position))
                let high: Int = Int(ceil(position))

                if high < meteringLevelsArray.count {
                    height = meteringLevelsArray[low] + ((position - Float(low)) * (meteringLevelsArray[high] - meteringLevelsArray[low]))
                } else {
                    height = meteringLevelsArray[low]
                }
            } else {
                for nestedIndex in lastPosition...Int(position) {
                    height += meteringLevelsArray[nestedIndex]
                }
                let stepsNumber = Int(1 + position - Float(lastPosition))
                height /= Float(stepsNumber)
            }

            lastPosition = Int(position)
            meteringLevelsClusteredArray.append(height)
        }
        setNeedsDisplay()
        return meteringLevelsClusteredArray
    }

    // MARK: - Mask + Gradient

    private func drawLevelBarsMaskAndGradient(inContext context: CGContext) {
        if currentMeteringLevelsArray.isEmpty {
            return
        }

        context.saveGState()

        UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)

        let maskContext = UIGraphicsGetCurrentContext()

        appearance.colorPalette.background.set()

        drawMeteringLevelBars(inContext: maskContext!)

        let mask = UIGraphicsGetCurrentContext()?.makeImage()
        UIGraphicsEndImageContext()

        context.clip(to: bounds, mask: mask!)

        drawGradient(inContext: context)

        context.restoreGState()
    }

    private func drawGradient(inContext context: CGContext) {
        if currentMeteringLevelsArray.isEmpty {
            return
        }

        context.saveGState()

        let startPoint = CGPoint(x: 0.0, y: centerY)
        var endPoint = CGPoint(x: xLeftMostBar() + meteringLevelBarWidth, y: centerY)

        if let gradientPercentage = currentGradientPercentage {
            endPoint = CGPoint(x: frame.size.width * CGFloat(gradientPercentage), y: centerY)
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let colorLocations: [CGFloat] = [0.0, 1.0]
        let colors: [CGColor]

        switch audioVisualizationFillType {
        case .gradient:
            colors = [gradientStartColor.cgColor, gradientEndColor.cgColor]
        case .full:
            colors = [gradientEndColor.cgColor, gradientEndColor.cgColor]
        }

        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: colorLocations)

        context.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: CGGradientDrawingOptions(rawValue: 0))

        context.restoreGState()

        if currentGradientPercentage != nil {
            drawPlainBackground(inContext: context, fillFromXCoordinate: endPoint.x)
        }
    }

    private func drawPlainBackground(inContext context: CGContext, fillFromXCoordinate xCoordinate: CGFloat) {
        context.saveGState()

        let squarePath = UIBezierPath()

        squarePath.move(to: CGPoint(x: xCoordinate, y: 0.0))
        squarePath.addLine(to: CGPoint(x: frame.size.width, y: 0.0))
        squarePath.addLine(to: CGPoint(x: frame.size.width, y: frame.size.height))
        squarePath.addLine(to: CGPoint(x: xCoordinate, y: frame.size.height))

        squarePath.close()
        squarePath.addClip()

        gradientStartColor.set()
        squarePath.fill()

        context.restoreGState()
    }

    // MARK: - Bars

    private func drawMeteringLevelBars(inContext context: CGContext) {
        let offset = max(currentMeteringLevelsArray.count - maximumNumberBars, 0)

        for index in offset..<currentMeteringLevelsArray.count {
            if meteringLevelBarSingleStick {
                drawBar(index - offset, meteringLevelIndex: index, levelBarType: .single, context: context)
            } else {
                drawBar(index - offset, meteringLevelIndex: index, levelBarType: .upper, context: context)
                drawBar(index - offset, meteringLevelIndex: index, levelBarType: .lower, context: context)
            }
        }
    }

    private func drawBar(_ barIndex: Int, meteringLevelIndex: Int, levelBarType: LevelBarType, context: CGContext) {
        context.saveGState()

        var barRect: CGRect

        let xPointForMeteringLevel = self.xPointForMeteringLevel(barIndex)
        let heightForMeteringLevel = self.heightForMeteringLevel(currentMeteringLevelsArray[meteringLevelIndex])

        switch levelBarType {
        case .upper:
            barRect = CGRect(
                x: xPointForMeteringLevel,
                y: centerY - heightForMeteringLevel,
                width: meteringLevelBarWidth,
                height: heightForMeteringLevel
            )
        case .lower:
            barRect = CGRect(
                x: xPointForMeteringLevel,
                y: centerY,
                width: meteringLevelBarWidth,
                height: heightForMeteringLevel
            )
        case .single:
            barRect = CGRect(
                x: xPointForMeteringLevel,
                y: centerY - heightForMeteringLevel,
                width: meteringLevelBarWidth,
                height: heightForMeteringLevel * 2
            )
        }

        let barPath: UIBezierPath = UIBezierPath(roundedRect: barRect, cornerRadius: meteringLevelBarCornerRadius)

        appearance.colorPalette.background.set()
        barPath.fill()

        context.restoreGState()
    }

    // MARK: - Points Helpers

    private var centerY: CGFloat {
        frame.size.height / 2.0
    }

    private var maximumBarHeight: CGFloat {
        bounds.size.height
    }

    private var minimumBarHeight: CGFloat {
        1
    }

    private var maximumNumberBars: Int {
        Int(frame.size.width / (meteringLevelBarWidth + meteringLevelBarInterItem))
    }

    private func xLeftMostBar() -> CGFloat {
        xPointForMeteringLevel(min(maximumNumberBars - 1, currentMeteringLevelsArray.count - 1))
    }

    private func heightForMeteringLevel(_ meteringLevel: Float) -> CGFloat {
        max(minimumBarHeight, CGFloat(meteringLevel) * maximumBarHeight)
    }

    private func xPointForMeteringLevel(_ atIndex: Int) -> CGFloat {
        CGFloat(atIndex) * (meteringLevelBarWidth + meteringLevelBarInterItem)
    }
}
