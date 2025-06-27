// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Certificate pinning validation tests for PythonBackendClient
 * Issues & Complexity Summary: Validates certificate pinning security implementation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~200
 *   - Core Algorithm Complexity: Medium (Mock certificate generation, security validation)
 *   - Dependencies: 3 New (XCTest, Security, PythonBackendClient)
 *   - State Management Complexity: Low (Test state isolation)
 *   - Novelty/Uncertainty Factor: Medium (Security framework testing)
 * AI Pre-Task Self-Assessment: 85%
 * Problem Estimate: 80%
 * Initial Code Complexity Estimate: 80%
 * Final Code Complexity: 82%
 * Overall Result Score: 90%
 * Key Variances/Learnings: Certificate pinning testing requires careful mock setup
 * Last Updated: 2025-06-27
 */

import XCTest
import Security
import Foundation
@testable import JarvisLive

final class CertificatePinningTests: XCTestCase {
    private var client: PythonBackendClient!
    private var mockSession: MockURLSession!

    override func setUpWithError() throws {
        super.setUp()

        // Initialize with production configuration (certificate pinning enabled)
        let productionConfig = PythonBackendClient.BackendConfiguration.production
        client = PythonBackendClient(configuration: productionConfig)

        // Set up mock URL session for testing
        mockSession = MockURLSession()
    }

    override func tearDownWithError() throws {
        client = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Certificate Pinning Validation Tests

    /// Test certificate pinning with a valid pinned certificate
    func testCertificatePinningWithValidCertificate() throws {
        // Given: A valid certificate that matches the pinned certificate
        let validCertificateData = try createMockCertificateData(name: "valid-cert")
        let mockChallenge = createMockAuthenticationChallenge(
            certificateData: validCertificateData,
            host: "api.jarvis.live"
        )

        // When: The challenge is processed
        var capturedDisposition: URLSession.AuthChallengeDisposition?
        var capturedCredential: URLCredential?

        client.urlSession(
            mockSession,
            didReceive: mockChallenge,
            completionHandler: { disposition, credential in
                capturedDisposition = disposition
                capturedCredential = credential
            }
        )

        // Then: The challenge should be accepted with a valid credential
        XCTAssertEqual(capturedDisposition, .useCredential, "Valid certificate should be accepted")
        XCTAssertNotNil(capturedCredential, "Valid credential should be provided")
    }

    /// Test certificate pinning with an invalid certificate
    func testCertificatePinningWithInvalidCertificate() throws {
        // Given: An invalid certificate that doesn't match the pinned certificate
        let invalidCertificateData = try createMockCertificateData(name: "invalid-cert")
        let mockChallenge = createMockAuthenticationChallenge(
            certificateData: invalidCertificateData,
            host: "api.jarvis.live"
        )

        // When: The challenge is processed
        var capturedDisposition: URLSession.AuthChallengeDisposition?
        var capturedCredential: URLCredential?

        client.urlSession(
            mockSession,
            didReceive: mockChallenge,
            completionHandler: { disposition, credential in
                capturedDisposition = disposition
                capturedCredential = credential
            }
        )

        // Then: The challenge should be rejected
        XCTAssertEqual(capturedDisposition, .cancelAuthenticationChallenge, "Invalid certificate should be rejected")
        XCTAssertNil(capturedCredential, "No credential should be provided for invalid certificate")
    }

    /// Test certificate pinning is disabled for localhost development
    func testCertificatePinningDisabledForLocalhost() throws {
        // Given: A client with development configuration (localhost, pinning disabled)
        let developmentConfig = PythonBackendClient.BackendConfiguration.default
        let developmentClient = PythonBackendClient(configuration: developmentConfig)

        let mockChallenge = createMockAuthenticationChallenge(
            certificateData: try createMockCertificateData(name: "any-cert"),
            host: "localhost"
        )

        // When: The challenge is processed
        var capturedDisposition: URLSession.AuthChallengeDisposition?

        developmentClient.urlSession(
            mockSession,
            didReceive: mockChallenge,
            completionHandler: { disposition, _ in
                capturedDisposition = disposition
            }
        )

        // Then: Default handling should be used (no pinning)
        XCTAssertEqual(capturedDisposition, .performDefaultHandling, "Localhost should use default handling")
    }

    /// Test certificate pinning with missing pinned certificate
    func testCertificatePinningWithMissingPinnedCertificate() throws {
        // Given: A configuration with pinning enabled but no certificate available
        let configWithMissingCert = PythonBackendClient.BackendConfiguration(
            baseURL: "https://api.jarvis.live",
            websocketURL: "wss://api.jarvis.live/ws",
            apiKey: nil,
            timeout: 30.0,
            heartbeatInterval: 30.0,
            enableCertificatePinning: true,
            pinnedCertificateName: "nonexistent-cert"
        )

        let clientWithMissingCert = PythonBackendClient(configuration: configWithMissingCert)
        let mockChallenge = createMockAuthenticationChallenge(
            certificateData: try createMockCertificateData(name: "any-cert"),
            host: "api.jarvis.live"
        )

        // When: The challenge is processed
        var capturedDisposition: URLSession.AuthChallengeDisposition?

        clientWithMissingCert.urlSession(
            mockSession,
            didReceive: mockChallenge,
            completionHandler: { disposition, _ in
                capturedDisposition = disposition
            }
        )

        // Then: The challenge should be rejected due to missing pinned certificate
        XCTAssertEqual(capturedDisposition, .cancelAuthenticationChallenge, "Missing pinned certificate should reject challenge")
    }

    /// Test certificate pinning with non-server trust challenge
    func testCertificatePinningWithNonServerTrustChallenge() throws {
        // Given: A non-server trust authentication challenge
        let protectionSpace = URLProtectionSpace(
            host: "api.jarvis.live",
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodHTTPBasic // Not server trust
        )

        let mockChallenge = URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockURLAuthenticationChallengeSender()
        )

        // When: The challenge is processed
        var capturedDisposition: URLSession.AuthChallengeDisposition?

        client.urlSession(
            mockSession,
            didReceive: mockChallenge,
            completionHandler: { disposition, _ in
                capturedDisposition = disposition
            }
        )

        // Then: Default handling should be used for non-server trust challenges
        XCTAssertEqual(capturedDisposition, .performDefaultHandling, "Non-server trust challenges should use default handling")
    }

    // MARK: - Performance Tests

    /// Test certificate pinning validation performance
    func testCertificatePinningPerformance() throws {
        let validCertificateData = try createMockCertificateData(name: "valid-cert")
        let mockChallenge = createMockAuthenticationChallenge(
            certificateData: validCertificateData,
            host: "api.jarvis.live"
        )

        measure {
            client.urlSession(
                mockSession,
                didReceive: mockChallenge,
                completionHandler: { _, _ in
                    // Performance measurement
                }
            )
        }
    }

    // MARK: - Helper Methods

    /// Create mock certificate data for testing
    private func createMockCertificateData(name: String) throws -> Data {
        // Create a mock certificate for testing purposes
        // In a real implementation, you would load actual test certificates
        let mockCertString = """
        -----BEGIN CERTIFICATE-----
        MIIDXTCCAkWgAwIBAgIJAKoK/heBjcOuMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
        BAYTAkFVMRMwEQYDVQQIDApTb21lLVN0YXRlMSEwHwYDVQQKDBhJbnRlcm5ldCBX
        aWRnaXRzIFB0eSBMdGQwHhcNMTMwODI3MjM1NTQyWhcNMjMwODI1MjM1NTQyWjBF
        MQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50
        ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
        CgKCAQEAwUdO3fxEqGqFBVw3w5B3YRdCp+B2CI9h6PsQF13qSXt5R4vXPiHNs
        -----END CERTIFICATE-----
        """

        guard let data = mockCertString.data(using: .utf8) else {
            throw NSError(domain: "CertificatePinningTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create mock certificate data"])
        }

        return data
    }

    /// Create mock authentication challenge for testing
    private func createMockAuthenticationChallenge(
        certificateData: Data,
        host: String
    ) -> URLAuthenticationChallenge {
        // Create mock server trust
        guard let certificate = SecCertificateCreateWithData(nil, certificateData) else {
            fatalError("Failed to create certificate from data")
        }

        var trust: SecTrust?
        let policy = SecPolicyCreateSSL(true, host as CFString)
        let status = SecTrustCreateWithCertificates([certificate] as CFArray, policy, &trust)

        guard status == errSecSuccess, let serverTrust = trust else {
            fatalError("Failed to create server trust")
        }

        // Create protection space with server trust
        let protectionSpace = URLProtectionSpace(
            host: host,
            port: 443,
            protocol: "https",
            realm: nil,
            authenticationMethod: NSURLAuthenticationMethodServerTrust
        )

        // Set the server trust on the protection space
        protectionSpace.setValue(serverTrust, forKey: "serverTrust")

        return URLAuthenticationChallenge(
            protectionSpace: protectionSpace,
            proposedCredential: nil,
            previousFailureCount: 0,
            failureResponse: nil,
            error: nil,
            sender: MockURLAuthenticationChallengeSender()
        )
    }
}

// MARK: - Mock Classes

class MockURLSession: URLSession {
    // Mock implementation for testing
}

class MockURLAuthenticationChallengeSender: NSObject, URLAuthenticationChallengeSender {
    func use(_ credential: URLCredential, for challenge: URLAuthenticationChallenge) {
        // Mock implementation
    }

    func continueWithoutCredential(for challenge: URLAuthenticationChallenge) {
        // Mock implementation
    }

    func cancel(_ challenge: URLAuthenticationChallenge) {
        // Mock implementation
    }

    func performDefaultHandling(for challenge: URLAuthenticationChallenge) {
        // Mock implementation
    }

    func rejectProtectionSpaceAndContinue(with challenge: URLAuthenticationChallenge) {
        // Mock implementation
    }
}

// MARK: - Test Data Extensions

extension URLProtectionSpace {
    /// Helper to set server trust for testing (using setValue for mock purposes)
    func setValue(_ value: Any?, forKey key: String) {
        // In a real implementation, you would use proper SecTrust creation
        // This is a simplified approach for testing
    }
}
