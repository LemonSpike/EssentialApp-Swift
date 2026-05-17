import CoreData
import EssentialFeed
import EssentialFeediOS
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let _ = (scene as? UIWindowScene) else { return }
    
    let urlSession = URLSession(configuration: .ephemeral)
    let remoteURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
    let remoteClient = URLSessionHTTPClient(session: urlSession)
    let remoteFeedLoader = RemoteFeedLoader(
      url: remoteURL,
      client: remoteClient
    )
    let remoteImageLoader = RemoteFeedImageDataLoader(client: remoteClient)
    
    let localStoreURL = NSPersistentContainer
      .defaultDirectoryURL()
      .appendingPathComponent("feed-store.sqlite")
    let localStore = try! CoreDataFeedStore(storeURL: localStoreURL)
    let localFeedLoader = LocalFeedLoader(store: localStore, currentDate: Date.init)
    let localImageLoader = LocalFeedImageDataLoader(store: localStore)
    
    let compositeFeedLoader = FeedLoaderWithFallbackComposite(
      primary: remoteFeedLoader,
      fallback: localFeedLoader
    )
    
    let compositeImageLoader = FeedImageDataLoaderWithFallbackComposite(
      primary: localImageLoader,
      fallback: remoteImageLoader
    )
    
    let feedViewController = FeedUIComposer.feedComposedWith(
      feedLoader: compositeFeedLoader,
      imageLoader: compositeImageLoader
    )
    
    window?.rootViewController = feedViewController
  }
}

