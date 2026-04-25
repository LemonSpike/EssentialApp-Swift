import EssentialFeed
import Foundation
import Testing

struct EssentialFeedAPIEndToEndTests {
  
  @Test func testEndToEndTestServerGETFeedResultMatchesFixedTestAccountData() async throws {
    try await LeakChecker { checker in
      let (client, loader, result) = await getFeedResult()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(loader)
      switch result {
      case let .success(imageFeed):
        #expect(imageFeed.count == 8, "Expected 8 images in the test account image feed")
        
        #expect(imageFeed[0] == expectedImage(at: 0))
        #expect(imageFeed[1] == expectedImage(at: 1))
        #expect(imageFeed[2] == expectedImage(at: 2))
        #expect(imageFeed[3] == expectedImage(at: 3))
        #expect(imageFeed[4] == expectedImage(at: 4))
        #expect(imageFeed[5] == expectedImage(at: 5))
        #expect(imageFeed[6] == expectedImage(at: 6))
        #expect(imageFeed[7] == expectedImage(at: 7))
      case let .failure(error):
        #expect(Bool(false), "Expected successful feed result, got \(error) instead")
      @unknown default:
        #expect(Bool(false), "Expected successful feed result, got no result instead")
      }
    }
  }
  
  @Test func test_endToEndTestServerGETFeedImageDataResult_matchesFixedTestAccountData() async throws {
    try await LeakChecker { checker in
      let (client, loader, result) = await getFeedImageDataResult()
      checker.checkForMemoryLeak(client)
      checker.checkForMemoryLeak(loader)
      switch result {
      case let .success(data)?:
        #expect(!data.isEmpty, "Expected non-empty image data")
        
      case let .failure(error)?:
        #expect(Bool(false), "Expected successful image data result, got \(error) instead")
        
      default:
        #expect(Bool(false), "Expected successful image data result, got no result instead")
      }
    }
  }
  
  // MARK: - Helpers
  private func getFeedResult() async -> (URLSessionHTTPClient, RemoteFeedLoader, FeedLoader.Result) {
    let client = ephemeralClient()
    let loader = RemoteFeedLoader(url: feedTestServerURL, client: client)
    
    return (client, loader, await loader.load())
  }
  
  private func getFeedImageDataResult(file: StaticString = #file, line: UInt = #line) async -> (URLSessionHTTPClient, RemoteFeedImageDataLoader, FeedImageDataLoader.Result?) {
    let client = ephemeralClient()
    let loader = RemoteFeedImageDataLoader(client: client)
    
    
    return await withCheckedContinuation { continuation in
      let url = feedTestServerURL.appendingPathComponent("73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6/image")
      
      _ = loader.loadImageData(from: url) { result in
        continuation.resume(returning: (client, loader, result))
      }
    }
  }
  
  private var feedTestServerURL: URL {
    return URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/feed")!
  }
  
  private func ephemeralClient(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
    return URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
  }
  
  private func expectedImage(at index: Int) -> FeedImage {
    return FeedImage(
      id: UUID(uuidString: [
        "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
        "BA298A85-6275-48D3-8315-9C8F7C1CD109",
        "5A0D45B3-8E26-4385-8C5D-213E160A5E3C",
        "FF0ECFE2-2879-403F-8DBE-A83B4010B340",
        "DC97EF5E-2CC9-4905-A8AD-3C351C311001",
        "557D87F1-25D3-4D77-82E9-364B2ED9CB30",
        "A83284EF-C2DF-415D-AB73-2A9B8B04950B",
        "F79BD7F8-063F-46E2-8147-A67635C3BB01"
      ][index])!,
      description: [
        "Description 1",
        nil,
        "Description 3",
        nil,
        "Description 5",
        "Description 6",
        "Description 7",
        "Description 8"
      ][index],
      location: [
        "Location 1",
        "Location 2",
        nil,
        nil,
        "Location 5",
        "Location 6",
        "Location 7",
        "Location 8"
      ][index],
      url: URL(string: "https://url-\(index+1).com")!
    )
  }
}
