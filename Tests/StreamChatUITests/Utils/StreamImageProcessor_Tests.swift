//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamChatUI
import UIKit
import XCTest

final class StreamImageProcessor_Tests: XCTestCase {
    private let sut = StreamImageProcessor()

    func test_crop_usesAspectFillAndCenterCrop() throws {
        let source = stripedImage()

        let cropped = try XCTUnwrap(sut.crop(image: source, to: CGSize(width: 2, height: 2)))

        XCTAssertEqual(cropped.size, CGSize(width: 2, height: 2))
        let color = try XCTUnwrap(averageColor(of: cropped))
        XCTAssertLessThan(color.red, 0.15)
        XCTAssertGreaterThan(color.green, 0.85)
        XCTAssertLessThan(color.blue, 0.15)
    }

    func test_crop_withInvalidTargetSize_returnsNil() {
        let image = stripedImage()

        XCTAssertNil(sut.crop(image: image, to: .zero))
        XCTAssertNil(sut.crop(image: image, to: CGSize(width: -1, height: 1)))
    }

    private func stripedImage() -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 6, height: 2), format: format).image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 2, height: 2))
            UIColor.green.setFill()
            context.fill(CGRect(x: 2, y: 0, width: 2, height: 2))
            UIColor.blue.setFill()
            context.fill(CGRect(x: 4, y: 0, width: 2, height: 2))
        }
    }

    private func averageColor(of image: UIImage) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        guard let ciImage = CIImage(image: image) else { return nil }
        let filter = CIFilter(name: "CIAreaAverage")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(CIVector(cgRect: ciImage.extent), forKey: kCIInputExtentKey)
        guard let output = filter?.outputImage else { return nil }

        var pixel = [UInt8](repeating: 0, count: 4)
        CIContext().render(
            output,
            toBitmap: &pixel,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )
        return (
            CGFloat(pixel[0]) / 255,
            CGFloat(pixel[1]) / 255,
            CGFloat(pixel[2]) / 255
        )
    }
}
