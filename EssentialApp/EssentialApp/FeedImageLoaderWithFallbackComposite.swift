import EssentialFeed
import Foundation

nonisolated public class FeedImageLoaderWithFallbackComposite: FeedImageDataLoader {
  let primary: FeedImageDataLoader
  let fallback: FeedImageDataLoader
  
  public init(primary: FeedImageDataLoader, fallback: FeedImageDataLoader) {
    self.primary = primary
    self.fallback = fallback
  }
  
  private class FeedImageDataLoaderTaskWrapper: FeedImageDataLoaderTask {
    private var completion: ((FeedImageDataLoader.Result) -> Void)?
    
    var wrapped: FeedImageDataLoaderTask?
    
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
  
  public func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> any FeedImageDataLoaderTask {
    
    let task =  FeedImageDataLoaderTaskWrapper(completion)
    
    task.wrapped = primary.loadImageData(from: url) { [weak self] result in
      switch result {
      case .success:
        completion(result)
      case .failure:
        task.wrapped = self?.fallback.loadImageData(
          from: url,
          completion: completion
        )
      }
    }
    
    return task
  }
}
