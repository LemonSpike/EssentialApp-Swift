import EssentialFeed
import Foundation

nonisolated public class FeedImageLoaderCacheDecorator: FeedImageDataLoader {
  private let decoratee: FeedImageDataLoader
  private let cache: FeedImageCache
  
  public init(
    decoratee: FeedImageDataLoader,
    cache: FeedImageCache
  ) {
    self.decoratee = decoratee
    self.cache = cache
  }
  
  public func loadImageData(
    from url: URL,
    completion: @escaping (FeedImageDataLoader.Result) -> Void
  ) -> FeedImageDataLoaderTask {
    decoratee.loadImageData(from: url) { [weak self] result in
      completion(result.map { data in
        self?.cache.saveIgnoringResult(data, for: url)
        return data
      })
    }
  }
}

private extension FeedImageCache {
  nonisolated func saveIgnoringResult(
    _ data: Data,
    for url: URL
  ) {
    save(data, for: url) { _ in }
  }
}
