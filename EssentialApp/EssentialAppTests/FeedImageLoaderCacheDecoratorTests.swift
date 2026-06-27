import EssentialApp
import EssentialFeed
import XCTest

class FeedImageLoaderCacheDecoratorTests: XCTestCase, FeedImageDataLoaderTestCase {
  
  func test_init_doesNotLoadImageData() {
    let (_, loader) = makeSUT()
    
    XCTAssertTrue(loader.loadedURLs.isEmpty, "Expected no loaded URLs")
  }
  
  func test_loadImageData_loadsFromLoader() {
    let url = anyURL()
    let (sut, loader) = makeSUT()
    
    _ = sut.loadImageData(from: url) { result in }
    
    XCTAssertEqual(
      loader.loadedURLs,
      [url],
      "Expected to load URL from loader"
    )
  }
  
  func test_cancelLoadImageData_cancelsImageLoaderTask() {
    let url = anyURL()
    let (sut, imageLoader) = makeSUT()
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    task.cancel()
    XCTAssertEqual(imageLoader.cancelledURLs, [url])
  }
  
  func test_cancelLoadImageData_doesNotCache() {
    let cache = CacheSpy()
    let url = anyURL()
    let (sut, _) = makeSUT(
      cache: cache
    )
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    task.cancel()
    XCTAssertTrue(cache.messages.isEmpty)
  }
  
  func test_loadImageData_deliversDataOnLoaderSuccess() {
    let imageData = anyData()
    let (sut, loader) = makeSUT()
    
    expect(sut, toCompleteWith: .success(imageData), when: {
      loader.complete(data: imageData)
    })
  }
  
  func test_loadImageData_deliversErrorOnLoaderFailure() {
    let error = anyNSError()
    let (sut, loader) = makeSUT()
    
    expect(sut, toCompleteWith: .failure(error), when: {
      loader.complete(with: error)
    })
  }
  
  func test_loadImageData_cachesLoadedDataOnLoaderSuccess() {
    let cache = CacheSpy()
    let data = anyData()
    let url = anyURL()
    let (sut, loader) = makeSUT(
      cache: cache
    )
    
    _ = sut.loadImageData(from: url) { _ in }
    loader.complete(data: data)
    
    XCTAssertEqual(
      cache.messages,
      [.save(data, url)],
      "Expected to cache loaded image data on success"
    )
  }
  
  func test_loadImageData_doesNotCacheOnLoaderFailure() {
    let cache = CacheSpy()
    let url = anyURL()
    let (sut, loader) = makeSUT(
      cache: cache
    )
    
    _ = sut.loadImageData(from: url) { _ in }
    loader.complete(with: anyNSError())
    
    XCTAssert(
      cache.messages.isEmpty,
      "Expected to not cache image data on load error"
    )
  }
  
  private func makeSUT(
    cache: CacheSpy = CacheSpy(),
    file: StaticString = #file,
    line: UInt = #line
  ) -> (FeedImageLoaderCacheDecorator, ImageLoaderSpy) {
    let imageLoader = ImageLoaderSpy()
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
