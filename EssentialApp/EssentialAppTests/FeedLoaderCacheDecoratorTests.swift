import EssentialApp
import EssentialFeed
import XCTest

class FeedLoaderCacheDecoratorTests: XCTestCase {
  
  func test_load_deliversFeedOnLoaderSuccess() {
    let feed = uniqueFeed()
    let loader = FeedLoaderStub(result: .success(feed))
    let sut = FeedLoaderCacheDecorator(decoratee: loader)
    
    expect(sut, toCompleteWith: .success(feed))
  }
  
  func test_load_deliversErrorOnLoaderFailure() {
    let loader = FeedLoaderStub(result: .failure(anyNSError()))
    let sut = FeedLoaderCacheDecorator(decoratee: loader)
    
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
  
  private func expect(
    _ sut: FeedLoader,
    toCompleteWith expectedResult: FeedLoader.Result,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for load completion")
    sut.load { receivedResult in
      switch (expectedResult, receivedResult) {
      case (.success(let feed), .success(let receivedFeed)):
        XCTAssertEqual(feed, receivedFeed, file: file, line: line)
        
      case (.failure, .failure):
        break
        
      default:
        XCTFail("Expected load feed result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
      }
      
      exp.fulfill()
    }
    wait(for: [exp], timeout: 0.1)
  }
}
