import Combine
import EssentialFeed
import EssentialFeediOS
import EssentialFeedPresentation
import UIKit

public final class FeedUIComposer {

  private init() {}
  
  public static func feedComposedWith(
    feedLoader: @escaping () -> FeedLoader.Publisher,
    imageLoader: @escaping (URL) -> FeedImageDataLoader.Publisher
  ) -> FeedViewController {
    let presentationAdapter = FeedLoaderPresentationAdapter(feedLoader: feedLoader)
    
    let feedController = FeedViewController.makeWith(
      delegate: presentationAdapter,
      title: FeedPresenter.title
    )

    presentationAdapter.presenter = FeedPresenter(
      loadingView: WeakRefVirtualProxy(feedController),
      feedView: FeedViewAdapter(
        controller: feedController,
        imageLoader: imageLoader
      ),
      errorView: WeakRefVirtualProxy(feedController)
    )
    return feedController
  }
}

private extension FeedViewController {
  static func makeWith(delegate: FeedViewControllerDelegate, title: String) -> FeedViewController {
    let bundle = Bundle(for: FeedViewController.self)
    let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
    let feedController = storyboard.instantiateInitialViewController() as! FeedViewController
    feedController.delegate = delegate
    feedController.title = FeedPresenter.title    
    return feedController
  }
}
