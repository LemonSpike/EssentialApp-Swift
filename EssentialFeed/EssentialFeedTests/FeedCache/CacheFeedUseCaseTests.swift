import EssentialFeed
import Foundation
import XCTest

final class CacheFeedUseCaseTests: XCTestCase {
  func testInitDoesNotMessageStoreUponCreation() async throws {
    let (_, store) = makeSUT()
    XCTAssertEqual(store.receivedMessages, [])
  }
  
  func testSaveRequestsCacheDeletion() async throws {
    let (sut, store) = makeSUT()
    let feed = uniqueImageFeed().models
    
    // when
    sut.save(feed) { _ in }
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func testSaveDoesNotRequestCacheInsertionOnDeletionError() async throws {
    let (sut, store) = makeSUT()
    let feed = uniqueImageFeed().models
    let deletionError = anyNSError()
    
    sut.save(feed) { _ in }
    store.completeDeletion(with: deletionError)
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed])
  }
  
  func testSaveRequestsNewCacheInsertionWithTimestampOnSuccessfulDeletion() async throws {
    let timestamp = Date()
    let (sut, store) = makeSUT(currentDate: { timestamp })
    let feed = uniqueImageFeed()
    
    sut.save(feed.models) { _ in }
    store.completeDeletionSuccessfully()
    
    XCTAssertEqual(store.receivedMessages, [.deleteCachedFeed, .insert(feed.local, timestamp)])
  }
  
  func testSaveFailsOnDeletionError() throws {
    let (sut, store) = makeSUT()
    let deletionError = anyNSError()
    
    expect(sut, toCompleteWithError: deletionError, when: {
      store.completeDeletion(with: deletionError)
    })
  }
  
  func testSaveFailsOnInsertionError() throws {
    let (sut, store) = makeSUT()
    let insertionError = anyNSError()
    
    expect(sut, toCompleteWithError: insertionError, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertion(with: insertionError)
    })
  }
  
  func testSaveSucceedsOnSuccessfulCacheInsertion() throws {
    let (sut, store) = makeSUT()
    
    expect(sut, toCompleteWithError: nil, when: {
      store.completeDeletionSuccessfully()
      store.completeInsertionSuccessfully()
    })
  }
  
  func testSaveDoesNotDeliverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults: [LocalFeedLoader.SaveResult] = []
    sut?.save(uniqueImageFeed().models, completion: { error in
      receivedResults.append(error)
    })
    
    sut = nil
    store.completeDeletion(with: anyNSError())
    XCTAssertTrue(receivedResults.isEmpty)
  }
  
  func testSaveDoesNotDeliverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
    let store = FeedStoreSpy()
    var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
    
    var receivedResults: [LocalFeedLoader.SaveResult] = []
    sut?.save(uniqueImageFeed().models, completion: { error in
      receivedResults.append(error)
    })
    
    store.completeDeletionSuccessfully()
    sut = nil
    store.completeInsertion(with: anyNSError())
    
    XCTAssertTrue(receivedResults.isEmpty)
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
    toCompleteWithError expectedError: NSError?,
    when action: () -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for save completion")
    
    var receivedError: Error?
    sut.save(uniqueImageFeed().models) { receivedSaveResult in
      if case let Result.failure(error) = receivedSaveResult {
        receivedError = error
      }
      exp.fulfill()
    }
    
    action()
    wait(for: [exp], timeout: 1.0)
    
    XCTAssertEqual(
      receivedError as NSError?,
      expectedError,
      file: file,
      line: line
    )
  }
}
