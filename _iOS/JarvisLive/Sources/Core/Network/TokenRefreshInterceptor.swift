// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/*
* Purpose: Network request interceptor for automatic JWT token refresh on 401 responses
* Issues & Complexity Summary: URLSession interceptor with concurrent request handling and token refresh
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: High (network interception, concurrent request management, async coordination)
  - Dependencies: 3 New (Foundation, URLSession, async/await patterns)
  - State Management Complexity: Very High (request queuing, token lifecycle, concurrent access)
  - Novelty/Uncertainty Factor: High (URLProtocol subclassing, thread safety with token refresh)
* AI Pre-Task Self-Assessment: 80%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: 87%
* Overall Result Score: 93%
* Key Variances/Learnings: URLProtocol requires careful thread safety and request lifecycle management
* Last Updated: 2025-06-27
*/

import Foundation

/// Network request interceptor that automatically handles JWT token refresh on 401 responses
class TokenRefreshInterceptor: URLProtocol {
    // MARK: - Static Properties

    private static let handledKey = "TokenRefreshInterceptor_Handled"
    private static var refreshInProgress = false
    private static var pendingRequests: [TokenRefreshPendingRequest] = []
    private static let refreshQueue = DispatchQueue(label: "token-refresh-queue", attributes: .concurrent)
    private static let refreshSemaphore = DispatchSemaphore(value: 1)

    // MARK: - URLProtocol Overrides

    override class func canInit(with request: URLRequest) -> Bool {
        // Only handle requests that haven't been handled before and contain authorization header
        guard URLProtocol.property(forKey: handledKey, in: request) == nil else {
            return false
        }

        // Only intercept requests with Authorization header
        guard request.value(forHTTPHeaderField: "Authorization") != nil else {
            return false
        }

        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // Mark request as handled to prevent infinite loops
        let mutableRequest = NSMutableURLRequest(url: request.url!, cachePolicy: request.cachePolicy, timeoutInterval: request.timeoutInterval)
        mutableRequest.httpMethod = request.httpMethod ?? "GET"
        mutableRequest.allHTTPHeaderFields = request.allHTTPHeaderFields
        mutableRequest.httpBody = request.httpBody
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRequest)

        Task {
            await handleRequest(mutableRequest as URLRequest)
        }
    }

    override func stopLoading() {
        // Clean up any pending operations
    }

    // MARK: - Request Handling

    private func handleRequest(_ request: URLRequest) async {
        do {
            // Perform the original request
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check if we received a 401 response
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 401 {
                // Handle 401 by attempting token refresh
                try await handleTokenRefresh(for: request, originalResponse: httpResponse, originalData: data)
            } else {
                // Forward successful response
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            }
        } catch {
            // Forward error
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    private func handleTokenRefresh(for request: URLRequest, originalResponse: HTTPURLResponse, originalData: Data) async throws {
        // Use async coordination to ensure only one refresh attempt at a time
        // Note: Semaphore wait() is not available in async context
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Self.refreshQueue.async {
                Self.refreshSemaphore.wait()
                continuation.resume()
            }
        }
        defer {
            Self.refreshQueue.async {
                Self.refreshSemaphore.signal()
            }
        }

        if Self.refreshInProgress {
            // Queue this request and wait for refresh to complete
            await queueRequest(request)
        } else {
            // Start refresh process
            Self.refreshInProgress = true

            do {
                // Attempt to refresh the token
                try await performTokenRefresh()

                // Retry the original request with new token
                try await retryRequestWithNewToken(request)

                // Process any queued requests
                await processQueuedRequests()
            } catch {
                // Refresh failed, forward original 401 response and log out user
                await handleRefreshFailure(originalResponse: originalResponse, originalData: originalData)

                // Process queued requests with failure
                await processQueuedRequestsWithFailure()
            }

            Self.refreshInProgress = false
        }
    }

    private func performTokenRefresh() async throws {
        // Get refresh token from keychain
        let keychainManager = KeychainManager(service: "com.ablankcanvas.jarvis-live")
        let refreshToken = try keychainManager.getCredential(forKey: "jwt_refresh_token")

        // Get backend URL
        let backendURL = getBackendURL()
        let refreshURL = URL(string: "\(backendURL)/auth/refresh")!

        var refreshRequest = URLRequest(url: refreshURL)
        refreshRequest.httpMethod = "POST"
        refreshRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        refreshRequest.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")

        // Mark refresh request as handled to prevent interception
        let mutableRefreshRequest = NSMutableURLRequest(url: refreshRequest.url!, cachePolicy: refreshRequest.cachePolicy, timeoutInterval: refreshRequest.timeoutInterval)
        mutableRefreshRequest.httpMethod = refreshRequest.httpMethod ?? "POST"
        mutableRefreshRequest.allHTTPHeaderFields = refreshRequest.allHTTPHeaderFields
        mutableRefreshRequest.httpBody = refreshRequest.httpBody
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRefreshRequest)
        refreshRequest = mutableRefreshRequest as URLRequest

        let (data, response) = try await URLSession.shared.data(for: refreshRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TokenRefreshError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 401 {
                throw TokenRefreshError.refreshTokenExpired
            }
            throw TokenRefreshError.refreshFailed("HTTP \(httpResponse.statusCode)")
        }

        // Parse new tokens
        let decoder = JSONDecoder()
        let authResponse = try decoder.decode(AuthenticationResponse.self, from: data)

        // Store new tokens in keychain
        try keychainManager.storeCredential(authResponse.accessToken, forKey: "jwt_access_token")
        if let newRefreshToken = authResponse.refreshToken {
            try keychainManager.storeCredential(newRefreshToken, forKey: "jwt_refresh_token")
        }
    }

    private func retryRequestWithNewToken(_ request: URLRequest) async throws {
        // Get new access token
        let keychainManager = KeychainManager(service: "com.ablankcanvas.jarvis-live")
        let newAccessToken = try keychainManager.getCredential(forKey: "jwt_access_token")

        // Create new request with updated token
        var retryRequest = request
        retryRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")

        // Mark as handled to prevent re-interception
        let mutableRetryRequest = NSMutableURLRequest(url: retryRequest.url!, cachePolicy: retryRequest.cachePolicy, timeoutInterval: retryRequest.timeoutInterval)
        mutableRetryRequest.httpMethod = retryRequest.httpMethod ?? "GET"
        mutableRetryRequest.allHTTPHeaderFields = retryRequest.allHTTPHeaderFields
        mutableRetryRequest.httpBody = retryRequest.httpBody
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRetryRequest)
        retryRequest = mutableRetryRequest as URLRequest

        // Perform retry
        let (data, response) = try await URLSession.shared.data(for: retryRequest)

        // Forward response
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func queueRequest(_ request: URLRequest) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            Self.refreshQueue.async(flags: .barrier) {
                let tokenRequest = TokenRefreshPendingRequest(
                    request: request,
                    client: self.client,
                    continuation: continuation
                )
                Self.pendingRequests.append(tokenRequest)
            }
        }
    }

    private func processQueuedRequests() async {
        let requests = await withCheckedContinuation { (continuation: CheckedContinuation<[TokenRefreshPendingRequest], Never>) in
            Self.refreshQueue.async(flags: .barrier) {
                let pendingRequests = Self.pendingRequests
                Self.pendingRequests.removeAll()
                continuation.resume(returning: pendingRequests)
            }
        }

        // Process each queued request
        for tokenRequest in requests {
            do {
                try await retryQueuedRequest(tokenRequest)
            } catch {
                // Forward error for this specific request
                tokenRequest.client?.urlProtocol(self, didFailWithError: error)
            }

            // Resume the continuation
            tokenRequest.continuation.resume()
        }
    }

    private func processQueuedRequestsWithFailure() async {
        let requests = await withCheckedContinuation { (continuation: CheckedContinuation<[TokenRefreshPendingRequest], Never>) in
            Self.refreshQueue.async(flags: .barrier) {
                let pendingRequests = Self.pendingRequests
                Self.pendingRequests.removeAll()
                continuation.resume(returning: pendingRequests)
            }
        }

        // Fail all queued requests
        for tokenRequest in requests {
            let error = TokenRefreshError.refreshTokenExpired
            tokenRequest.client?.urlProtocol(self, didFailWithError: error)
            tokenRequest.continuation.resume()
        }
    }

    private func retryQueuedRequest(_ tokenRequest: TokenRefreshPendingRequest) async throws {
        // Get new access token
        let keychainManager = KeychainManager(service: "com.ablankcanvas.jarvis-live")
        let newAccessToken = try keychainManager.getCredential(forKey: "jwt_access_token")

        // Create new request with updated token
        var retryRequest = tokenRequest.request
        retryRequest.setValue("Bearer \(newAccessToken)", forHTTPHeaderField: "Authorization")

        // Mark as handled
        let mutableRetryRequest = NSMutableURLRequest(url: retryRequest.url!, cachePolicy: retryRequest.cachePolicy, timeoutInterval: retryRequest.timeoutInterval)
        mutableRetryRequest.httpMethod = retryRequest.httpMethod ?? "GET"
        mutableRetryRequest.allHTTPHeaderFields = retryRequest.allHTTPHeaderFields
        mutableRetryRequest.httpBody = retryRequest.httpBody
        URLProtocol.setProperty(true, forKey: Self.handledKey, in: mutableRetryRequest)
        retryRequest = mutableRetryRequest as URLRequest

        // Perform retry
        let (data, response) = try await URLSession.shared.data(for: retryRequest)

        // Forward response to original client
        tokenRequest.client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        tokenRequest.client?.urlProtocol(self, didLoad: data)
        tokenRequest.client?.urlProtocolDidFinishLoading(self)
    }

    private func handleRefreshFailure(originalResponse: HTTPURLResponse, originalData: Data) async {
        // Clear tokens from keychain
        let keychainManager = KeychainManager(service: "com.ablankcanvas.jarvis-live")
        try? keychainManager.deleteCredential(forKey: "jwt_access_token")
        try? keychainManager.deleteCredential(forKey: "jwt_refresh_token")

        // Notify authentication manager to log out user
        await MainActor.run {
            NotificationCenter.default.post(
                name: .tokenRefreshFailed,
                object: nil,
                userInfo: ["error": TokenRefreshError.refreshTokenExpired]
            )
        }

        // Forward original 401 response
        client?.urlProtocol(self, didReceive: originalResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: originalData)
        client?.urlProtocolDidFinishLoading(self)
    }

    private func getBackendURL() -> String {
        if let urlFromArgs = ProcessInfo.processInfo.environment["PythonBackendURL"] {
            return urlFromArgs
        }

        // Check launch arguments for testing
        let args = ProcessInfo.processInfo.arguments
        if let urlIndex = args.firstIndex(of: "-PythonBackendURL"),
           urlIndex + 1 < args.count {
            return args[urlIndex + 1]
        }

        // Default to local development server
        return "http://localhost:8000"
    }
}

// MARK: - Supporting Types

struct TokenRefreshPendingRequest {
    let request: URLRequest
    let client: URLProtocolClient?
    let continuation: CheckedContinuation<Void, Never>
}

enum TokenRefreshError: Error, LocalizedError {
    case invalidResponse
    case refreshTokenExpired
    case refreshFailed(String)
    case keychainError

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from token refresh endpoint"
        case .refreshTokenExpired:
            return "Refresh token has expired"
        case .refreshFailed(let message):
            return "Token refresh failed: \(message)"
        case .keychainError:
            return "Failed to access keychain for token storage"
        }
    }
}

// MARK: - Notification Extensions

extension Notification.Name {
    static let tokenRefreshFailed = Notification.Name("TokenRefreshFailed")
}

// MARK: - URLSessionConfiguration Extension

extension URLSessionConfiguration {
    /// Configure URLSession to use token refresh interceptor
    static func withTokenRefresh() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [TokenRefreshInterceptor.self]
        return configuration
    }
}
