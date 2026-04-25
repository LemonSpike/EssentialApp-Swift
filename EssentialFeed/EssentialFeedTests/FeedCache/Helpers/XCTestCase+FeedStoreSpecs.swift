import EssentialFeed
import Foundation
import XCTest

extension FeedStoreSpecs where Self: XCTestCase {
  func assertThatRetrieveDeliversEmptyOnEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    expect(sut, toRetrieve: .success(nil), file: file, line: line)
  }

  func assertThatRetrieveHasNoSideEffectsOnEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    expect(sut, toRetrieveTwice: .success(nil), file: file, line: line)
  }

  func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let feed = uniqueImageFeed().local
    let timestamp = Date()

    insert((feed: feed, timestamp: timestamp), to: sut)

    expect(
      sut,
      toRetrieve: .success(CachedFeed(feed: feed, timestamp: timestamp))
    )
  }

  func assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let feed = uniqueImageFeed().local
    let timestamp = Date()

    insert((feed: feed, timestamp: timestamp), to: sut)

    expect(
      sut,
      toRetrieveTwice: .success(CachedFeed(feed: feed, timestamp: timestamp))
    )
  }

  func assertThatInsertDeliversNoErrorOnEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

    XCTAssertNil(insertionError, "Expected to insert cache successfully")
  }

  func assertThatInsertDeliversNoErrorOnNonEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    insert((uniqueImageFeed().local, Date()), to: sut)

    let insertionError = insert((uniqueImageFeed().local, Date()), to: sut)

    XCTAssertNil(insertionError, "Expected to insert cache successfully")
  }

  func assertThatInsertOverridesPreviouslyInsertedCacheValues(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let firstFeed = uniqueImageFeed().local
    let firstTimestamp = Date()
    insert((feed: firstFeed, timestamp: firstTimestamp), to: sut)

    let latestFeed = uniqueImageFeed().local
    let latestTimestamp = Date()
    insert((feed: latestFeed, timestamp: latestTimestamp), to: sut)

    expect(
      sut,
      toRetrieve:
          .success(CachedFeed(feed: latestFeed, timestamp: latestTimestamp))
    )
  }

  func assertThatDeleteDeliversNoErrorOnEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let deletionError = deleteCache(from: sut)

    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
  }

  func assertThatDeleteHasNoSideEffectsOnEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    deleteCache(from: sut)

    expect(sut, toRetrieve: .success(nil))
  }

  func assertThatDeleteDeliversNoErrorOnNonEmptyCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    insert((uniqueImageFeed().local, Date()), to: sut)

    let deletionError = deleteCache(from: sut)

    XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
  }

  func assertThatDeleteEmptiesPreviouslyInsertedCache(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    insert((uniqueImageFeed().local, Date()), to: sut)

    deleteCache(from: sut)

    expect(sut, toRetrieve: .success(nil))
  }

  func assertThatSideEffectsRunSerially(
    on sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    var completedOperationsInOrder: [XCTestExpectation] = []

    let op1 = expectation(description: "Operation 1")
    sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op1)
      op1.fulfill()
    }

    let op2 = expectation(description: "Operation 2")
    sut.deleteCachedFeed { error in
      completedOperationsInOrder.append(op2)
      op2.fulfill()
    }

    let op3 = expectation(description: "Operation 3")
    sut.insert(uniqueImageFeed().local, timestamp: Date()) { _ in
      completedOperationsInOrder.append(op3)
      op3.fulfill()
    }

    waitForExpectations(timeout: 0.1)
    XCTAssertEqual(
      completedOperationsInOrder,
      [op1, op2, op3],
      "Expected store side effects to run serially but operations finished in wrong order"
    )
  }

  @discardableResult
  func insert(
    _ cache: (feed: [LocalFeedImage], timestamp: Date),
    to sut: FeedStore,
    file: StaticString = #file,
    line: UInt = #line
  ) -> Error? {
    let expectation = self.expectation(description: "Wait for cache insertion")
    var insertionError: Error?
    sut.insert(cache.feed, timestamp: cache.timestamp) { receivedInsertionResult in
      if case let Result.failure(error) = receivedInsertionResult {
        insertionError = error
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.1)
    return insertionError
  }

  @discardableResult
  func deleteCache(from sut: FeedStore) -> Error? {
    let exp = expectation(description: "Wait for cache deletion")
    var deletionError: Error?
    sut.deleteCachedFeed { receivedDeletionResult in
      if case let Result.failure(error) = receivedDeletionResult {
        deletionError = error
      }
      exp.fulfill()
    }
    wait(for: [exp], timeout: 1.0)
    return deletionError
  }

  func expect(
    _ sut: FeedStore,
    toRetrieve expectedResult: FeedStore.RetrievalResult,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let expectation = self.expectation(description: "Wait for cache retrieval")

    sut.retrieve { retrievedResult in
      switch (retrievedResult, expectedResult) {
      case (.success(nil), .success(nil)),
          (.failure, .failure):
          break
      case let (
          .success(.some(retrievedCache)),
          .success(.some(expectedCache))
        ):
          XCTAssertEqual(retrievedCache.feed, expectedCache.feed, file: file, line: line)
          XCTAssertEqual(retrievedCache.timestamp, expectedCache.timestamp, file: file, line: line)
      default:
          XCTFail("Expected to retrieve \(expectedResult), got \(retrievedResult) instead", file: file, line: line)
      }
      expectation.fulfill()
    }
    wait(for: [expectation], timeout: 0.1)
  }

  func expect(
    _ sut: FeedStore,
    toRetrieveTwice expectedResult: FeedStore.RetrievalResult,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
    expect(sut, toRetrieve: expectedResult, file: file, line: line)
  }
}
