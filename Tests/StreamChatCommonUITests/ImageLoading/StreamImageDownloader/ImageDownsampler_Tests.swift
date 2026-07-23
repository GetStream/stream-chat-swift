//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import ImageIO
@testable import StreamChatCommonUI
import UIKit
import XCTest

final class ImageDownsampler_Tests: XCTestCase {
    // MARK: - isGIF

    func test_isGIF_detectsGIF() {
        XCTAssertTrue(gifData().isGIF)
    }

    func test_isGIF_returnsFalseForNonGIF() {
        XCTAssertFalse(pngData(width: 8, height: 8).isGIF)
        XCTAssertFalse(Data([0x00, 0x01]).isGIF)
    }

    // MARK: - decode

    func test_decode_withoutResize_returnsFullSize() throws {
        let image = try XCTUnwrap(ImageDownsampler.decode(pngData(width: 100, height: 60), resize: nil, scale: 1))
        XCTAssertEqual(image.cgImage?.width, 100)
        XCTAssertEqual(image.cgImage?.height, 60)
    }

    func test_decode_withResize_downscalesToFillTarget() throws {
        // Square source, square target → exact fit.
        let image = try XCTUnwrap(ImageDownsampler.decode(pngData(width: 200, height: 200), resize: CGSize(width: 50, height: 50), scale: 1))
        XCTAssertEqual(image.cgImage?.width, 50)
        XCTAssertEqual(image.cgImage?.height, 50)
    }

    func test_decode_aspectFill_landscapeSourceCoversTarget() throws {
        // 200x100 into a 50x50 box: aspect-fill scale = 0.5 → 100x50 (covers the box).
        let image = try XCTUnwrap(ImageDownsampler.decode(pngData(width: 200, height: 100), resize: CGSize(width: 50, height: 50), scale: 1))
        XCTAssertEqual(image.cgImage?.width, 100)
        XCTAssertEqual(image.cgImage?.height, 50)
    }

    func test_decode_doesNotUpscaleSmallImages() throws {
        let image = try XCTUnwrap(ImageDownsampler.decode(pngData(width: 30, height: 30), resize: CGSize(width: 100, height: 100), scale: 1))
        XCTAssertEqual(image.cgImage?.width, 30)
        XCTAssertEqual(image.cgImage?.height, 30)
    }

    func test_decode_appliesDisplayScaleToResizedOutput() throws {
        // Target 50pt at scale 2 → 100px; source is large enough to downscale to it.
        let image = try XCTUnwrap(ImageDownsampler.decode(pngData(width: 400, height: 400), resize: CGSize(width: 50, height: 50), scale: 2))
        XCTAssertEqual(image.cgImage?.width, 100)
        XCTAssertEqual(image.scale, 2)
        XCTAssertEqual(image.size.width, 50, accuracy: 0.5)
    }

    // MARK: - Orientation

    func test_decode_normalisesEXIFOrientation() throws {
        let cases: [(orientation: CGImagePropertyOrientation, swaps: Bool)] = [
            (.up, false), (.upMirrored, false), (.down, false), (.downMirrored, false),
            (.left, true), (.leftMirrored, true), (.right, true), (.rightMirrored, true)
        ]
        for testCase in cases {
            let data = orientedJPEGData(width: 120, height: 60, orientation: testCase.orientation)
            let image = try XCTUnwrap(ImageDownsampler.decode(data, resize: nil, scale: 1))
            let expected = testCase.swaps ? CGSize(width: 60, height: 120) : CGSize(width: 120, height: 60)
            XCTAssertEqual(image.size, expected, "orientation \(testCase.orientation.rawValue)")
            XCTAssertEqual(image.imageOrientation, .up, "orientation \(testCase.orientation.rawValue)")
        }
    }

    func test_decode_resize_usesOrientedDimensionsForAspectFill() throws {
        // 120x60 buffer tagged .right → displays as 60x120 (portrait); resized output stays portrait.
        let data = orientedJPEGData(width: 120, height: 60, orientation: .right)
        let image = try XCTUnwrap(ImageDownsampler.decode(data, resize: CGSize(width: 30, height: 30), scale: 1))
        XCTAssertGreaterThan(image.size.height, image.size.width)
        XCTAssertEqual(image.imageOrientation, .up)
    }

    // MARK: - Helpers

    private func renderedImage(width: Int, height: Int) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let size = CGSize(width: width, height: height)
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            UIColor.systemTeal.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func pngData(width: Int, height: Int) -> Data {
        renderedImage(width: width, height: height).pngData()!
    }

    private func gifData() -> Data {
        let cgImage = renderedImage(width: 4, height: 4).cgImage!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, "com.compuserve.gif" as CFString, 1, nil)!
        CGImageDestinationAddImage(destination, cgImage, nil)
        CGImageDestinationFinalize(destination)
        return output as Data
    }

    private func orientedJPEGData(width: Int, height: Int, orientation: CGImagePropertyOrientation) -> Data {
        let cgImage = renderedImage(width: width, height: height).cgImage!
        let output = NSMutableData()
        let destination = CGImageDestinationCreateWithData(output, "public.jpeg" as CFString, 1, nil)!
        let properties = [kCGImagePropertyOrientation: orientation.rawValue] as CFDictionary
        CGImageDestinationAddImage(destination, cgImage, properties)
        CGImageDestinationFinalize(destination)
        return output as Data
    }
}
