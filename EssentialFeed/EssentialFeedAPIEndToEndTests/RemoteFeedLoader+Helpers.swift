import EssentialFeed
import Foundation

extension RemoteFeedLoader {
  public func load() async -> Result {
    await withCheckedContinuation { continuation in
      load { result in
        continuation.resume(returning: result)
      }
    }
  }
}
