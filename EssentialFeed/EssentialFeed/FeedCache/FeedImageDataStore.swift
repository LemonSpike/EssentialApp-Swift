import Foundation

public protocol FeedImageDataStore {
  typealias RetrievalResult = Swift.Result<Data?, Error>
  typealias RetrievalCompletion  = (RetrievalResult) -> Void

  typealias InsertionResult = Result<Void, Error>
  typealias InsertionCompletion = (InsertionResult) -> Void

  /// The completion handler can be invoked in any thread.
  /// Clients are responsible to dispatch to appropriate threads, if needed.
  func insert(_ data: Data, for url: URL, completion: @escaping InsertionCompletion)
  
  /// The completion handler can be invoked in any thread.
  /// Clients are responsible to dispatch to appropriate threads, if needed.
  func retrieve(dataForURL url: URL, completion: @escaping RetrievalCompletion)
}
