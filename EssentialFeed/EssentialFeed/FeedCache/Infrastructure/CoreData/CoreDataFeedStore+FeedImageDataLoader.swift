import CoreData
import Foundation

extension CoreDataFeedStore: FeedImageDataStore {
  public func insert(_ data: Data, for url: URL, completion: @escaping InsertionCompletion) {
    perform { context in
      completion(Result {
        try ManagedFeedImage.first(with: url, in: context)
          .map { $0.data = data }
          .map(context.save)
      })
    }
  }
  
  public func retrieve(dataForURL url: URL, completion: @escaping FeedImageDataStore.RetrievalCompletion) {
    perform { context in
      completion(Result {
        try ManagedFeedImage.first(with: url, in: context)?.data
      })
    }
  }
}
