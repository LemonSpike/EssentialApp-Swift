import EssentialApp
import EssentialFeed
import XCTest

class FeedImageLoaderCacheDecoratorTests: XCTestCase {
  
  func test_loadImageData_deliversImageOnLoaderSuccess() {
    let data = anyData()
    let (sut, _) = makeSUT(result: .success(data))
    
    expect(sut, toCompleteWith: .success(data))
  }
  
  func test_loadImageData_deliversErrorOnLoaderFailure() {
    let (sut, _) = makeSUT(result:  .failure(anyNSError()))
    
    expect(sut, toCompleteWith: .failure(anyNSError()))
  }
  
  func test_loadImageData_cachesLoadedDataOnLoaderSuccess() {
    let cache = CacheSpy()
    let data = anyData()
    let url = anyURL()
    let (sut, _) = makeSUT(
      result: .success(data),
      cache: cache
    )
    
    _ = sut.loadImageData(from: url) { _ in }
    
    XCTAssertEqual(
      cache.messages,
      [.save(data, url)],
      "Expected to cache loaded image data on success"
    )
  }
  
  func test_loadImageData_doesNotCacheOnLoaderFailure() {
    let cache = CacheSpy()
    let url = anyURL()
    let (sut, _) = makeSUT(
      result: .failure(anyNSError()),
      cache: cache
    )
    
    _ = sut.loadImageData(from: url) { _ in }
    
    XCTAssert(
      cache.messages.isEmpty,
      "Expected to not cache image data on load error"
    )
  }
  
  func test_cancelLoadImageData_cancelsImageLoaderTaskWithoutCaching() {
    let cache = CacheSpy()
    let url = anyURL()
    let (sut, imageLoader) = makeSUT(
      result: .failure(anyNSError()),
      cache: cache
    )
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    task.cancel()
    XCTAssertEqual(imageLoader.cancelledURLs, [url])
    XCTAssert(cache.messages.isEmpty)
  }
  
  private func expect(
    _ sut: FeedImageDataLoader,
    toCompleteWith expectedResult: FeedImageDataLoader.Result,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for load completion")
    _ = sut.loadImageData(from: anyURL()) { receivedResult in
      switch (expectedResult, receivedResult) {
      case (.success(let data), .success(let receivedData)):
        XCTAssertEqual(data, receivedData, file: file, line: line)
        
      case (.failure, .failure):
        break
        
      default:
        XCTFail("Expected load image result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
      }
      
      exp.fulfill()
    }
    wait(for: [exp], timeout: 0.1)
  }
  
  private func makeSUT(
    result: FeedImageDataLoader.Result,
    cache: CacheSpy = CacheSpy(),
    file: StaticString = #file,
    line: UInt = #line
  ) -> (FeedImageLoaderCacheDecorator, ImageLoaderSpy) {
    let imageLoader = ImageLoaderSpy(result: result)
    let sut = FeedImageLoaderCacheDecorator(
      decoratee: imageLoader,
      cache: cache
    )
    return (sut, imageLoader)
  }
  
  private class CacheSpy: FeedImageCache {
    private(set) var messages: [Message] = []
    
    enum Message: Equatable {
      case save(Data, URL)
    }
    
    func save(
      _ data: Data,
      for url: URL,
      completion: @escaping (FeedImageCache.Result) -> Void
    ) {
      messages.append(.save(data, url))
      completion(.success(()))
    }
  }
}
