import XCTest

final class EssentialAppUIAcceptanceTests: XCTestCase {
  
  @MainActor
  func test_onLaunch_displaysRemoteFeedWhenCustomerHasConnectivity() {
    let app = XCUIApplication()
    app.launchArguments = ["-reset", "-connectivity", "online"]
    app.launch()
    
    let feedCells = app.cells.matching(identifier: "feed-image-cell")
    XCTAssertEqual(feedCells.count, 2)
    
    let firstImage = app.images.matching(identifier: "feed-image-view").firstMatch
    XCTAssertTrue(firstImage.exists)
  }
  
  @MainActor
  func test_onLaunch_displaysCachedRemoteFeedWhenCustomerHasNoConnectivity() {
    let onlineApp = XCUIApplication()
    onlineApp.launchArguments = ["-reset", "-connectivity", "online"]
    onlineApp.launch()
    
    let offlineApp = XCUIApplication()
    offlineApp.launchArguments = ["-connectivity", "offline"]
    offlineApp.launch()
    
    let cachedFeedCells = offlineApp.cells.matching(identifier: "feed-image-cell")
    XCTAssertEqual(cachedFeedCells.count, 2)
    
    let firstCachedImage = offlineApp.images.matching(identifier: "feed-image-view").firstMatch
    XCTAssertTrue(firstCachedImage.exists)
  }
  
  @MainActor
  func test_onLaunch_displaysEmptyFeedWhenCustomerHasNoConnectivityAndNoCache() {
    let offlineApp = XCUIApplication()
    offlineApp.launchArguments = ["-reset", "-connectivity", "offline"]
    offlineApp.launch()
    
    let cachedFeedCells = offlineApp.cells.matching(identifier: "feed-image-cell")
    XCTAssertEqual(cachedFeedCells.count, 0)
    
    let firstCachedImage = offlineApp.images.matching(identifier: "feed-image-view").firstMatch
    XCTAssertFalse(firstCachedImage.exists)
  }
}
