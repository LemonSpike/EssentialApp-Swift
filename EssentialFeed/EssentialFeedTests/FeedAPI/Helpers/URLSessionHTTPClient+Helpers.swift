import EssentialFeed
import Foundation
import Testing

extension HTTPClient {
  func get(from url: URL, taskHandler: @escaping (HTTPClientTask) -> Void = { _ in }) async throws -> Result {
    try await withCheckedThrowingContinuation { continuation in
      let task = get(from: url) { receivedResult in
        continuation.resume(returning: receivedResult)
      }
      taskHandler(task)
    }
  }
}
