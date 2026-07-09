import CoreData
import EssentialFeedCache
import Foundation

extension CoreDataFeedStore: FeedStore {
  
  public func retrieve(completion: @escaping FeedStore.RetrievalCompletion) {
    perform { context in
      completion(Result {
        try ManagedCache.find(in: context).map {
          return CachedFeed(feed: $0.localFeed, timestamp: $0.timestamp)
        }
      })
    }
  }
  
  public func insert(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
    perform { context in
      completion(Result {
        do {
          let managedCache = try ManagedCache.newUniqueInstance(in: context)
          managedCache.timestamp = timestamp
          managedCache.feed = ManagedFeedImage.images(from: feed, in: context)
          
          try context.save()
        } catch {
          context.rollback()
          throw error
        }
      })
    }
  }
  
  public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
    perform { context in
      completion(Result {
        do {
          try ManagedCache.find(in: context).map(context.delete).map(context.save)
        } catch {
          context.rollback()
          throw error
        }
      })
    }
  }
  
}
