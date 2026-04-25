import Testing

/// Checks for memory leaks when going out of scope.
/// Taken from https://github.com/hakkurishian/swift_experiments/blob/master/MemoryLeakChecking/LeakChecker.swift.
final class LeakChecker {
  typealias Checkable = AnyObject & Sendable

  @discardableResult
  func checkForMemoryLeak<T: Checkable>(
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column,
    _ instanceFactory: @autoclosure () -> T
  ) -> T
  {
    let instance = instanceFactory()
    let location = SourceLocation(fileID: fileID, filePath: filePath, line: line, column: column)
    checks.append(
      LeakCheck(
        instance,
        sourceLocation: location
      )
    )
    return instance
  }

  private struct LeakCheck {
    let sourceLocation: SourceLocation
    private weak var weakReference: Checkable?
    var isLeaking: Bool { weakReference != nil }
    init(_ weakReference: Checkable, sourceLocation: SourceLocation) {
      self.weakReference = weakReference
      self.sourceLocation = sourceLocation
    }
  }

  private var checks: [LeakCheck] = []

  typealias Scope = (_ checker: LeakChecker) async throws -> Void

  private let scope: Scope

  @discardableResult
  init(scope: @escaping Scope) async throws {
    self.scope = scope
    try await scope(self)
  }

  deinit {
    for check in checks {
      #expect(
        !check.isLeaking,
        "Instance should have been deallocated: Potential Memory Leak detected",
        sourceLocation: check.sourceLocation
      )
    }
  }
}
