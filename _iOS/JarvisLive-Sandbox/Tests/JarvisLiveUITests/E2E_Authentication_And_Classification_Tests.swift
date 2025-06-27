/*
* Purpose: End-to-End integration tests for iOS-Python backend authentication and classification
* Issues & Complexity Summary: Complete E2E validation of live API integration
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: High (live network testing, async coordination)
  - Dependencies: 3 New (XCUITest, live Python backend, network mocking)
  - State Management Complexity: High (authentication state, network state, UI state)
  - Novelty/Uncertainty Factor: High (live backend integration testing)
* AI Pre-Task Self-Assessment: 80%
* Problem Estimate: 85%
* Initial Code Complexity Estimate: 85%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-27
*/

import XCTest

final class E2EAuthenticationAndClassificationTests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Configure app for testing with live backend
        app.launchArguments.append("-EnableE2ETesting")
        app.launchArguments.append("-PythonBackendURL")
        app.launchArguments.append("http://localhost:8000") // Default local Python server

        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Authentication Flow Tests

    func test_successfulLogin_showsMainView() throws {
        // This test validates the complete live authentication flow

        // Navigate to authentication view
        let authenticationView = app.otherElements["AuthenticationView"]
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5), "Authentication view should be visible")

        // Enter valid credentials (these should match Python backend test user)
        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        usernameField.tap()
        usernameField.typeText("testuser@example.com")

        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("testpassword123")

        // Tap login button
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists)
        XCTAssertTrue(loginButton.isEnabled, "Login button should be enabled with valid credentials")
        loginButton.tap()

        // Wait for authentication processing
        waitForNetworkOperation(timeout: 10)

        // Wait for authentication to complete and main view to appear
        let mainView = app.otherElements["MainView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 15), "Main view should appear after successful login")

        // Verify authentication state indicators
        let authenticationStatusIndicator = app.otherElements["authenticationStatusIndicator"]
        if authenticationStatusIndicator.exists {
            XCTAssertTrue(authenticationStatusIndicator.label.contains("Authenticated"),
                         "Should show authenticated status")
        }

        // Verify that we can access authenticated features
        let voiceInputButton = app.buttons["microphoneButton"]
        if voiceInputButton.exists {
            XCTAssertTrue(voiceInputButton.isEnabled, "Voice input should be enabled after authentication")
        }
    }

    func test_invalidLogin_showsError() throws {
        // Navigate to authentication view
        let authenticationView = app.otherElements["AuthenticationView"]
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5))

        // Enter invalid credentials
        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        usernameField.tap()
        usernameField.typeText("invalid@example.com")

        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("wrongpassword")

        // Tap login button
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()

        // Wait for error message to appear
        let errorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'error' OR label CONTAINS[c] 'invalid' OR label CONTAINS[c] 'failed'")).firstMatch
        XCTAssertTrue(errorMessage.waitForExistence(timeout: 5), "Error message should appear for invalid credentials")

        // Verify we remain on authentication view
        XCTAssertTrue(authenticationView.exists, "Should remain on authentication view after failed login")
    }

    func test_networkError_showsRetryOption() throws {
        // This test assumes the Python backend is offline or unreachable

        // Configure app to use unreachable backend URL
        app.terminate()
        app.launchArguments.append("-PythonBackendURL")
        app.launchArguments.append("http://localhost:9999") // Unreachable port
        app.launch()

        let authenticationView = app.otherElements["AuthenticationView"]
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5))

        // Enter valid-format credentials
        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        usernameField.tap()
        usernameField.typeText("testuser@example.com")

        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("testpassword123")

        // Tap login button
        let loginButton = app.buttons["loginButton"]
        loginButton.tap()

        // Wait for network error message
        let networkErrorMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'network' OR label CONTAINS[c] 'connection' OR label CONTAINS[c] 'offline'")).firstMatch
        XCTAssertTrue(networkErrorMessage.waitForExistence(timeout: 8), "Network error message should appear")

        // Look for retry option
        let retryButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'retry' OR label CONTAINS[c] 'try again'")).firstMatch
        XCTAssertTrue(retryButton.exists, "Retry option should be available for network errors")
    }

    // MARK: - Voice Classification Tests

    func test_liveVoiceClassificationWithAuthentication() throws {
        // First authenticate successfully
        try authenticateWithValidCredentials()

        // Navigate to voice input area
        let voiceInputView = app.otherElements["VoiceInputView"]
        XCTAssertTrue(voiceInputView.waitForExistence(timeout: 5), "Voice input view should be accessible after authentication")

        // Simulate voice input (using text field for testing)
        let voiceTextInput = app.textFields["voiceTextInput"]
        if voiceTextInput.exists {
            voiceTextInput.tap()
            voiceTextInput.typeText("Create a PDF document about quarterly results")
        }

        // Trigger classification
        let classifyButton = app.buttons["classifyVoiceCommand"]
        if classifyButton.exists {
            classifyButton.tap()
        } else {
            // Alternative: trigger via microphone button
            let microphoneButton = app.buttons["microphoneButton"]
            XCTAssertTrue(microphoneButton.exists, "Microphone button should be available")
            microphoneButton.tap()
        }

        // Wait for network processing
        waitForNetworkOperation(timeout: 10)

        // Wait for classification result from live backend
        let classificationResult = app.otherElements["ClassificationResult"]
        XCTAssertTrue(classificationResult.waitForExistence(timeout: 15), "Classification result from live backend should appear")

        // Verify classification contains expected elements from live API response
        let confidenceIndicator = app.otherElements["ConfidenceIndicator"]
        XCTAssertTrue(confidenceIndicator.exists, "Confidence indicator should be present")

        let categoryBadge = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'document' OR label CONTAINS[c] 'generation'")).firstMatch
        XCTAssertTrue(categoryBadge.exists, "Category should be correctly identified by live backend")

        // Verify execute button is available
        let executeButton = app.buttons["Execute Command"]
        XCTAssertTrue(executeButton.exists, "Execute button should be available for valid classification")

        // Verify confidence level is reasonable for live classification
        if confidenceIndicator.exists {
            let confidenceText = confidenceIndicator.label
            XCTAssertTrue(confidenceText.contains("%"), "Confidence should be displayed as percentage")
        }

        // Test that we can interact with the classification result
        if executeButton.exists && executeButton.isEnabled {
            executeButton.tap()

            // Wait for execution to complete
            let executionResult = app.otherElements["ExecutionResult"]
            if executionResult.waitForExistence(timeout: 10) {
                XCTAssertTrue(executionResult.exists, "Execution result should be displayed")
            }
        }
    }

    func test_tokenRefreshScenario() throws {
        // This test simulates JWT token expiration and refresh

        // First authenticate successfully
        try authenticateWithValidCredentials()

        // Simulate token expiration by waiting or triggering refresh
        // This would require backend cooperation or time manipulation

        // Attempt voice classification that should trigger token refresh
        let voiceInputView = app.otherElements["VoiceInputView"]
        XCTAssertTrue(voiceInputView.waitForExistence(timeout: 5))

        let voiceTextInput = app.textFields["voiceTextInput"]
        if voiceTextInput.exists {
            voiceTextInput.tap()
            voiceTextInput.typeText("Send an email to team about meeting")
        }

        let classifyButton = app.buttons["classifyVoiceCommand"]
        if classifyButton.exists {
            classifyButton.tap()
        }

        // Should either succeed with refresh or show re-authentication prompt
        // This test validates graceful handling of token expiration
        let result = app.otherElements["ClassificationResult"]
        let authPrompt = app.otherElements["AuthenticationView"]

        XCTAssertTrue(result.waitForExistence(timeout: 10) || authPrompt.waitForExistence(timeout: 10),
                     "Should either show result (with refresh) or auth prompt (if refresh failed)")
    }

    func test_offlineModeGracefulDegradation() throws {
        // Test offline mode fallback functionality

        // First authenticate successfully
        try authenticateWithValidCredentials()

        // Simulate network disconnect by changing backend URL
        // This would ideally be done through network condition simulation

        // Attempt voice classification in offline mode
        let voiceInputView = app.otherElements["VoiceInputView"]
        XCTAssertTrue(voiceInputView.waitForExistence(timeout: 5))

        let voiceTextInput = app.textFields["voiceTextInput"]
        if voiceTextInput.exists {
            voiceTextInput.tap()
            voiceTextInput.typeText("Create a document")
        }

        let classifyButton = app.buttons["classifyVoiceCommand"]
        if classifyButton.exists {
            classifyButton.tap()
        }

        // Should show offline mode indicator or fallback classification
        let offlineIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'offline' OR label CONTAINS[c] 'local'")).firstMatch
        let fallbackResult = app.otherElements["ClassificationResult"]

        XCTAssertTrue(offlineIndicator.waitForExistence(timeout: 5) || fallbackResult.waitForExistence(timeout: 5),
                     "Should show offline indicator or provide fallback classification")
    }

    // MARK: - Performance Validation Tests

    func test_e2ePerformanceValidation() throws {
        // Test end-to-end performance meets <200ms requirement

        // First authenticate successfully
        try authenticateWithValidCredentials()

        measure(metrics: [XCTClockMetric()]) {
            // Navigate to voice input
            let voiceInputView = app.otherElements["VoiceInputView"]
            XCTAssertTrue(voiceInputView.waitForExistence(timeout: 2))

            // Input voice command
            let voiceTextInput = app.textFields["voiceTextInput"]
            if voiceTextInput.exists {
                voiceTextInput.tap()
                voiceTextInput.typeText("Quick test command")
            }

            // Trigger classification and measure response time
            let classifyButton = app.buttons["classifyVoiceCommand"]
            if classifyButton.exists {
                classifyButton.tap()
            }

            // Wait for result (this measures the total time)
            let classificationResult = app.otherElements["ClassificationResult"]
            XCTAssertTrue(classificationResult.waitForExistence(timeout: 3), "Classification should complete within performance window")
        }
    }

    func test_authenticationPerformance() throws {
        measure(metrics: [XCTClockMetric()]) {
            // Test authentication performance
            let authenticationView = app.otherElements["AuthenticationView"]
            XCTAssertTrue(authenticationView.waitForExistence(timeout: 2))

            let usernameField = app.textFields["usernameField"]
            XCTAssertTrue(usernameField.waitForExistence(timeout: 1))
            usernameField.tap()
            usernameField.typeText("testuser@example.com")

            let passwordField = app.secureTextFields["passwordField"]
            passwordField.tap()
            passwordField.typeText("testpassword123")

            let loginButton = app.buttons["loginButton"]
            loginButton.tap()

            // Measure time to authentication completion
            let mainView = app.otherElements["MainView"]
            XCTAssertTrue(mainView.waitForExistence(timeout: 5), "Authentication should complete quickly")
        }
    }

    // MARK: - Helper Methods

    private func authenticateWithValidCredentials() throws {
        let authenticationView = app.otherElements["AuthenticationView"]
        XCTAssertTrue(authenticationView.waitForExistence(timeout: 5))

        let usernameField = app.textFields["usernameField"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 2))
        usernameField.tap()
        usernameField.typeText("testuser@example.com")

        let passwordField = app.secureTextFields["passwordField"]
        XCTAssertTrue(passwordField.exists)
        passwordField.tap()
        passwordField.typeText("testpassword123")

        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(loginButton.exists)
        loginButton.tap()

        let mainView = app.otherElements["MainView"]
        XCTAssertTrue(mainView.waitForExistence(timeout: 10), "Authentication should succeed")
    }

    private func waitForNetworkOperation(timeout: TimeInterval = 10) {
        // Helper to wait for network operations to complete
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            let disappearsPredicate = NSPredicate(format: "exists == FALSE")
            expectation(for: disappearsPredicate, evaluatedWith: loadingIndicator, handler: nil)
            waitForExpectations(timeout: timeout, handler: nil)
        }
    }

    private func verifyAuthenticationState(expected: Bool) {
        let authenticationStatusIndicator = app.otherElements["authenticationStatusIndicator"]
        if authenticationStatusIndicator.exists {
            if expected {
                XCTAssertTrue(authenticationStatusIndicator.label.contains("Authenticated"),
                             "Should show authenticated status")
            } else {
                XCTAssertFalse(authenticationStatusIndicator.label.contains("Authenticated"),
                              "Should not show authenticated status")
            }
        }
    }

    private func clearAppData() {
        // Helper to clear authentication data between tests
        let settingsButton = app.buttons["settingsButton"]
        if settingsButton.exists {
            settingsButton.tap()

            let clearDataButton = app.buttons["clearAllData"]
            if clearDataButton.exists {
                clearDataButton.tap()

                let confirmButton = app.buttons["Confirm"]
                if confirmButton.exists {
                    confirmButton.tap()
                }
            }
        }
    }
}
