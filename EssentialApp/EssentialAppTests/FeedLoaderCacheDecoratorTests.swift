import EssentialApp
import EssentialFeed
import XCTest

class FeedLoaderCacheDecoratorTests: XCTestCase, FeedLoaderTestCase {
  
  func test_load_deliversFeedOnLoaderSuccess() {
    let feed = uniqueFeed()
    let sut = makeSUT(result: .success(feed))
    
    expect(sut, toCompleteWith: .success(feed))
  }
  
  func test_load_deliversErrorOnLoaderFailure() {
    let sut = makeSUT(result:  .failure(anyNSError()))
    
    expect(sut, toCompleteWith: .failure(anyNSError()))
  }
  
  func test_load_cachesLoadedFeedOnLoaderSuccess() {
    let cache = CacheSpy()
    let feed = uniqueFeed()
    let sut = makeSUT(result: .success(feed), cache: cache)
    
    sut.load { _ in }
    
    XCTAssertEqual(
      cache.messages,
      [.save(feed)],
      "Expected to cache loaded feed on success"
    )
  }
  
  func test_load_doesNotCacheOnLoaderFailure() {
    let cache = CacheSpy()
    let sut = makeSUT(result: .failure(anyNSError()), cache: cache)
    
    sut.load { _ in }
    
    XCTAssert(
      cache.messages.isEmpty,
      "Expected to not cache feed on load error"
    )
  }
  
  private func makeSUT(
    result: FeedLoader.Result,
    cache: CacheSpy = CacheSpy(),
    file: StaticString = #file,
    line: UInt = #line
  ) -> FeedLoader {
    let loader = FeedLoaderStub(result: result)
    let sut = FeedLoaderCacheDecorator(decoratee: loader, cache: cache)
    trackForMemoryLeaks(loader, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
  
  private class CacheSpy: FeedCache {
    private(set) var messages: [Message] = []
    
    enum Message: Equatable {
      case save([FeedImage])
    }
    
    func save(
      _ feed: [EssentialFeed.FeedImage],
      completion: @escaping (FeedCache.Result) -> ()
    ) {
      messages.append(.save(feed))
      completion(.success(()))
    }
  }
}
