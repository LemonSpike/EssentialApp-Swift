import EssentialFeed
import Foundation

nonisolated public class FeedLoaderCacheDecorator: FeedLoader {
  private let decoratee: FeedLoader
  
  public init(
    decoratee: FeedLoader
  ) {
    self.decoratee = decoratee
  }
  
  public func load(completion: @escaping (FeedLoader.Result) -> Void) {
    self.decoratee.load(completion: completion)
  }
}
