import CoreData
import EssentialFeed
import EssentialFeedAPI
import EssentialFeedCache
import EssentialFeedCacheInfrastructure
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  private lazy var httpClient: HTTPClient = {
    URLSessionHTTPClient(session: URLSession(configuration: .ephemeral))
  }()
  
  private lazy var store: FeedStore & FeedImageDataStore = {
    let localStoreURL = NSPersistentContainer
      .defaultDirectoryURL()
      .appendingPathComponent("feed-store.sqlite")
    return try! CoreDataFeedStore(storeURL: localStoreURL)
  }()
  
  private lazy var localFeedLoader: LocalFeedLoader = {
    LocalFeedLoader(store: store, currentDate: Date.init)
  }()
  
  convenience init(httpClient: HTTPClient, store: FeedStore & FeedImageDataStore) {
    self.init()
    self.httpClient = httpClient
    self.store = store
  }
  
  func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
    guard let _ = (scene as? UIWindowScene) else { return }
    
    configureWindow()
  }
  
  func configureWindow() {
    let remoteURL = URL(string: "https://ile-api.essentialdeveloper.com/essential-feed/v1/feed")!
    let remoteFeedLoader = RemoteFeedLoader(
      url: remoteURL,
      client: httpClient
    )
    let remoteImageLoader = RemoteFeedImageDataLoader(client: httpClient)
  
    let localImageLoader = LocalFeedImageDataLoader(store: store)
    
    let compositeFeedLoader = FeedLoaderWithFallbackComposite(
      primary: FeedLoaderCacheDecorator(
        decoratee: remoteFeedLoader,
        cache: localFeedLoader),
      fallback: localFeedLoader
    )
    
    let compositeImageLoader = FeedImageDataLoaderWithFallbackComposite(
      primary: localImageLoader,
      fallback: FeedImageLoaderCacheDecorator(
        decoratee: remoteImageLoader,
        cache: localImageLoader
      )
    )
    
    window?.rootViewController = UINavigationController(
      rootViewController: FeedUIComposer.feedComposedWith(
        feedLoader: compositeFeedLoader,
        imageLoader: compositeImageLoader
      )
    )
  }
  
  func sceneWillResignActive(_ scene: UIScene) {
    localFeedLoader.validateCache { _ in }
  }
}
