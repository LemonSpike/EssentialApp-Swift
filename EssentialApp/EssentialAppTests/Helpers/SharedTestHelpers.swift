import EssentialFeed
import Foundation

func anyURL() -> URL {
  URL(string: "http://any-url.com")!
}

func anyData() -> Data {
  UUID().uuidString.data(using: .utf8)!
}

func anyNSError() -> NSError {
  NSError(domain: "any error", code: 0)
}

func uniqueFeed() -> [FeedImage] {
  [FeedImage(id: UUID(), description: "any", location: "any", url: anyURL())]
}
