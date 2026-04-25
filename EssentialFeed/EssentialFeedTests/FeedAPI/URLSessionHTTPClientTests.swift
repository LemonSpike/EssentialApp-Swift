import Foundation
import Testing
import EssentialFeed

@Suite
class URLSessionHTTPClientTests {
  
  private static let stubs: [(Data?, URLResponse?, Error?)] = [
    (
      data: nil,
      response: nonHTTPURLResponse(),
      error: nil
    ),
    (
      data: anyData(),
      response: nil,
      error: anyNSError()
    ),
    (
      data: nil,
      response: nonHTTPURLResponse(),
      error: anyNSError()
    ),
    (
      data: nil,
      response: anyHTTPURLResponse(),
      error: anyNSError()
    ),
    (
      data: anyData(),
      response: nonHTTPURLResponse(),
      error: anyNSError()
    ),
    (
      data: anyData(),
      response: nonHTTPURLResponse(),
      error: nil
    )
  ]
  
  deinit {
    URLProtocolStub.removeStub()
  }
  
  @Test func testGetFromURLPerformsGETRequestWithURL() async throws {
    let url = anyURL()
    try await confirmation("Wait for request") { fulfill in
      URLProtocolStub.observeRequests { request in
        #expect(request.url == url)
        #expect(request.httpMethod == "GET")
        fulfill()
      }
      
      _ = try await self.makeSUT().get(from: url)
    }
  }
  
  @Test func test_cancelGetFromURLTask_cancelsURLRequest() async throws {
    let receivedError = try await resultErrorFor(taskHandler: { $0.cancel() }) as? NSError
    
    #expect(receivedError?.code == URLError.cancelled.rawValue)
  }
  
  @Test func testGetFromURLFailsOnRequestError() async throws {
    let requestError = anyNSError()
    let stub: (Data?, URLResponse?, Error?) = (data: nil, response: nil, error: requestError)
    let receivedError = try await resultErrorFor(stub) as? NSError
    
    #expect(receivedError?.domain == requestError.domain)
    #expect(receivedError?.code == requestError.code)
  }
  
  @Test(
    "Invalid representation yields error",
    arguments: stubs
  )
  func testGetFromURLFailsOnAllInvalidRepresentationCases(stub: (Data?, URLResponse?, Error?)) async throws {
    _ = try await resultErrorFor(stub)
  }
  
  @Test("Successful HTTPURLResponse with Data")
  func testGetFromURLSucceedsOnHTTPURLResponseWithData() async throws {
    let data = anyData()
    let response = Self.anyHTTPURLResponse()
    
    let receivedValues = try await resultValuesFor((
      data: data,
      response: response,
      error: nil
    ))
    
    #expect(receivedValues?.data == data)
    #expect(receivedValues?.response.url == response.url)
    #expect(receivedValues?.response.statusCode == response.statusCode)
  }
  
  @Test("Successful HTTPURLResponse with Empty Data")
  func testGetFromURLSucceedsWithEmptyDataOnHTTPURLResponseWithNilData() async throws {
    let response = Self.anyHTTPURLResponse()
    
    let receivedValues = try await resultValuesFor((
      data: nil,
      response: response,
      error: nil
    ))
    
    let emptyData = Data()
    #expect(receivedValues?.data == emptyData)
    #expect(receivedValues?.response.url == response.url)
    #expect(receivedValues?.response.statusCode == response.statusCode)
  }
  
  // MARK: Helpers
  
  private func makeSUT() -> HTTPClient {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [URLProtocolStub.self]
    let session = URLSession(configuration: configuration)
    
    return URLSessionHTTPClient(session: session)
  }
  
  private static func nonHTTPURLResponse() -> URLResponse {
    URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
  }
  
  private static func anyHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
  }
  
  private func resultErrorFor(
    _ values: (data: Data?, response: URLResponse?, error: Error?)? = nil,
    taskHandler: @escaping (HTTPClientTask) -> Void = { _ in },
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column
  ) async throws -> Error? {
    let result = try await resultFor(values, taskHandler: taskHandler)
    switch result {
    case let .failure(error as NSError):
      return error
    default:
      let location = SourceLocation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      #expect(Bool(false), "Expected failure with NSError, got \(result) instead.", sourceLocation: location)
    }
    return nil
  }
  
  private func resultValuesFor(
    _ values: (data: Data?, response: URLResponse?, error: Error?)?,
    fileID: String = #fileID,
    filePath: String = #filePath,
    line: Int = #line,
    column: Int = #column
  ) async throws -> (data: Data, response: HTTPURLResponse)? {
    let result = try await resultFor(values)
    switch result {
    case let .success((data, response)):
      return (data, response)
    default:
      let location = SourceLocation(
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
      )
      #expect(Bool(false), "Expected success with data and response, got result \(result) instead.", sourceLocation: location)
    }
    return nil
  }
  
  private func resultFor(
    _ values: (data: Data?, response: URLResponse?, error: Error?)?,
    taskHandler: @escaping (HTTPClientTask) -> Void = { _ in }
  ) async throws -> HTTPClient.Result {
    values.map {
      URLProtocolStub.stub(
        data: $0,
        response: $1,
        error: $2
      )
    }
    let sut = self.makeSUT()

    return try await sut.get(from: anyURL(), taskHandler: taskHandler)
  }
}
