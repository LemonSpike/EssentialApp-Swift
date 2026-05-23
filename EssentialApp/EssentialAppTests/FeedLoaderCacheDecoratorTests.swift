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
  
  private func makeSUT(
    result: FeedLoader.Result,
    file: StaticString = #file,
    line: UInt = #line
  ) -> FeedLoader {
    let loader = FeedLoaderStub(result: result)
    let sut = FeedLoaderCacheDecorator(decoratee: loader)
    trackForMemoryLeaks(loader, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return sut
  }
}
