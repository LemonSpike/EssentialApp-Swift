import XCTest
import EssentialFeed
import EssentialApp

final class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {
  
  func test_init_doesNotLoadImageData() throws {
    let (_, primaryLoader, fallbackLoader) = makeSUT()
    
    XCTAssert(primaryLoader.loadedURLs.isEmpty)
    XCTAssert(fallbackLoader.loadedURLs.isEmpty)
  }
  
  func test_loadImageData_loadsFromPrimaryLoaderFirst() {
    let url = anyURL()
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    _ = sut.loadImageData(from: url) { _ in }
    
    XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
    XCTAssertTrue(fallbackLoader.loadedURLs.isEmpty, "Expected no loaded URLs in the fallback loader")
  }
  
  func test_loadImageData_loadsFromFallbackOnPrimaryLoaderFailure() {
    let url = anyURL()
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    _ = sut.loadImageData(from: url) { _ in }
    
    primaryLoader.complete(with: anyNSError())
    
    XCTAssertEqual(primaryLoader.loadedURLs, [url], "Expected to load URL from primary loader")
    XCTAssertEqual(fallbackLoader.loadedURLs, [url], "Expected to load URL from fallback loader")
  }
  
  func test_cancelLoadImageData_cancelsPrimaryLoaderTask() throws {
    let url = anyURL()
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    task.cancel()
    XCTAssertEqual(primaryLoader.cancelledURLs, [url])
    XCTAssert(fallbackLoader.cancelledURLs.isEmpty)
  }
  
  func test_cancelLoadImageData_cancelsFallbackLoaderTaskOnPrimaryLoaderFailure() throws {
    let url = anyURL()
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    let task = sut.loadImageData(from: url, completion: { _ in })
    primaryLoader.complete(with: anyNSError())
    task.cancel()
    
    XCTAssert(primaryLoader.cancelledURLs.isEmpty)
    XCTAssertEqual(fallbackLoader.cancelledURLs, [url])
  }
  
  func test_loadImageData_deliversPrimaryDataOnPrimaryLoaderSuccess() throws {
    let primaryData = anyData()
    
    let (sut, primaryLoader, _) = makeSUT()
    
    expect(
      sut,
      toCompleteWith: .success(primaryData),
      when: {
        primaryLoader.complete(data: primaryData)
      }
    )
  }
  
  func test_loadImageData_deliversFallbackDataOnFallbackLoaderSuccess() {
    let fallbackData = anyData()
    
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    expect(
      sut,
      toCompleteWith: .success(fallbackData),
      when: {
        primaryLoader.complete(with: anyNSError())
        fallbackLoader.complete(data: fallbackData)
      }
    )
  }
  
  func test_loadImageData_deliversErrorOnPrimaryLoaderFailureAndFallbackLoaderFailure() {
    let (sut, primaryLoader, fallbackLoader) = makeSUT()
    
    expect(
      sut,
      toCompleteWith: .failure(anyNSError()),
      when: {
        primaryLoader.complete(with: anyNSError())
        fallbackLoader.complete(with: anyNSError())
      }
    )
  }
  
  private func makeSUT(
    file: StaticString = #file,
    line: UInt = #line
  ) -> (FeedImageDataLoader, ImageLoaderSpy, ImageLoaderSpy) {
    let primaryLoader = ImageLoaderSpy()
    let fallbackLoader = ImageLoaderSpy()
    let sut = FeedImageDataLoaderWithFallbackComposite(
      primary: primaryLoader,
      fallback: fallbackLoader
    )
    trackForMemoryLeaks(primaryLoader, file: file, line: line)
    trackForMemoryLeaks(fallbackLoader, file: file, line: line)
    trackForMemoryLeaks(sut, file: file, line: line)
    return (sut, primaryLoader, fallbackLoader)
  }
  
  private func expect(
    _ sut: FeedImageDataLoader,
    toCompleteWith expectedResult: FeedImageDataLoader.Result,
    when action: () -> Void,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for load completion")
    _ = sut.loadImageData(from: anyURL(), completion: { receivedResult in
      switch (expectedResult, receivedResult) {
      case (.success(let data), .success(let receivedData)):
        XCTAssertEqual(data, receivedData, file: file, line: line)
        
      case (.failure, .failure):
        break
        
      default:
        XCTFail("Expected load feed result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
      }
      
      exp.fulfill()
    })
    
    action()
    
    wait(for: [exp], timeout: 0.1)
  }
  
  private func trackForMemoryLeaks(_ instance: AnyObject, file: StaticString = #file, line: UInt = #line) {
    addTeardownBlock { [weak instance] in
      XCTAssertNil(instance, "Instance should have been deallocated. Potential memory leak.", file: file, line: line)
    }
  }
  
  private func anyURL() -> URL {
    URL(string: "http://any-url.com")!
  }
  
  private func anyData() -> Data {
    UUID().uuidString.data(using: .utf8)!
  }
  
  private func anyNSError() -> NSError {
    NSError(domain: "any error", code: 0)
  }
  
  class ImageLoaderSpy: FeedImageDataLoader {
    private struct Task: FeedImageDataLoaderTask {
      let callback: () -> Void
      func cancel() { callback() }
    }
    
    private var messages: [(url: URL, completion: (FeedImageDataLoader.Result) -> Void)] = []
    private(set) var cancelledURLs: [URL] = []
    
    var loadedURLs: [URL] {
      return messages.map { $0.url }
    }
    
    func loadImageData(
      from url: URL,
      completion: @escaping (FeedImageDataLoader.Result) -> Void
    ) -> any FeedImageDataLoaderTask {
      messages.append((url, completion))
      return Task { [weak self] in
        self?.cancelledURLs.append(url)
      }
    }
    
    func complete(with error: Error, at index: Int = 0) {
      messages[index].completion(.failure(error))
    }
    
    func complete(data: Data, at index: Int = 0) {
      messages[index].completion(.success(data))
    }
  }
}
