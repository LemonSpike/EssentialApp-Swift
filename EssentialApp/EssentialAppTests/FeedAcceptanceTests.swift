import EssentialFeed
import EssentialFeediOS
import XCTest
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
  
  func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
    let feed = launch(
      httpClient: .online(response),
      store: .empty
    )
    
    XCTAssertEqual(feed.numberOfRenderedFeedImageViews(), 2)
    XCTAssertEqual(feed.renderedFeedImageData(at: 0), makeImageData())
    XCTAssertEqual(feed.renderedFeedImageData(at: 1), makeImageData())
  }
  
  func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
    
  }
  
  func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
    
  }
  
  private func launch(
    httpClient: HTTPClientStub = .offline,
    store: InMemoryFeedStore = .empty
  ) -> FeedViewController {
    let sut = SceneDelegate(httpClient: httpClient, store: store)
    sut.window = UIWindow()
    sut.configureWindow()
    
    let nav = sut.window?.rootViewController as? UINavigationController
    let feed = nav?.topViewController as! FeedViewController
    
    feed.simulateAppearance()
    
    return feed
  }
  
  private func response(for url: URL) -> (Data, HTTPURLResponse) {
    let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
    return (makeData(for: url), response)
  }
  
  private func makeData(for url: URL) -> Data {
    switch url.absoluteString {
    case "http://image.com":
      return makeImageData()
      
    default:
      return makeFeedData()
    }
  }
  
  private func makeImageData() -> Data {
    return UIImage.make(withColor: .red).pngData()!
  }
  
  private func makeFeedData() -> Data {
    return try! JSONSerialization.data(withJSONObject: ["items": [
      ["id": UUID().uuidString, "image": "http://image.com"],
      ["id": UUID().uuidString, "image": "http://image.com"]
    ]])
  }
}
