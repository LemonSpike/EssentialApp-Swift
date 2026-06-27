import EssentialFeed
import Foundation

class FeedImageDataLoaderTaskStub: FeedImageDataLoaderTask {
  func cancel() { }
}

class FeedImageLoaderStub: FeedImageDataLoader {
  private let result: FeedImageDataLoader.Result
  
  init(result: FeedImageDataLoader.Result) {
    self.result = result
  }
  
  func loadImageData(
    from url: URL,
    completion: @escaping (FeedImageDataLoader.Result) -> Void
  ) -> FeedImageDataLoaderTask {
    completion(result)
    return FeedImageDataLoaderTaskStub()
  }
}
