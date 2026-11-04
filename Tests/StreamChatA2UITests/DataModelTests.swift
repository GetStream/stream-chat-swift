//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamChatA2UI
import Testing

@MainActor
@Suite("Data paths")
struct DataPathTests {
    @Test("Absolute and relative paths are distinguished")
    func absoluteAndRelative() {
        #expect(DataPath("/a/b").isAbsolute)
        #expect(!DataPath("a/b").isAbsolute)
        #expect(DataPath("/").isRoot)
        #expect(DataPath("/a/b").segments == ["a", "b"])
    }

    @Test("JSON Pointer escapes are decoded and re-encoded")
    func escaping() {
        let path = DataPath("/a~1b/c~0d")
        #expect(path.segments == ["a/b", "c~d"])
        #expect(path.description == "/a~1b/c~0d")
    }

    @Test("Appending a relative path extends it, an absolute path replaces it")
    func appending() {
        let base = DataPath("/items/0")
        #expect(base.appending(DataPath("name")).description == "/items/0/name")
        #expect(base.appending(DataPath("/other")).description == "/other")
        #expect(base.appending(segment: "1").description == "/items/0/1")
    }

    @Test("Descendant checks compare segment prefixes")
    func descendants() {
        #expect(DataPath("/a/b/c").isDescendant(of: DataPath("/a/b")))
        #expect(DataPath("/a").isDescendant(of: DataPath("/")))
        #expect(!DataPath("/a/b").isDescendant(of: DataPath("/a/b/c")))
    }

    @Test("Basename and dirname address the last segment")
    func components() {
        #expect(DataPath("/a/b").basename == "b")
        #expect(DataPath("/a/b").dirname.description == "/a")
        #expect(DataPath("/").basename.isEmpty)
    }
}

@MainActor
@Suite("Data model")
struct DataModelTests {
    @Test("Values are read and written by path")
    func readWrite() {
        let model = DataModel(["user": ["name": "Ada"] as JsonMap])
        #expect(Json.string(model.value(at: DataPath("/user/name"))) == "Ada")

        model.update(at: DataPath("/user/name"), value: "Grace")
        #expect(Json.string(model.value(at: DataPath("/user/name"))) == "Grace")
    }

    @Test("Missing intermediate containers are created")
    func upsert() {
        let model = DataModel()
        model.update(at: DataPath("/order/items/0/name"), value: "Tea")

        #expect(Json.string(model.value(at: DataPath("/order/items/0/name"))) == "Tea")
        #expect(Json.array(model.value(at: DataPath("/order/items")))?.count == 1)
    }

    @Test("Writing null removes the entry")
    func deletion() {
        let model = DataModel(["a": 1, "b": 2])
        model.update(at: DataPath("/a"), value: nil)

        #expect(model.value(at: DataPath("/a")) == nil)
        #expect(Json.int(model.value(at: DataPath("/b"))) == 2)
        #expect(model.snapshot.keys.sorted() == ["b"])
    }

    @Test("Writing to the root replaces the whole model")
    func rootReplacement() {
        let model = DataModel(["a": 1])
        model.update(at: .root, value: ["b": 2] as JsonMap)

        #expect(model.value(at: DataPath("/a")) == nil)
        #expect(Json.int(model.value(at: DataPath("/b"))) == 2)
    }

    @Test("Array elements are addressed by index and appended at the end")
    func arrays() {
        let model = DataModel(["items": ["a", "b"]])
        model.update(at: DataPath("/items/1"), value: "c")
        model.update(at: DataPath("/items/2"), value: "d")

        #expect(Json.stringArray(model.value(at: DataPath("/items"))) == ["a", "c", "d"])
    }

    @Test("Observers are notified of every write")
    func observers() {
        let model = DataModel()
        var changes: [String] = []
        let stop = model.observe { changes.append($0.path.description) }

        model.update(at: DataPath("/a"), value: 1)
        model.update(at: DataPath("/b/c"), value: 2)
        stop()
        model.update(at: DataPath("/d"), value: 3)

        #expect(changes == ["/a", "/b/c"])
    }

    @Test("A write cannot descend through a scalar")
    func writeThroughScalar() {
        let model = DataModel(["a": 1])
        #expect(throws: DataModelError.notAContainer(DataPath("/a/b"))) {
            try model.set(2, at: DataPath("/a/b"))
        }
        model.update(at: DataPath("/a/b"), value: 2)

        #expect(Json.int(model.value(at: DataPath("/a"))) == 1)
    }
}

@MainActor
@Suite("Data contexts")
struct DataContextTests {
    @Test("Relative paths resolve against the scope, absolute paths do not")
    func resolution() {
        let model = DataModel(["items": [["name": "Tea"]], "title": "Menu"])
        let root = DataContext(model, "/")
        let scope = root.collectionScope(path: DataPath("/items"), index: 0)

        #expect(Json.string(scope.value(at: DataPath("name"))) == "Tea")
        #expect(Json.string(scope.value(at: DataPath("/title"))) == "Menu")
        #expect(scope.resolve(DataPath("name")).description == "/items/0/name")
    }

    @Test("Collection scopes expose the item index")
    func itemIndex() {
        let model = DataModel(["items": [1, 2, 3]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 2)

        #expect(scope.itemIndex == 2)
        #expect(scope.isCollectionScope)
        #expect(!DataContext(model, "/").isCollectionScope)
    }

    @Test("Writes go through the scope")
    func writes() {
        let model = DataModel(["items": [["quantity": 1]]])
        let scope = DataContext(model, "/").collectionScope(path: DataPath("/items"), index: 0)
        scope.update(DataPath("quantity"), 5)

        #expect(Json.int(model.value(at: DataPath("/items/0/quantity"))) == 5)
    }
}
