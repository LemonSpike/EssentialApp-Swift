import Foundation

public protocol FeedCache {
  typealias Result = Swift.Result<Void, Error>

  nonisolated func save(
    _ feed: [FeedImage],
    completion: @escaping (Result) -> ()
  )
}
