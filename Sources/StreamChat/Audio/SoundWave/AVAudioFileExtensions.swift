//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import AVFoundation

extension AVAudioFile {
    func buffer() throws -> [[Float]] {
        let frameCount = UInt32(length)

        guard
            let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: fileFormat.sampleRate, channels: fileFormat.channelCount, interleaved: false),
            let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: UInt32(length))
        else {
            return []
        }

        do {
            try read(into: buffer, frameCount: frameCount)
            return analyze(buffer: buffer)
        } catch {
            log.error(error)
            return []
        }
    }

    private func analyze(buffer: AVAudioPCMBuffer) -> [[Float]] {
        let channelCount = Int(buffer.format.channelCount)
        let frameLength = Int(buffer.frameLength)
        var result = Array(
            repeating: [Float](
                repeatElement(0, count: frameLength)
            ),
            count: channelCount
        )

        for channel in 0..<channelCount {
            for sampleIndex in 0..<frameLength {
                guard let floatChannelData = buffer.floatChannelData else {
                    continue
                }

                let squareRoot = sqrt(
                    floatChannelData[channel][sampleIndex * buffer.stride] / Float(buffer.frameLength)
                )
                let dbPower = 20 * log10(squareRoot)
                result[channel][sampleIndex] = dbPower
            }
        }
        return result
    }
}
