//
//  NetworkManagerTests.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import XCTest

@testable import RCKit

final class NetworkManagerTests: XCTestCase {
  // Mock data for testing
  let testJSON = """
    {
        "id": 123,
        "name": "Test User",
        "email": "test@example.com"
    }
    """.data(using: .utf8)!

  var networkManager: NetworkManager!

  override func setUp() {
    super.setUp()

    // Register the mock URL protocol
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]

    networkManager = NetworkManager(configuration: config)

    // Reset mock handlers between tests
    MockURLProtocol.reset()
  }

  // MARK: - GET Tests

  func testGetRequest() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 200,
        data: testJSON
      ),
      for: "/test"
    )

    // Make the request
    let data = try await networkManager.get("https://example.com/test")

    // Verify the response
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? Int, 123)
    XCTAssertEqual(json?["name"] as? String, "Test User")
    XCTAssertEqual(json?["email"] as? String, "test@example.com")

    // Verify the request was made with the correct method
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "GET")
  }

  func testGetWithParameters() async throws {
    // Set up mock response - match any query string since parameter order is not guaranteed
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 200,
        data: testJSON,
        isRegex: true
      ),
      for: ".*\\?.*param1=value1.*"
    )

    // Make the request with parameters
    let data = try await networkManager.get(
      "https://example.com/test",
      parameters: ["param1": "value1", "param2": "value2"]
    )

    // Verify the response
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? Int, 123)

    // Verify the request was made with the correct query parameters
    let request = MockURLProtocol.lastRequest()
    XCTAssertNotNil(request?.url?.query)
    XCTAssertTrue(request?.url?.query?.contains("param1=value1") ?? false)
    XCTAssertTrue(request?.url?.query?.contains("param2=value2") ?? false)
  }

  func testGetAndDecodeResponse() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 200,
        data: testJSON
      ),
      for: "/user"
    )

    // Make the request and decode response
    let user = try await networkManager.get(
      "https://example.com/user",
      as: TestUser.self
    )

    // Verify the decoded object
    XCTAssertEqual(user.id, 123)
    XCTAssertEqual(user.name, "Test User")
    XCTAssertEqual(user.email, "test@example.com")
  }

  // MARK: - POST Tests

  func testPostWithData() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 201,
        data: testJSON
      ),
      for: "/create"
    )

    // Test data to send
    let postData = "Hello, world!".data(using: .utf8)!

    // Make the request
    let data = try await networkManager.post(
      "https://example.com/create",
      body: postData
    )

    // Verify the response
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? Int, 123)

    // Verify the request was made with the correct method and body
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "POST")
    XCTAssertEqual(request?.httpBody, postData)
  }

  func testPostWithJSON() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 201,
        data: testJSON
      ),
      for: "/create-json"
    )

    // Codable object to send
    struct Payload: Codable {
      let key: String
      let number: Int
    }
    let payload = Payload(key: "value", number: 42)

    // Make the request
    let data = try await networkManager.post(
      "https://example.com/create-json",
      object: payload
    )

    // Verify the response
    let user = try JSONDecoder().decode(TestUser.self, from: data)
    XCTAssertEqual(user.id, 123)

    // Verify the request was made with the correct method, body and Content-Type header
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "POST")
    XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")

    if let httpBody = request?.httpBody {
      let sentPayload = try JSONDecoder().decode(Payload.self, from: httpBody)
      XCTAssertEqual(sentPayload.key, "value")
      XCTAssertEqual(sentPayload.number, 42)
    } else {
      XCTFail("HTTP body should not be nil")
    }
  }

  func testPostWithEncodableObject() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 201,
        data: testJSON
      ),
      for: "/create-user"
    )

    // Encodable object to send
    let user = TestUser(id: 456, name: "New User", email: "new@example.com")

    // Make the request
    let data = try await networkManager.post(
      "https://example.com/create-user",
      object: user
    )

    // Verify the response
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? Int, 123)

    // Verify the request was made with the correct method, body and Content-Type header
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "POST")
    XCTAssertEqual(request?.value(forHTTPHeaderField: "Content-Type"), "application/json")

    if let httpBody = request?.httpBody {
      let sentUser = try JSONDecoder().decode(TestUser.self, from: httpBody)
      XCTAssertEqual(sentUser.id, 456)
      XCTAssertEqual(sentUser.name, "New User")
      XCTAssertEqual(sentUser.email, "new@example.com")
    } else {
      XCTFail("HTTP body should not be nil")
    }
  }

  // MARK: - PUT Tests

  func testPutRequest() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 200,
        data: testJSON
      ),
      for: "/update"
    )

    // Test data to send
    let putData = "Updated data".data(using: .utf8)!

    // Make the request
    let data = try await networkManager.put(
      "https://example.com/update",
      body: putData
    )

    // Verify the response
    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(json?["id"] as? Int, 123)

    // Verify the request was made with the correct method and body
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "PUT")
    XCTAssertEqual(request?.httpBody, putData)
  }

  // MARK: - DELETE Tests

  func testDeleteRequest() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 204,
        data: Data()
      ),
      for: "/delete"
    )

    // Make the request
    let data = try await networkManager.delete("https://example.com/delete")

    // Verify the response is empty
    XCTAssertEqual(data.count, 0)

    // Verify the request was made with the correct method
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.httpMethod, "DELETE")
  }

  // MARK: - Error Handling Tests

  func testBadRequestError() async {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 400,
        data: "Bad request".data(using: .utf8)!
      ),
      for: "/bad-request"
    )

    // Make the request and expect an error
    do {
      _ = try await networkManager.get("https://example.com/bad-request")
      XCTFail("Expected error to be thrown")
    } catch let error as NetworkError {
      if case .badRequest(let data, _) = error {
        XCTAssertEqual(String(data: data, encoding: .utf8), "Bad request")
      } else {
        XCTFail("Expected badRequest error")
      }
    } catch {
      XCTFail("Expected NetworkError.badRequest")
    }
  }

  func testUnauthorizedError() async {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 401,
        data: Data()
      ),
      for: "/unauthorized"
    )

    // Make the request and expect an error
    do {
      _ = try await networkManager.get("https://example.com/unauthorized")
      XCTFail("Expected error to be thrown")
    } catch let error as NetworkError {
      if case .unauthorized = error {
        // Success - error is unauthorized
      } else {
        XCTFail("Expected NetworkError.unauthorized, got \(error)")
      }
    } catch {
      XCTFail("Expected NetworkError.unauthorized")
    }
  }

  func testServerError() async {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 500,
        data: Data()
      ),
      for: "/server-error"
    )

    // Make the request and expect an error
    do {
      _ = try await networkManager.get("https://example.com/server-error")
      XCTFail("Expected error to be thrown")
    } catch let error as NetworkError {
      if case .serverError(let code, _) = error {
        XCTAssertEqual(code, 500)
      } else {
        XCTFail("Expected serverError error")
      }
    } catch {
      XCTFail("Expected NetworkError.serverError")
    }
  }

  // MARK: - Header Tests

  func testDefaultHeaders() async throws {
    // Set up mock response
    MockURLProtocol.setResponse(
      MockResponse(
        statusCode: 200,
        data: testJSON
      ),
      for: "/headers"
    )

    // Set default headers
    networkManager.setDefaultHeader("DefaultValue", forKey: "X-Default-Header")

    // Make the request with additional headers
    _ = try await networkManager.get(
      "https://example.com/headers",
      headers: ["X-Custom-Header": "CustomValue"]
    )

    // Verify the request was made with both headers
    let request = MockURLProtocol.lastRequest()
    XCTAssertEqual(request?.value(forHTTPHeaderField: "X-Default-Header"), "DefaultValue")
    XCTAssertEqual(request?.value(forHTTPHeaderField: "X-Custom-Header"), "CustomValue")

    // Test removing a default header
    networkManager.removeDefaultHeader(forKey: "X-Default-Header")

    // Make another request
    _ = try await networkManager.get("https://example.com/headers")

    // Verify the default header is no longer present
    let newRequest = MockURLProtocol.lastRequest()
    XCTAssertNil(newRequest?.value(forHTTPHeaderField: "X-Default-Header"))

    // Test clearing all default headers
    networkManager.setDefaultHeader("AnotherValue", forKey: "X-Another-Header")
    networkManager.clearDefaultHeaders()

    // Make another request
    _ = try await networkManager.get("https://example.com/headers")

    // Verify no default headers are present
    let finalRequest = MockURLProtocol.lastRequest()
    XCTAssertNil(finalRequest?.value(forHTTPHeaderField: "X-Another-Header"))
  }

  // MARK: - Base URL Tests

  func testBaseURL() async throws {
    // Create a network manager with a base URL
    let baseURLManager = NetworkManager(
      baseURL: URL(string: "http://api.example.com")!
    )

    // Instead of making an actual request, just test the URL construction
    let request = try baseURLManager.createRequest(
      path: "/endpoint",
      method: "GET"
    )

    // Verify the request URL was constructed correctly
    XCTAssertEqual(request.url?.absoluteString, "http://api.example.com/endpoint")
    XCTAssertEqual(request.httpMethod, "GET")
  }
}

// MARK: - Test Models

struct TestUser: Codable, Equatable {
  let id: Int
  let name: String
  let email: String
}

extension NetworkError: Equatable {
  public static func == (lhs: NetworkError, rhs: NetworkError) -> Bool {
    switch (lhs, rhs) {
    case (.invalidURL(let lhsURL), .invalidURL(let rhsURL)):
      return lhsURL == rhsURL
    case (.invalidResponse, .invalidResponse):
      return true
    case (.requestFailed(let lhsError, let lhsURL), .requestFailed(let rhsError, let rhsURL)):
      return lhsError.localizedDescription == rhsError.localizedDescription
        && lhsURL?.absoluteString == rhsURL?.absoluteString
    case (.badRequest(let lhsData, let lhsURL), .badRequest(let rhsData, let rhsURL)):
      return lhsData == rhsData && lhsURL.absoluteString == rhsURL.absoluteString
    case (.unauthorized(let lhsURL), .unauthorized(let rhsURL)),
      (.forbidden(let lhsURL), .forbidden(let rhsURL)),
      (.notFound(let lhsURL), .notFound(let rhsURL)):
      return lhsURL.absoluteString == rhsURL.absoluteString
    case (.serverError(let lhsCode, let lhsURL), .serverError(let rhsCode, let rhsURL)):
      return lhsCode == rhsCode && lhsURL.absoluteString == rhsURL.absoluteString
    case (
      .httpError(let lhsCode, let lhsData, let lhsURL),
      .httpError(let rhsCode, let rhsData, let rhsURL)
    ):
      return lhsCode == rhsCode && lhsData == rhsData
        && lhsURL.absoluteString == rhsURL.absoluteString
    case (.decodingFailed(let lhsError), .decodingFailed(let rhsError)):
      return lhsError.localizedDescription == rhsError.localizedDescription
    default:
      return false
    }
  }
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
  private static let store = MockURLStore()

  // Reset all mock data
  static func reset() {
    store.reset()
  }

  static func setResponse(_ response: MockResponse, for pattern: String) {
    store.setResponse(response, for: pattern)
  }

  static func lastRequest() -> URLRequest? {
    store.lastRequest()
  }

  // URLProtocol methods
  override class func canInit(with request: URLRequest) -> Bool {
    return true
  }

  override class func canonicalRequest(for request: URLRequest) -> URLRequest {
    // Create a mutable copy of the request to ensure we capture the body
    var mutableRequest = request

    // If there's a body stream, read it and set it as httpBody
    if let bodyStream = request.httpBodyStream {
      let bufferSize = 1024
      var buffer = [UInt8](repeating: 0, count: bufferSize)
      var data = Data()

      bodyStream.open()

      while bodyStream.hasBytesAvailable {
        let bytesRead = bodyStream.read(&buffer, maxLength: bufferSize)
        if bytesRead > 0 {
          data.append(buffer, count: bytesRead)
        } else {
          break
        }
      }

      bodyStream.close()

      // Set the body data
      mutableRequest.httpBody = data
    }

    return mutableRequest
  }

  override func startLoading() {
    // Store a copy of the request for later inspection
    // Make sure we capture the body
    var requestCopy = request
    if let originalBody = request.httpBody {
      requestCopy.httpBody = originalBody
    }

    MockURLProtocol.store.appendRequest(requestCopy)

    guard let url = request.url?.absoluteString else {
      client?.urlProtocol(self, didFailWithError: NetworkError.invalidURL("missing URL"))
      return
    }

    // Find matching response
    var mockResponse: MockResponse?

    // First try exact match
    let responses = MockURLProtocol.store.responsesSnapshot()
    if let exactMatch = responses[url] {
      mockResponse = exactMatch
    } else {
      // Then try pattern matching
      for (urlPattern, response) in responses {
        if response.isRegex {
          // Regex pattern matching
          if let regex = try? NSRegularExpression(pattern: urlPattern),
            regex.firstMatch(in: url, range: NSRange(location: 0, length: url.count)) != nil
          {
            mockResponse = response
            break
          }
        } else if url.contains(urlPattern) {
          // Simple string containment matching
          mockResponse = response
          break
        }
      }
    }

    guard let response = mockResponse else {
      client?.urlProtocol(
        self, didFailWithError: NetworkError.notFound(request.url ?? URL(string: "unknown")!))
      return
    }

    // Create response
    let httpResponse = HTTPURLResponse(
      url: request.url!,
      statusCode: response.statusCode,
      httpVersion: "HTTP/1.1",
      headerFields: response.headers
    )!

    // Send response to client
    client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
    client?.urlProtocol(self, didLoad: response.data)
    client?.urlProtocolDidFinishLoading(self)
  }

  override func stopLoading() {
    // No-op
  }
}

// Mock response model
struct MockResponse {
  let statusCode: Int
  let data: Data
  var headers: [String: String] = [:]
  var isRegex: Bool = false
}

private final class MockURLStore: @unchecked Sendable {
  private let lock = NSLock()
  private var mockResponses: [String: MockResponse] = [:]
  private var requestHistory: [URLRequest] = []

  func reset() {
    lock.lock()
    defer { lock.unlock() }
    mockResponses = [:]
    requestHistory = []
  }

  func setResponse(_ response: MockResponse, for pattern: String) {
    lock.lock()
    defer { lock.unlock() }
    mockResponses[pattern] = response
  }

  func responsesSnapshot() -> [String: MockResponse] {
    lock.lock()
    defer { lock.unlock() }
    return mockResponses
  }

  func appendRequest(_ request: URLRequest) {
    lock.lock()
    defer { lock.unlock() }
    requestHistory.append(request)
  }

  func lastRequest() -> URLRequest? {
    lock.lock()
    defer { lock.unlock() }
    return requestHistory.last
  }
}
