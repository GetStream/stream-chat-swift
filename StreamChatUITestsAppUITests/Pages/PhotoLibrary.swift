//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Photos
import XCTest

enum PhotoLibrary {
    /// Generates a one-second video in the runner and saves it to the simulator's photo library,
    /// which has only stock photos, so the photo picker can offer a video.
    static func seedVideo(file: StaticString = #filePath, line: UInt = #line) {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("e2e_video.mp4")
        do {
            try writeVideo(to: url)
        } catch {
            XCTFail("Could not write the video: \(error)", file: file, line: line)
            return
        }
        requestAddAuthorization()

        let saved = XCTestExpectation(description: "The video is saved to the photo library")
        nonisolated(unsafe) var saveError: Error?
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
        }) { _, error in
            saveError = error
            saved.fulfill()
        }
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 20), .completed, file: file, line: line)
        XCTAssertNil(saveError, "Could not save the video: \(String(describing: saveError))", file: file, line: line)
    }

    private static func requestAddAuthorization() {
        guard PHPhotoLibrary.authorizationStatus(for: .addOnly) != .authorized else { return }
        let authorized = XCTestExpectation(description: "Photo library access is granted")
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in authorized.fulfill() }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let allowButton = springboard.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Allow'")).firstMatch
        if allowButton.waitForExistence(timeout: 5) {
            allowButton.tap()
        }
        _ = XCTWaiter.wait(for: [authorized], timeout: 10)
    }

    private static func writeVideo(to url: URL) throws {
        try? FileManager.default.removeItem(at: url)
        let size = 64
        let writer = try AVAssetWriter(outputURL: url, fileType: .mp4)
        let input = AVAssetWriterInput(
            mediaType: .video,
            outputSettings: [AVVideoCodecKey: AVVideoCodecType.h264, AVVideoWidthKey: size, AVVideoHeightKey: size]
        )
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: input,
            sourcePixelBufferAttributes: [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB,
                kCVPixelBufferWidthKey as String: size,
                kCVPixelBufferHeightKey as String: size
            ]
        )
        writer.add(input)
        writer.startWriting()
        writer.startSession(atSourceTime: .zero)
        let frameRate: Int32 = 30
        for frame in 0..<Int(frameRate) {
            while !input.isReadyForMoreMediaData {
                Thread.sleep(forTimeInterval: 0.01)
            }
            var pixelBuffer: CVPixelBuffer?
            guard let pool = adaptor.pixelBufferPool,
                  CVPixelBufferPoolCreatePixelBuffer(nil, pool, &pixelBuffer) == kCVReturnSuccess,
                  let pixelBuffer else {
                throw writer.error ?? CocoaError(.fileWriteUnknown)
            }
            adaptor.append(pixelBuffer, withPresentationTime: CMTime(value: CMTimeValue(frame), timescale: frameRate))
        }
        input.markAsFinished()
        let finished = XCTestExpectation(description: "The video is written")
        writer.finishWriting { finished.fulfill() }
        _ = XCTWaiter.wait(for: [finished], timeout: 10)
        if writer.status != .completed {
            throw writer.error ?? CocoaError(.fileWriteUnknown)
        }
    }
}
