import EssentialFeed
import XCTest

final class LoadFeedFromCacheUseCaseTests: XCTestCase {

  func testInitDoesNotMessageStoreUponCreation() throws {
    let (_, store) = makeSUT()
    XCTAssertEqual(store.receivedMessages, [])
  }

  func testLoadRequestsCacheRetrieval() {
    let (sut, store) = makeSUT()

    sut.load { _ in }
    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadFailsOnRetrievalError() {
    let (sut, store) = makeSUT()
    let retrievalError = anyNSError()

    expect(sut, toCompleteWith: .failure(retrievalError), when: {
      store.completeRetrieval(with: retrievalError)
    })
  }

  func testLoadDeliversNoImagesOnEmptyCache() {
    let (sut, store) = makeSUT()

    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrievalWithEmptyCache()
    })
  }

  func testLoadDeliversCachedImagesOnNonExpiredCache() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })


    expect(sut, toCompleteWith: .success(feed.models), when: {
      store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)
    })
  }

  func testLoadDeliversNoImagesOnCacheExpiration() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })


    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)
    })
  }

  func testLoadDeliversNoImagesOnExpiredCache() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })


    expect(sut, toCompleteWith: .success([]), when: {
      store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)
    })
  }

  func testLoadHasNoSideEffectsOnRetrievalError() {
    let (sut, store) = makeSUT()

    sut.load { _ in }
    store.completeRetrieval(with: anyNSError())

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadHasNoSideEffectsOnEmptyCache() {
    let (sut, store) = makeSUT()

    sut.load { _ in }
    store.completeRetrievalWithEmptyCache()

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadHasNoSideEffectsOnNonExpiredCache() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let nonExpiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: 1)
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: nonExpiredTimestamp)

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadHasNoSideEffectsOnCacheExpiration() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let expirationTimestamp = fixedCurrentDate.minusFeedCacheMaxAge()
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: expirationTimestamp)

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadHasNoSideEffectsOnExpiredCache() {
    let feed = uniqueImageFeed()
    let fixedCurrentDate = Date()
    let expiredTimestamp = fixedCurrentDate.minusFeedCacheMaxAge().adding(seconds: -1)
    let (sut, store) = makeSUT(currentDate: { fixedCurrentDate })

    sut.load { _ in }
    store.completeRetrieval(with: feed.local, timestamp: expiredTimestamp)

    XCTAssertEqual(store.receivedMessages, [.retrieve])
  }

  func testLoadDoesNotDeliverResultAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)

    var receivedResults: [LocalFeedLoader.LoadResult] = []
    sut?.load { result in
      receivedResults.append(result)
    }

    sut = nil
    store.completeRetrievalWithEmptyCache()

    XCTAssert(receivedResults.isEmpty)
  }

  // MARK: - Helpers
  private func makeSUT(
    currentDate: @escaping () -> Date = Date.init,
    file: StaticString = #file,
    line: UInt = #line
  ) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
    let store = FeedStoreSpy()
    let sut = LocalFeedLoader(store: store, currentDate: currentDate)
    trackForMemoryLeaks(store, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)

    return (sut, store)
  }

  private func expect(
    _ sut: LocalFeedLoader,
    toCompleteWith expectedResult: FeedLoader.Result,
    when action: () -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let expectation = expectation(description: "Wait for load completion")

    sut.load() { receivedResult in
      switch (receivedResult, expectedResult) {
        case let (.success(receivedImages), .success(expectedImages)):
          XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
        case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
          XCTAssertEqual(receivedError, expectedError, file: file, line: line)
        default:
          XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
      }
      expectation.fulfill()
    }

    action()
    wait(for: [expectation], timeout: 0.1)
  }
}
