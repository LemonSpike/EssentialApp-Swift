import Foundation

public protocol FeedImageCache {
  typealias Result = Swift.Result<Void, Error>
  
  nonisolated func save(
    _ data: Data,
    for url: URL,
    completion: @escaping (Result) -> Void
  )
}
