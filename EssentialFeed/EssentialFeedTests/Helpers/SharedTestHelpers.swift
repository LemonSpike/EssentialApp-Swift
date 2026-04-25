import EssentialFeed
import Foundation

func anyNSError() -> NSError {
  NSError(domain: "Any Error", code: 1)
}

func anyURL() -> URL {
  return URL(string: "http://any-url.com")!
}

func anyData() -> Data {
  return Data("any data".utf8)
}
