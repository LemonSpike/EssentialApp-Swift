import Foundation

protocol FeedStoreSpecs {
  func testRetrieveDeliversEmptyOnEmptyCache()
  func testRetrieveHasNoSideEffectsOnEmptyCache()
  func testRetrieveDeliversFoundValuesOnNonEmptyCache()
  func testRetrieveHasNoSideEffectsOnNonEmptyCache()
  
  func testInsertDeliversNoErrorOnEmptyCache()
  func testInsertDeliversNoErrorOnNonEmptyCache()
  func testInsertOverridesPreviouslyInsertedCacheValues()
  
  func testDeleteDeliversNoErrorOnEmptyCache()
  func testDeleteHasNoSideEffectsOnEmptyCache()
  func testDeleteDeliversNoErrorOnNonEmptyCache()
  func testDeleteEmptiesPreviouslyInsertedCache()
  
  func testStoreSideEffectsRunSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
  func testRetrieveDeliversFailureOnRetrievalError()
  func testRetrieveHasNoSideEffectsOnFailure()
}

protocol FailableInsertFeedStoreSpecs: FeedStoreSpecs {
  func testInsertDeliversErrorOnInsertionError()
  func testInsertHasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedStoreSpecs: FeedStoreSpecs {
  func testDeleteDeliversErrorOnDeletionError()
  func testDeleteHasNoSideEffectsOnDeletionError()
}

typealias FailableFeedStore = FailableRetrieveFeedStoreSpecs & FailableInsertFeedStoreSpecs & FailableDeleteFeedStoreSpecs

