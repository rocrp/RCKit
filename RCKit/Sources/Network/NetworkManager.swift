//
//  NetworkManager.swift
//
//
//  Created by RoCry on 2024/5/1.
//

import Foundation

extension String {
  fileprivate func removingLeadingSlash() -> String {
    hasPrefix("/") ? String(dropFirst()) : self
  }
}

/// HTTP header constants
private enum HTTPHeader {
  static let contentType = "Content-Type"
  static let contentTypeJSON = "application/json"
}

/// A manager for handling network requests
public final class NetworkManager: @unchecked Sendable {
  /// URLSession used for requests
  private let session: URLSession

  /// Base URL for all requests (optional)
  private let baseURL: URL?

  /// Default headers to include with all requests
  private let lock = NSLock()
  private var _defaultHeaders: [String: String]

  /// Thread-safe access to default headers
  private var defaultHeaders: [String: String] {
    get {
      lock.lock()
      defer { lock.unlock() }
      return _defaultHeaders
    }
    set {
      lock.lock()
      defer { lock.unlock() }
      _defaultHeaders = newValue
    }
  }

  /// JSON encoder with UTC ISO8601 date strategy
  private let jsonEncoder: JSONEncoder = JSONCoding.makeEncoder()

  /// JSON decoder with UTC ISO8601 date strategy
  private let jsonDecoder: JSONDecoder = JSONCoding.makeDecoder()

  /// Initialize a NetworkManager
  /// - Parameters:
  ///   - baseURL: Base URL for all requests (optional)
  ///   - defaultHeaders: Default headers to include with all requests
  ///   - configuration: URLSession configuration (defaults to .default)
  public init(
    baseURL: URL? = nil,
    defaultHeaders: [String: String] = [:],
    configuration: URLSessionConfiguration = .default
  ) {
    self.baseURL = baseURL
    self._defaultHeaders = defaultHeaders
    self.session = URLSession(configuration: configuration)
  }

  // MARK: - Request Methods

  /// Send a GET request
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - parameters: Query parameters
  ///   - headers: Additional headers
  /// - Returns: Data from the response
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func get(
    _ path: String,
    parameters: [String: String] = [:],
    headers: [String: String] = [:]
  ) async throws -> Data {
    let request = try createRequest(
      path: path,
      method: "GET",
      parameters: parameters,
      headers: headers)
    return try await performRequest(request)
  }

  /// Send a POST request
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - body: Request body data
  ///   - headers: Additional headers
  /// - Returns: Data from the response
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func post(
    _ path: String,
    body: Data?,
    headers: [String: String] = [:]
  ) async throws -> Data {
    var request = try createRequest(
      path: path,
      method: "POST",
      headers: headers)
    // Explicitly set the body
    request.httpBody = body
    return try await performRequest(request)
  }

  /// Send a POST request with an Encodable object
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - object: Encodable object to send in the request body
  ///   - headers: Additional headers
  /// - Returns: Data from the response
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func post<T: Encodable>(
    _ path: String,
    object: T,
    headers: [String: String] = [:]
  ) async throws -> Data {
    var requestHeaders = headers
    requestHeaders[HTTPHeader.contentType] = HTTPHeader.contentTypeJSON

    let jsonData = try jsonEncoder.encode(object)

    var request = try createRequest(
      path: path,
      method: "POST",
      headers: requestHeaders)
    // Explicitly set the body
    request.httpBody = jsonData
    return try await performRequest(request)
  }

  /// Send a PUT request
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - body: Request body data
  ///   - headers: Additional headers
  /// - Returns: Data from the response
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func put(
    _ path: String,
    body: Data?,
    headers: [String: String] = [:]
  ) async throws -> Data {
    var request = try createRequest(
      path: path,
      method: "PUT",
      headers: headers)
    // Explicitly set the body
    request.httpBody = body
    return try await performRequest(request)
  }

  /// Send a DELETE request
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - parameters: Query parameters
  ///   - headers: Additional headers
  /// - Returns: Data from the response
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func delete(
    _ path: String,
    parameters: [String: String] = [:],
    headers: [String: String] = [:]
  ) async throws -> Data {
    let request = try createRequest(
      path: path,
      method: "DELETE",
      parameters: parameters,
      headers: headers)
    return try await performRequest(request)
  }

  // MARK: - Response Parsing

  /// Send a request and decode the response as a specific type
  /// - Parameters:
  ///   - request: The request to send
  ///   - type: The type to decode the response as
  /// - Returns: The decoded object
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func decodeResponse<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T
  {
    let data = try await performRequest(request)
    do {
      return try jsonDecoder.decode(type, from: data)
    } catch {
      throw NetworkError.decodingFailed(error)
    }
  }

  /// Send a GET request and decode the response as a specific type
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - parameters: Query parameters
  ///   - headers: Additional headers
  ///   - type: The type to decode the response as
  /// - Returns: The decoded object
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func get<T: Decodable>(
    _ path: String,
    parameters: [String: String] = [:],
    headers: [String: String] = [:],
    as type: T.Type
  ) async throws -> T {
    let data = try await get(path, parameters: parameters, headers: headers)
    do {
      return try jsonDecoder.decode(type, from: data)
    } catch {
      throw NetworkError.decodingFailed(error)
    }
  }

  /// Send a POST request and decode the response as a specific type
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - body: Request body data
  ///   - headers: Additional headers
  ///   - type: The type to decode the response as
  /// - Returns: The decoded object
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  public func post<T: Decodable>(
    _ path: String,
    body: Data?,
    headers: [String: String] = [:],
    as type: T.Type
  ) async throws -> T {
    let data = try await post(path, body: body, headers: headers)
    do {
      return try jsonDecoder.decode(type, from: data)
    } catch {
      throw NetworkError.decodingFailed(error)
    }
  }

  // MARK: - Helper Methods

  /// Create a URL for a request
  /// - Parameters:
  ///   - path: The path to use
  ///   - queryItems: Query items to include
  /// - Returns: The constructed URL
  /// - Throws: NetworkError if the URL can't be constructed
  private func createURL(path: String, queryItems: [URLQueryItem]? = nil) throws -> URL {
    let baseURL = try resolveBaseURL(for: path)
    return try addQueryItems(queryItems, to: baseURL)
  }

  /// Resolve the base URL for a given path
  private func resolveBaseURL(for path: String) throws -> URL {
    if let base = baseURL {
      let adjustedPath = path.removingLeadingSlash()
      return base.appendingPathComponent(adjustedPath)
    }

    guard let url = URL(string: path) else {
      throw NetworkError.invalidURL(path)
    }
    return url
  }

  /// Add query items to a URL
  private func addQueryItems(_ items: [URLQueryItem]?, to url: URL) throws -> URL {
    guard let items = items, !items.isEmpty else { return url }

    guard var components = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
      throw NetworkError.invalidURL(url.absoluteString)
    }

    components.queryItems = (components.queryItems ?? []) + items

    guard let finalURL = components.url else {
      throw NetworkError.invalidURL(url.absoluteString)
    }

    return finalURL
  }

  /// Create a URLRequest
  /// - Parameters:
  ///   - path: Request path (appended to baseURL if provided)
  ///   - method: HTTP method to use
  ///   - parameters: Query parameters
  ///   - body: Request body data
  ///   - headers: Additional headers
  /// - Returns: The created URLRequest
  /// - Throws: NetworkError if the request can't be created
  public func createRequest(
    path: String,
    method: String,
    parameters: [String: String] = [:],
    body: Data? = nil,
    headers: [String: String] = [:]
  ) throws -> URLRequest {

    // Convert parameters to query items
    let queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }

    // Create URL
    let url = try createURL(path: path, queryItems: queryItems.isEmpty ? nil : queryItems)

    // Create request
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = body

    // Add headers (default headers + provided headers)
    for (key, value) in defaultHeaders {
      request.setValue(value, forHTTPHeaderField: key)
    }

    for (key, value) in headers {
      request.setValue(value, forHTTPHeaderField: key)
    }

    return request
  }

  /// Perform a network request
  /// - Parameter request: The request to perform
  /// - Returns: Data from the response
  /// - Throws: NetworkError
  @available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, visionOS 1.0, *)
  private func performRequest(_ request: URLRequest) async throws -> Data {
    let url = request.url
    do {
      let (data, response) = try await session.data(for: request)

      guard let httpResponse = response as? HTTPURLResponse else {
        throw NetworkError.invalidResponse
      }

      guard let requestURL = url else {
        throw NetworkError.invalidResponse
      }

      // Handle HTTP status codes
      switch httpResponse.statusCode {
      case 200...299:
        return data
      case 400:
        throw NetworkError.badRequest(data, requestURL)
      case 401:
        throw NetworkError.unauthorized(requestURL)
      case 403:
        throw NetworkError.forbidden(requestURL)
      case 404:
        throw NetworkError.notFound(requestURL)
      case 500...599:
        throw NetworkError.serverError(httpResponse.statusCode, requestURL)
      default:
        throw NetworkError.httpError(httpResponse.statusCode, data, requestURL)
      }
    } catch let error as NetworkError {
      throw error
    } catch {
      throw NetworkError.requestFailed(error, url)
    }
  }

  /// Set a default header for all requests
  /// - Parameters:
  ///   - value: Header value
  ///   - key: Header key
  public func setDefaultHeader(_ value: String, forKey key: String) {
    defaultHeaders[key] = value
  }

  /// Remove a default header
  /// - Parameter key: Header key to remove
  public func removeDefaultHeader(forKey key: String) {
    defaultHeaders.removeValue(forKey: key)
  }

  /// Clear all default headers
  public func clearDefaultHeaders() {
    defaultHeaders.removeAll()
  }
}

/// Errors that can occur during network operations
public enum NetworkError: Error, LocalizedError {
  case invalidURL(String)
  case invalidResponse
  case requestFailed(Error, URL?)
  case badRequest(Data, URL)
  case unauthorized(URL)
  case forbidden(URL)
  case notFound(URL)
  case serverError(Int, URL)
  case httpError(Int, Data, URL)
  case decodingFailed(Error)

  public var errorDescription: String? {
    switch self {
    case .invalidURL(let urlString):
      return "Invalid URL: \(urlString)"
    case .invalidResponse:
      return "Invalid response"
    case .requestFailed(let error, let url):
      if let url = url {
        return "Request failed for \(url.absoluteString): \(error.localizedDescription)"
      }
      return "Request failed: \(error.localizedDescription)"
    case .badRequest(_, let url):
      return "Bad request (400) for URL: \(url.absoluteString)"
    case .unauthorized(let url):
      return "Unauthorized (401) for URL: \(url.absoluteString)"
    case .forbidden(let url):
      return "Forbidden (403) for URL: \(url.absoluteString)"
    case .notFound(let url):
      return "Not found (404) for URL: \(url.absoluteString)"
    case .serverError(let code, let url):
      return "Server error (\(code)) for URL: \(url.absoluteString)"
    case .httpError(let code, _, let url):
      return "HTTP error (\(code)) for URL: \(url.absoluteString)"
    case .decodingFailed(let error):
      return "Failed to decode response: \(error.localizedDescription)"
    }
  }
}
