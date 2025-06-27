/*
* Purpose: Comprehensive authentication flow tests for biometric integration and token refresh
* Issues & Complexity Summary: Unit/integration tests for advanced authentication features
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~600
  - Core Algorithm Complexity: High (mocking biometric authentication, token refresh scenarios)
  - Dependencies: 4 New (XCTest, LocalAuthentication mocking, URLProtocol mocking, async testing)
  - State Management Complexity: High (authentication states, token lifecycle, error handling)
  - Novelty/Uncertainty Factor: Medium (biometric testing patterns, network interception testing)
* AI Pre-Task Self-Assessment: 85%
* Problem Estimate: 80%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-27
*/

import XCTest
import LocalAuthentication
@testable import JarvisLive_Sandbox

final class AuthenticationFlowTests: XCTestCase {
    var authManager: AuthenticationStateManager!
    var mockLAContext: MockLAContext!
    var mockAPIClient: MockAPIClient!
    var mockKeychainManager: MockKeychainManager!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Create mock dependencies
        mockLAContext = MockLAContext()
        mockAPIClient = MockAPIClient()
        mockKeychainManager = MockKeychainManager()

        // Initialize authentication manager with mocks
        authManager = AuthenticationStateManager(
            apiAuthManager: nil,
            keychainManager: mockKeychainManager,
            userDefaults: UserDefaults(suiteName: "test")!
        )
    }

    override func tearDownWithError() throws {
        authManager = nil
        mockLAContext = nil
        mockAPIClient = nil
        mockKeychainManager = nil

        // Clean up test user defaults
        if let testDefaults = UserDefaults(suiteName: "test") {
            testDefaults.removePersistentDomain(forName: "test")
        }
    }

    // MARK: - Biometric Authentication Tests

    func test_biometricLogin_succeeds_and_refreshesToken() async throws {
        // Setup: Store refresh token in mock keychain
        mockKeychainManager.storedSecrets["jwt_refresh_token"] = "valid_refresh_token"

        // Setup: Mock successful biometric authentication
        mockLAContext.mockResult = .success(true)

        // Setup: Mock successful token refresh
        mockAPIClient.mockResponses["/auth/refresh"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode(AuthenticationResponse(
                accessToken: "new_access_token",
                refreshToken: "new_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600,
                user: nil
            ))
        )

        // Execute: Perform biometric authentication
        try await authManager.performBiometricAuthentication()

        // Verify: Authentication state is authenticated
        XCTAssertTrue(authManager.isAuthenticated, "Should be authenticated after successful biometric login")
        XCTAssertEqual(authManager.currentFlow, .authenticated, "Flow should be in authenticated state")

        // Verify: New access token is stored
        XCTAssertEqual(mockKeychainManager.storedSecrets["jwt_access_token"], "new_access_token", "New access token should be stored")

        // Verify: New refresh token is stored
        XCTAssertEqual(mockKeychainManager.storedSecrets["jwt_refresh_token"], "new_refresh_token", "New refresh token should be stored")
    }

    func test_biometricLogin_fails_with_authenticationFailed() async throws {
        // Setup: Mock failed biometric authentication
        mockLAContext.mockResult = .failure(LAError(.authenticationFailed))

        // Execute and verify: Biometric authentication throws error
        do {
            try await authManager.performBiometricAuthentication()
            XCTFail("Should have thrown biometric authentication error")
        } catch let error as AuthenticationFlowError {
            XCTAssertEqual(error, .biometricAuthenticationFailed, "Should throw biometric authentication failed error")
        }

        // Verify: Authentication state remains unauthenticated
        XCTAssertFalse(authManager.isAuthenticated, "Should not be authenticated after failed biometric login")
        XCTAssertTrue(authManager.isInErrorState, "Should be in error state")
    }

    func test_biometricLogin_fails_with_userCancel() async throws {
        // Setup: Mock user cancelled biometric authentication
        mockLAContext.mockResult = .failure(LAError(.userCancel))

        // Execute and verify: Biometric authentication throws error
        do {
            try await authManager.performBiometricAuthentication()
            XCTFail("Should have thrown biometric authentication error")
        } catch let error as AuthenticationFlowError {
            XCTAssertEqual(error, .biometricAuthenticationFailed, "Should throw biometric authentication failed error")
        }

        // Verify: Authentication state remains unauthenticated
        XCTAssertFalse(authManager.isAuthenticated, "Should not be authenticated after cancelled biometric login")
        XCTAssertTrue(authManager.canRetry, "Should allow retry after user cancellation")
    }

    func test_biometricLogin_fails_with_biometryNotAvailable() async throws {
        // Setup: Mock biometry not available
        mockLAContext.mockResult = .failure(LAError(.biometryNotAvailable))

        // Execute and verify: Biometric authentication throws error
        do {
            try await authManager.performBiometricAuthentication()
            XCTFail("Should have thrown biometric not available error")
        } catch let error as AuthenticationFlowError {
            XCTAssertEqual(error, .biometricNotAvailable, "Should throw biometric not available error")
        }

        // Verify: Cannot retry biometric authentication
        XCTAssertFalse(authManager.canRetry, "Should not allow retry when biometry is not available")
    }

    func test_biometricLogin_fails_with_passcodeNotSet() async throws {
        // Setup: Mock passcode not set
        mockLAContext.mockResult = .failure(LAError(.passcodeNotSet))

        // Execute and verify: Biometric authentication throws error
        do {
            try await authManager.performBiometricAuthentication()
            XCTFail("Should have thrown biometric authentication error")
        } catch let error as AuthenticationFlowError {
            XCTAssertEqual(error, .biometricAuthenticationFailed, "Should throw biometric authentication failed error")
        }

        // Verify: Should provide guidance to set up passcode
        XCTAssertTrue(authManager.canRetry, "Should allow retry after setting up passcode")
    }

    // MARK: - Token Refresh Tests

    func test_apiCall_withExpiredToken_triggersRefresh_andSucceeds() async throws {
        // Setup: Store expired access token and valid refresh token
        mockKeychainManager.storedSecrets["jwt_access_token"] = "expired_access_token"
        mockKeychainManager.storedSecrets["jwt_refresh_token"] = "valid_refresh_token"

        // Setup: Mock 401 response for initial API call
        mockAPIClient.mockResponses["/voice/classify"] = MockResponse(
            statusCode: 401,
            data: Data()
        )

        // Setup: Mock successful token refresh
        mockAPIClient.mockResponses["/auth/refresh"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode(AuthenticationResponse(
                accessToken: "new_access_token",
                refreshToken: "new_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600,
                user: nil
            ))
        )

        // Setup: Mock successful retry of original API call
        mockAPIClient.retryResponses["/voice/classify"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode([
                "category": "document_generation",
                "intent": "Create document",
                "confidence": 0.85,
                "parameters": [:],
                "suggestions": [],
                "raw_text": "Create a document",
                "normalized_text": "create document",
                "confidence_level": "high",
                "context_used": false,
                "preprocessing_time": 0.01,
                "classification_time": 0.02,
                "requires_confirmation": false,
            ])
        )

        // Create voice classification manager with mock dependencies
        let voiceManager = VoiceClassificationManager(
            configuration: .default,
            session: mockAPIClient,
            keychainManager: mockKeychainManager,
            authenticationManager: nil
        )

        // Execute: Attempt voice classification (which should trigger token refresh)
        let result = try await voiceManager.classifyVoiceCommand("Create a document")

        // Verify: Classification succeeded after token refresh
        XCTAssertEqual(result.category, "document_generation", "Classification should succeed after token refresh")
        XCTAssertEqual(result.intent, "Create document", "Intent should be correctly classified")

        // Verify: New tokens are stored
        XCTAssertEqual(mockKeychainManager.storedSecrets["jwt_access_token"], "new_access_token", "New access token should be stored")
        XCTAssertEqual(mockKeychainManager.storedSecrets["jwt_refresh_token"], "new_refresh_token", "New refresh token should be stored")

        // Verify: Refresh endpoint was called
        XCTAssertTrue(mockAPIClient.calledEndpoints.contains("/auth/refresh"), "Refresh endpoint should have been called")
    }

    func test_tokenRefresh_fails_and_logsUserOut() async throws {
        // Setup: Store expired tokens
        mockKeychainManager.storedSecrets["jwt_access_token"] = "expired_access_token"
        mockKeychainManager.storedSecrets["jwt_refresh_token"] = "expired_refresh_token"

        // Setup: Mock 401 response for initial API call
        mockAPIClient.mockResponses["/voice/classify"] = MockResponse(
            statusCode: 401,
            data: Data()
        )

        // Setup: Mock failed token refresh (refresh token also expired)
        mockAPIClient.mockResponses["/auth/refresh"] = MockResponse(
            statusCode: 401,
            data: Data()
        )

        // Create voice classification manager with mock dependencies
        let voiceManager = VoiceClassificationManager(
            configuration: .default,
            session: mockAPIClient,
            keychainManager: mockKeychainManager,
            authenticationManager: nil
        )

        // Execute and verify: Voice classification fails with token expired error
        do {
            _ = try await voiceManager.classifyVoiceCommand("Create a document")
            XCTFail("Should have thrown token expired error")
        } catch let error as VoiceClassificationError {
            XCTAssertEqual(error, .tokenExpired, "Should throw token expired error when refresh fails")
        }

        // Verify: Tokens are cleared from keychain
        XCTAssertNil(mockKeychainManager.storedSecrets["jwt_access_token"], "Access token should be cleared")
        XCTAssertNil(mockKeychainManager.storedSecrets["jwt_refresh_token"], "Refresh token should be cleared")

        // Verify: User is logged out
        XCTAssertFalse(authManager.isAuthenticated, "User should be logged out after failed refresh")
    }

    func test_concurrentTokenRefresh_onlyMakesOneRefreshCall() async throws {
        // Setup: Store expired access token and valid refresh token
        mockKeychainManager.storedSecrets["jwt_access_token"] = "expired_access_token"
        mockKeychainManager.storedSecrets["jwt_refresh_token"] = "valid_refresh_token"

        // Setup: Mock 401 responses for multiple API calls
        mockAPIClient.mockResponses["/voice/classify"] = MockResponse(statusCode: 401, data: Data())
        mockAPIClient.mockResponses["/context/user/session/summary"] = MockResponse(statusCode: 401, data: Data())
        mockAPIClient.mockResponses["/context/user/session/suggestions"] = MockResponse(statusCode: 401, data: Data())

        // Setup: Mock successful token refresh with delay to simulate network latency
        mockAPIClient.mockResponses["/auth/refresh"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode(AuthenticationResponse(
                accessToken: "new_access_token",
                refreshToken: "new_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600,
                user: nil
            )),
            delay: 0.5
        )

        // Create voice classification manager
        let voiceManager = VoiceClassificationManager(
            configuration: .default,
            session: mockAPIClient,
            keychainManager: mockKeychainManager,
            authenticationManager: nil
        )

        // Execute: Make multiple concurrent API calls that will all receive 401
        async let call1 = voiceManager.classifyVoiceCommand("Create a document")
        async let call2 = voiceManager.getContextualSuggestions()
        async let call3 = voiceManager.getContextSummary()

        // Wait for all calls to complete (they should all fail initially)
        do {
            _ = try await call1
            _ = try await call2
            _ = try await call3
        } catch {
            // Expected to fail due to 401/token refresh scenarios
        }

        // Verify: Only one refresh call was made despite multiple 401 responses
        let refreshCallCount = mockAPIClient.callCounts["/auth/refresh"] ?? 0
        XCTAssertEqual(refreshCallCount, 1, "Should only make one refresh call despite multiple concurrent 401s")
    }

    // MARK: - Integration Tests

    func test_fullAuthenticationFlow_biometricToClassification() async throws {
        // Setup: Configure device with biometric support
        mockLAContext.mockBiometryType = .faceID
        mockLAContext.mockCanEvaluatePolicy = true
        mockLAContext.mockResult = .success(true)

        // Setup: Store valid refresh token
        mockKeychainManager.storedSecrets["jwt_refresh_token"] = "valid_refresh_token"

        // Setup: Mock successful token refresh
        mockAPIClient.mockResponses["/auth/refresh"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode(AuthenticationResponse(
                accessToken: "fresh_access_token",
                refreshToken: "fresh_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600,
                user: nil
            ))
        )

        // Setup: Mock successful voice classification
        mockAPIClient.mockResponses["/voice/classify"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode([
                "category": "email_management",
                "intent": "Send email",
                "confidence": 0.92,
                "parameters": ["recipient": "user@example.com"],
                "suggestions": [],
                "raw_text": "Send email to user",
                "normalized_text": "send email user",
                "confidence_level": "high",
                "context_used": true,
                "preprocessing_time": 0.01,
                "classification_time": 0.02,
                "requires_confirmation": false,
            ])
        )

        // Execute: Perform biometric authentication
        try await authManager.performBiometricAuthentication()

        // Verify: Authentication succeeded
        XCTAssertTrue(authManager.isAuthenticated, "Should be authenticated after biometric login")

        // Execute: Perform voice classification
        let voiceManager = VoiceClassificationManager(
            configuration: .default,
            session: mockAPIClient,
            keychainManager: mockKeychainManager,
            authenticationManager: nil
        )

        let result = try await voiceManager.classifyVoiceCommand("Send email to user")

        // Verify: Classification succeeded with fresh token
        XCTAssertEqual(result.category, "email_management", "Classification should succeed with fresh token")
        XCTAssertEqual(result.confidence, 0.92, "Confidence should match response")
        XCTAssertTrue(result.contextUsed, "Context should be used")

        // Verify: Fresh tokens are stored
        XCTAssertEqual(mockKeychainManager.storedSecrets["jwt_access_token"], "fresh_access_token", "Fresh access token should be stored")
    }

    func test_biometricUnavailable_fallsBackToManualAuth() async throws {
        // Setup: Configure device without biometric support
        mockLAContext.mockBiometryType = .none
        mockLAContext.mockCanEvaluatePolicy = false
        mockLAContext.mockResult = .failure(LAError(.biometryNotAvailable))

        // Execute: Attempt biometric authentication
        do {
            try await authManager.performBiometricAuthentication()
            XCTFail("Should have thrown biometric not available error")
        } catch let error as AuthenticationFlowError {
            XCTAssertEqual(error, .biometricNotAvailable, "Should throw biometric not available error")
        }

        // Verify: Should fallback to manual authentication
        XCTAssertFalse(authManager.canRetry, "Should not allow biometric retry when not available")
        XCTAssertEqual(authManager.currentFlow, .error(.biometricNotAvailable), "Should be in error state")

        // Setup: Mock successful manual login
        mockAPIClient.mockResponses["/auth/login"] = MockResponse(
            statusCode: 200,
            data: try JSONEncoder().encode(AuthenticationResponse(
                accessToken: "manual_access_token",
                refreshToken: "manual_refresh_token",
                tokenType: "bearer",
                expiresIn: 3600,
                user: UserInfo(
                    id: "user123",
                    username: "testuser",
                    email: "test@example.com",
                    fullName: "Test User",
                    permissions: ["read", "write"]
                )
            ))
        )

        // Execute: Manual login as fallback
        try await authManager.login(username: "testuser", password: "password123")

        // Verify: Manual authentication succeeded
        XCTAssertTrue(authManager.isAuthenticated, "Should be authenticated after manual login")
        XCTAssertEqual(authManager.currentFlow, .authenticated, "Should be in authenticated state")
    }
}

// MARK: - Mock Classes

class MockLAContext {
    var mockResult: Result<Bool, Error> = .success(true)
    var mockBiometryType: LABiometryType = .faceID
    var mockCanEvaluatePolicy: Bool = true

    func evaluatePolicy(_ policy: LAPolicy, localizedReason: String) async throws -> Bool {
        switch mockResult {
        case .success(let success):
            return success
        case .failure(let error):
            throw error
        }
    }

    func canEvaluatePolicy(_ policy: LAPolicy, error: inout NSError?) -> Bool {
        return mockCanEvaluatePolicy
    }

    var biometryType: LABiometryType {
        return mockBiometryType
    }
}

class MockAPIClient: NetworkSession {
    var mockResponses: [String: MockResponse] = [:]
    var retryResponses: [String: MockResponse] = [:]
    var calledEndpoints: Set<String> = []
    var callCounts: [String: Int] = [:]

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        guard let url = request.url else {
            throw URLError(.badURL)
        }

        let endpoint = url.path
        calledEndpoints.insert(endpoint)
        callCounts[endpoint] = (callCounts[endpoint] ?? 0) + 1

        // Check if this is a retry call
        if callCounts[endpoint]! > 1, let retryResponse = retryResponses[endpoint] {
            if let delay = retryResponse.delay {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }

            let httpResponse = HTTPURLResponse(
                url: url,
                statusCode: retryResponse.statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: nil
            )!

            return (retryResponse.data, httpResponse)
        }

        // Use initial response
        guard let mockResponse = mockResponses[endpoint] else {
            throw URLError(.resourceUnavailable)
        }

        if let delay = mockResponse.delay {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: mockResponse.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!

        return (mockResponse.data, httpResponse)
    }
}

struct MockResponse {
    let statusCode: Int
    let data: Data
    let delay: TimeInterval?

    init(statusCode: Int, data: Data, delay: TimeInterval? = nil) {
        self.statusCode = statusCode
        self.data = data
        self.delay = delay
    }
}

class MockKeychainManager: KeychainManager {
    var storedSecrets: [String: String] = [:]

    override func storeSecret(_ secret: String, for key: String) async throws {
        storedSecrets[key] = secret
    }

    override func retrieveSecret(for key: String) async throws -> String {
        guard let secret = storedSecrets[key] else {
            throw KeychainManagerError.itemNotFound
        }
        return secret
    }

    override func deleteSecret(for key: String) async throws {
        storedSecrets.removeValue(forKey: key)
    }
}
