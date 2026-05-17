import XCTest
import EssentialFeed
import EssentialApp

class FeedImageLoaderWithFallbackComposite: FeedImageDataLoader {
    let primary: FeedImageDataLoader
    let fallback: FeedImageDataLoader
    
    public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }

    private class TaskWrapper: FeedImageDataLoaderTask {
        private var completion: ((FeedImageDataLoader.Result) -> Void)?
        
        var wrapped: HTTPClientTask?
        
        init(_ completion: @escaping (FeedImageDataLoader.Result) -> Void) {
            self.completion = completion
        }
        
        func complete(with result: FeedImageDataLoader.Result) {
            completion?(result)
        }
        
        func cancel() {
            preventFurtherCompletions()
            wrapped?.cancel()
        }
        
        private func preventFurtherCompletions() {
            completion = nil
        }
    }
    
    func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> any FeedImageDataLoaderTask {
        primary.loadImageData(from: url) { [weak self] result in
            switch result {
            case .success:
                completion(result)
            case .failure:
                _ = self?.fallback.loadImageData(
                    from: url,
                    completion: completion
                )
            }
        }
    }
}

final class FeedImageLoaderWithFallbackCompositeTests: XCTestCase {
    
    func test_load_deliversPrimaryFeedOnPrimaryLoaderSuccess() throws {
        let primaryData = anyData()
        let fallbackData = anyData()
        
        let sut = makeSUT(
            primaryResult: .success(primaryData),
            fallbackResult: .success(fallbackData)
        )
        
        expect(
            sut,
            fromURL: anyURL(),
            toCompleteWith: .success(primaryData)
        )
    }
    
    func test_load_deliversFallbackFeedOnPrimaryLoaderFailure() {
        let fallbackData = anyData()
        
        let sut = makeSUT(
            primaryResult: .failure(anyNSError()),
            fallbackResult: .success(fallbackData)
        )
        
        expect(
            sut,
            fromURL: anyURL(),
            toCompleteWith: .success(fallbackData)
        )
    }
    
    func test_load_deliversErrorOnPrimaryLoaderFailureAndFallbackLoaderFailure() {
        let sut = makeSUT(
            primaryResult: .failure(anyNSError()),
            fallbackResult: .failure(anyNSError())
        )
        
        expect(
            sut,
            fromURL: anyURL(),
            toCompleteWith: .failure(anyNSError())
        )
    }
    
    func test_load_deliversPrimaryFeedOnPrimaryLoaderURL() {
        
    }
    
    private func makeSUT(
        primaryResult: FeedImageDataLoader.Result,
        fallbackResult: FeedImageDataLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) -> FeedImageDataLoader {
        let primaryLoader = ImageLoaderStub(result: primaryResult)
        let fallbackLoader = ImageLoaderStub(result: fallbackResult)
        let sut = FeedImageLoaderWithFallbackComposite(
            primary: primaryLoader,
            fallback: fallbackLoader
        )
        trackForMemoryLeaks(primaryLoader, file: file, line: line)
        trackForMemoryLeaks(fallbackLoader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func expect(
        _ sut: FeedImageDataLoader,
        fromURL url: URL,
        toCompleteWith expectedResult: FeedImageDataLoader.Result,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for load completion")
        _ = sut.loadImageData(from: url, completion: { receivedResult in
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
    
    private class ImageLoaderStub: FeedImageDataLoader {
        private let result: FeedImageDataLoader.Result
        
        init(result: FeedImageDataLoader.Result) {
            self.result = result
        }
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> any FeedImageDataLoaderTask {
            completion(result)
            return ImageLoaderTaskStub()
        }
    }
    
    private class ImageLoaderTaskStub: FeedImageDataLoaderTask {
        func cancel() { }
    }
}
