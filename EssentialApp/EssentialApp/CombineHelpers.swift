import Combine
import EssentialFeed
import Foundation

public extension FeedImageDataLoader {
  typealias Publisher = AnyPublisher<Data, Error>
  func loadImageDataPublisher(from url: URL) -> Publisher {
    var task: FeedImageDataLoaderTask?
    
    return Deferred {
      Future { completion in
        task = self.loadImageData(from: url, completion: completion)
      }
    }
    .handleEvents(receiveCancel: { task?.cancel() })
    .eraseToAnyPublisher()
  }
}

extension Publisher where Output == Data {
  func caching(to cache: FeedImageCache, using url: URL) -> AnyPublisher<Output, Failure> {
    handleEvents(receiveOutput: { data in
      cache.saveIgnoringResult(data, for: url)
    }).eraseToAnyPublisher()
  }
}

extension FeedImageCache {
  nonisolated func saveIgnoringResult(_ data: Data, for url: URL) {
    save(data, for: url) { _ in }
  }
}

public extension FeedLoader {
  typealias Publisher = AnyPublisher<[FeedImage], Error>
  func loadPublisher() -> Publisher {
    return Deferred {
      Future(self.load)
    }
    .eraseToAnyPublisher()
  }
}

extension Publisher {
  func fallback(to fallbackPublisher: @escaping () -> AnyPublisher<Output, Failure>) -> AnyPublisher<Output, Failure> {
    self.catch { _ in fallbackPublisher() }
    .eraseToAnyPublisher()
  }
}

extension Publisher where Output == [FeedImage] {
  func caching(to cache: FeedCache) -> AnyPublisher<Output, Failure> {
    handleEvents(receiveOutput: cache.saveIgnoringResult).eraseToAnyPublisher()
  }
}

extension FeedCache {
  nonisolated func saveIgnoringResult(_ feed: [FeedImage]) {
    save(feed) { _ in }
  }
}

extension Publisher {
  func dispatchOnMainQueue() -> AnyPublisher<Output, Failure> {
    receive(on: DispatchQueue.immediateWhenOnMainQueueScheduler)
      .eraseToAnyPublisher()
  }
}

extension DispatchQueue {
  static var immediateWhenOnMainQueueScheduler: ImmediateWhenOnMainQueueScheduler { ImmediateWhenOnMainQueueScheduler()
  }
  
  struct ImmediateWhenOnMainQueueScheduler: Scheduler {
    typealias SchedulerTimeType = DispatchQueue.SchedulerTimeType
    typealias SchedulerOptions = DispatchQueue.SchedulerOptions
    
    var now: SchedulerTimeType {
      DispatchQueue.main.now
    }
    
    var minimumTolerance: SchedulerTimeType.Stride {
      DispatchQueue.main.minimumTolerance
    }
    
    func schedule(options: SchedulerOptions?, _ action: @escaping () -> Void) {
      guard Thread.isMainThread else {
        return DispatchQueue.main.schedule(options: options, action)
      }
      action()
    }
    
    func schedule(after date: SchedulerTimeType, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) {
      DispatchQueue.main.schedule(after: date, tolerance: tolerance, options: options, action)
    }
    
    func schedule(after date: SchedulerTimeType, interval: SchedulerTimeType.Stride, tolerance: SchedulerTimeType.Stride, options: SchedulerOptions?, _ action: @escaping () -> Void) -> any Cancellable {
      DispatchQueue.main.schedule(after: date, interval: interval, tolerance: tolerance, options: options, action)
    }
  }
}
