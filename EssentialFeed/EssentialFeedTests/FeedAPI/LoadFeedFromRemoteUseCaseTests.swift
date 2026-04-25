import Foundation
import Testing
import EssentialFeed

@Suite
struct LoadFeedFromRemoteUseCaseTests {
  @Test func testInitDoesNotRequestDataFromURL() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      #expect(client.requestedURLs.isEmpty)
    }
  }

  @Test func testLoadRequestsDataFromURL() async throws {
    try await LeakChecker { checker in
      let url = URL(string: "https://a-given-url.com")!
      let (sut, client) = makeSUT(url: url)
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      sut.load() { _ in }

      #expect(client.requestedURLs == [url])
    }
  }

  @Test func testLoadTwiceRequestsDataFromURLTwice() async throws {
    try await LeakChecker { checker in
      let url = URL(string: "https://a-given-url.com")!
      let (sut, client) = makeSUT(url: url)
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      sut.load() { _ in }
      sut.load() { _ in }

      #expect(client.requestedURLs == [url, url])
    }
  }

  @Test func testLoadDeliversErrorOnClientError() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      await expect(sut, toCompleteWithResult: failure(.connectivity)) {
        let clientError = NSError(domain: "Test", code: 0)
        client.complete(with: clientError)
      }
    }
  }

  @Test func testLoadDeliversErrorOnHTTPErrorStatusCode() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      let samples = [199, 201, 300, 400, 500].enumerated()

      for (index, code) in samples {
        await expect(sut, toCompleteWithResult: failure(.invalidData)) {
          let json = makeItemsJson([])
          client.complete(withStatusCode: code, data: json, at: index)
        }
      }
    }
  }

  @Test func testLoadDeliversErrorOnSuccessHTTPResponseWithInvalidJSON() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      await expect(sut, toCompleteWithResult: failure(.invalidData)) {
        let invalidJSON = Data("invalid json".utf8)
        client.complete(withStatusCode: 200, data: invalidJSON)
      }
    }
  }

  @Test func testLoadDeliversNoItemsOnSuccessHTTPResponseWithEmptyJSONList() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      await expect(sut, toCompleteWithResult: .success([])) {
        let emptyListJSON = makeItemsJson([])
        client.complete(withStatusCode: 200, data: emptyListJSON)
      }
    }
  }

  @Test func testLoadDeliversItemsOnSuccessHTTPResponseWithValidJSONItems() async throws {
    try await LeakChecker { checker in
      let (sut, client) = makeSUT()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(sut)

      let itemOne = makeItem(
        id: UUID(),
        imageUrl: URL(string: "http://a-url.com")!
      )

      let itemTwo = makeItem(
        id: UUID(),
        description: "a description",
        location: "a location",
        imageUrl: URL(string: "http://another-url.com")!
      )

      let itemsJSON = [itemOne.json, itemTwo.json]
      let items = [itemOne.model, itemTwo.model]

      await expect(sut, toCompleteWithResult: .success(items)) {
        let listData = makeItemsJson(itemsJSON)
        client.complete(withStatusCode: 200, data: listData)
      }
    }
  }

  @Test func testLoadDoesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() async throws {
    try await LeakChecker { checker in
      let url = URL(string: "https://a-url.com")!
      let client = HTTPClientSpy()
      var sut: RemoteFeedLoader? = RemoteFeedLoader(url: url, client: client)
      checker.checkForMemoryLeak(client)

      var capturedResults: [RemoteFeedLoader.Result] = []
      sut?.load() { capturedResults.append($0) }

      sut = nil
      client.complete(withStatusCode: 200, data: makeItemsJson([]))

      #expect(capturedResults.isEmpty)
    }
  }

  // MARK: - Helpers
  private func makeSUT(url: URL = URL(string: "https://a-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
    let client = HTTPClientSpy()
    return (RemoteFeedLoader(url: url, client: client), client)
  }

  private func makeItem(
    id: UUID,
    description: String? = nil,
    location: String? = nil,
    imageUrl: URL
  ) -> (model: FeedImage, json:[String: Any]) {
    let item = FeedImage(
      id: id,
      description: description,
      location: location,
      url: imageUrl
    )
    let json = [
      "id": id.uuidString,
      "description": description,
      "location": location,
      "image": imageUrl.absoluteString
    ].compactMapValues { $0 }
    return (item, json)
  }

  private func makeItemsJson(_ items: [[String: Any]]) -> Data {
    let json = ["items": items]
    return try! JSONSerialization.data(withJSONObject: json)
  }

  private func failure(_ error: RemoteFeedLoader.Error) -> RemoteFeedLoader.Result {
    .failure(error)
  }

  private func expect(
    _ sut: RemoteFeedLoader,
    toCompleteWithResult result: RemoteFeedLoader.Result,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column,
    when action: @escaping () -> Void
  ) async {
    _ = await confirmation("Wait for load completion") { fulfill in
      sut.load() { receivedResult in
        let sourceLocation = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
        switch (receivedResult, result) {
        case let (.success(receivedItems), .success(expectedItems)):
          #expect(receivedItems == expectedItems, sourceLocation: sourceLocation)
        case let (.failure(receivedError as RemoteFeedLoader.Error), .failure(expectedError as RemoteFeedLoader.Error)):
          #expect(receivedError == expectedError, sourceLocation: sourceLocation)
        default:
          #expect(Bool(false), "Expected a different result.", sourceLocation: sourceLocation)
        }
        fulfill()
      }
      action()
    }
  }
}
