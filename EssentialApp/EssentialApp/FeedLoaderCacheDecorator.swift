import EssentialFeed
import Foundation

public protocol FeedCache {
  typealias Result = Swift.Result<Void, Error>

  nonisolated func save(
    _ feed: [FeedImage],
    completion: @escaping (Result) -> ()
  )
}

nonisolated public class FeedLoaderCacheDecorator: FeedLoader {
  private let decoratee: FeedLoader
  private let cache: FeedCache
  
  public init(
    decoratee: FeedLoader,
    cache: FeedCache
  ) {
    self.decoratee = decoratee
    self.cache = cache
  }
  
  public func load(completion: @escaping (FeedLoader.Result) -> Void) {
    decoratee.load { [weak self] result in
      self?.cache.save((try? result.get()) ?? []) { _ in }
      completion(result)
    }
  }
}
