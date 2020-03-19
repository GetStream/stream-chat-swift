import XCTest
@testable import StreamChatClient

final class AttachmentTypeTests: XCTestCase {
    struct MetaType: Codable {
        let type: AttachmentType
    }

    func testRawValue() {
        XCTAssertEqual(AttachmentType.unknown.rawValue, nil)
        XCTAssertEqual(AttachmentType.custom("type/custom").rawValue, "type/custom")
        XCTAssertEqual(AttachmentType.image.rawValue, "image")
        XCTAssertEqual(AttachmentType.imgur.rawValue, "imgur")
        XCTAssertEqual(AttachmentType.giphy.rawValue, "giphy")
        XCTAssertEqual(AttachmentType.video.rawValue, "video")
        XCTAssertEqual(AttachmentType.youtube.rawValue, "youtube")
        XCTAssertEqual(AttachmentType.product.rawValue, "product")
        XCTAssertEqual(AttachmentType.file.rawValue, "file")
        XCTAssertEqual(AttachmentType.link.rawValue, "link")
    }

    func testCreatingFromRawValue() {
        XCTAssertEqual(AttachmentType(rawValue: nil), .unknown)
        XCTAssertEqual(AttachmentType(rawValue: ""), .unknown)
        XCTAssertEqual(AttachmentType(rawValue: "type/custom"), .custom("type/custom"))
        XCTAssertEqual(AttachmentType(rawValue: "image"), .image)
        XCTAssertEqual(AttachmentType(rawValue: "imgur"), .imgur)
        XCTAssertEqual(AttachmentType(rawValue: "giphy"), .giphy)
        XCTAssertEqual(AttachmentType(rawValue: "video"), .video)
        XCTAssertEqual(AttachmentType(rawValue: "youtube"), .youtube)
        XCTAssertEqual(AttachmentType(rawValue: "product"), .product)
        XCTAssertEqual(AttachmentType(rawValue: "file"), .file)
        XCTAssertEqual(AttachmentType(rawValue: "link"), .link)
    }

    func testString() {
        var type: AttachmentType = "type/custom"
        XCTAssertEqual(type.rawValue, "type/custom")
        XCTAssertEqual(type, .custom("type/custom"))
        type = "image"
        XCTAssertEqual(type, .image)
    }
    
    func testDecoding() {
        let json = "{\"type\":\"image\"}"
        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        let meta = try! decoder.decode(MetaType.self, from: data)
        XCTAssertEqual(meta.type, .image)
    }

    func testEncoding() {
        let meta = MetaType(type: .giphy)
        let encoder = JSONEncoder()
        let data = try! encoder.encode(meta)
        let json = String(data: data, encoding: .utf8)
        XCTAssertEqual(json, "{\"type\":\"giphy\"}")
    }
}
