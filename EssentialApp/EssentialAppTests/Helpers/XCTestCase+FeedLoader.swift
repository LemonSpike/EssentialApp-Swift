import EssentialFeed
import Foundation
import XCTest

protocol FeedLoaderTestCase: XCTestCase { }

extension FeedLoaderTestCase {
  func expect(
    _ sut: FeedLoader,
    toCompleteWith expectedResult: FeedLoader.Result,
    file: StaticString = #file,
    line: UInt = #line
  ) {
    let exp = expectation(description: "Wait for load completion")
    sut.load { receivedResult in
      switch (expectedResult, receivedResult) {
      case (.success(let feed), .success(let receivedFeed)):
        XCTAssertEqual(feed, receivedFeed, file: file, line: line)
        
      case (.failure, .failure):
        break
        
      default:
        XCTFail("Expected load feed result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
      }
      
      exp.fulfill()
    }
    wait(for: [exp], timeout: 0.1)
  }
}
