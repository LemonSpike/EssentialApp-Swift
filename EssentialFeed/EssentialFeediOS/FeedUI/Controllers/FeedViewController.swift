import EssentialFeed
import UIKit

protocol FeedViewControllerDelegate {
  func didRequestFeedRefresh()
}

final public class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching, FeedLoadingView, FeedErrorView {
  
  var delegate: FeedViewControllerDelegate?

  @IBOutlet private(set) public var errorView: ErrorView?
  
  var tableModel: [FeedImageCellController] = [] {
    didSet { tableView.reloadData() }
  }
  
  public override func viewIsAppearing(_ animated: Bool) {
    super.viewIsAppearing(animated)

    refresh()
  }

  // MARK: - FeedLoadingView
  @IBAction private func refresh() {
    delegate?.didRequestFeedRefresh()
  }

  public func display(_ viewModel: FeedLoadingViewModel) {
    refreshControl?.update(isRefreshing: viewModel.isLoading)
  }
  
  public func display(_ viewModel: FeedErrorViewModel) {
    errorView?.message = viewModel.message
  }

  // MARK: - UITableViewDataSource and UITableViewDelegate
  public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    tableModel.count
  }
  
  public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    cellController(forRowAt: indexPath).view(in: tableView)
  }

  public override func tableView(
    _ tableView: UITableView,
    willDisplay cell: UITableViewCell,
    forRowAt indexPath: IndexPath
  ) {
    cellController(forRowAt: indexPath).preload()
  }

  public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    cancelCellControllerLoad(forRowAt: indexPath)
  }
  
  public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
    indexPaths.forEach { indexPath in
      cellController(forRowAt: indexPath).preload()
    }
  }
  
  public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
    indexPaths.forEach(cancelCellControllerLoad)
  }
  
  private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
    tableModel[indexPath.row]
  }
  
  private func cancelCellControllerLoad(forRowAt indexPath: IndexPath) {
    cellController(forRowAt: indexPath).cancelLoad()
  }
}
