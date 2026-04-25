import Foundation

public final class LocalFeedLoader {
  private let store: FeedStore
  private let currentDate: () -> Date

  public init(store: FeedStore, currentDate: @escaping () -> Date) {
    self.store = store
    self.currentDate = currentDate
  }
}

extension LocalFeedLoader {
  public typealias SaveResult = Result<Void, Error>

  public func save(
    _ feed: [FeedImage],
    completion: @escaping (SaveResult) -> ()
  ) {
    store.deleteCachedFeed { [weak self] deletionResult in
      guard let self else { return }

      switch deletionResult {
        case .success(_):
          cache(feed, with: completion)
        case let .failure(cacheDeletionError):
          completion(.failure(cacheDeletionError))
      }
    }
  }

  private func cache(
    _ feed: [FeedImage],
    with completion: @escaping (SaveResult) -> ()
  ) {
    store.insert(
      feed.toLocal(),
      timestamp: self.currentDate()
    ) { [weak self] result in
      guard self != nil else { return }
      completion(result)
    }
  }
}

extension LocalFeedLoader: FeedLoader {
  public typealias LoadResult = FeedLoader.Result

  public func load(completion: @escaping (LoadResult) -> Void) {
    store.retrieve { [weak self] result in
      guard let self else { return }
      switch result {
        case let .failure(error):
          completion(.failure(error))
        case let .success(.some(cache)) where FeedCachePolicy.validate(
          cache.timestamp,
          against: currentDate()
        ):
          completion(.success(cache.feed.toModels()))
        case .success:
          completion(.success([]))
      }
    }
  }
}

extension LocalFeedLoader {
  public typealias ValidationResult = Result<Void, Error>
  
  public func validateCache(completion: @escaping (ValidationResult) -> Void) {
    store.retrieve { [weak self] result in
      guard let self else { return }
      switch result {
        case .failure:
          store.deleteCachedFeed(completion: completion)
        case let .success(.some(cache)) where !FeedCachePolicy.validate(cache.timestamp, against: currentDate()):
          store.deleteCachedFeed(completion: completion)
        case .success:
        completion(.success(()))
      }
    }
  }
}

private extension Array where Element == FeedImage {
  func toLocal() -> [LocalFeedImage] {
    map {
      LocalFeedImage(
        id: $0.id,
        description: $0.description,
        location: $0.location,
        url: $0.url
      )
    }
  }
}

private extension Array where Element == LocalFeedImage {
  func toModels() -> [FeedImage] {
    map {
      FeedImage(
        id: $0.id,
        description: $0.description,
        location: $0.location,
        url: $0.url
      )
    }
  }
}
