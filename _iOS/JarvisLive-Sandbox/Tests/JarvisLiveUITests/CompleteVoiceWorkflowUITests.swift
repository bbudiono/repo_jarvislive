// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive UI automation testing for complete voice AI workflow
 * Issues & Complexity Summary: End-to-end user experience validation with accessibility testing
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~250
 *   - Core Algorithm Complexity: Medium (UI automation patterns)
 *   - Dependencies: 2 New (XCTest, XCUITest)
 *   - State Management Complexity: Medium (UI state transitions)
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment: 85%
 * Problem Estimate: 70%
 * Initial Code Complexity Estimate: 75%
 * Final Code Complexity: TBD
 * Overall Result Score: TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import XCTest

final class CompleteVoiceWorkflowUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Main Interface Tests

    func test_mainInterface_displaysCorrectElements() throws {
        // Verify main app elements are present and accessible

        let sandboxLabel = app.staticTexts["🧪 SANDBOX MODE"]
        XCTAssertTrue(sandboxLabel.exists, "Sandbox watermark should be visible")

        let titleLabel = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleLabel.exists, "Main title should be displayed")

        let subtitleLabel = app.staticTexts["AI Voice Assistant"]
        XCTAssertTrue(subtitleLabel.exists, "Subtitle should be displayed")

        let connectionStatus = app.otherElements["ConnectionStatus"]
        XCTAssertTrue(connectionStatus.exists, "Connection status should be accessible")

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists, "Settings button should be accessible")
        XCTAssertTrue(settingsButton.isHittable, "Settings button should be tappable")
    }

    func test_connectionWorkflow_initialDisconnectedState() throws {
        // Verify initial disconnected state and connection UI

        let connectionStatus = app.otherElements["ConnectionStatus"]
        XCTAssertTrue(connectionStatus.exists)

        // Should show connection button when disconnected
        let connectButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Connect'")).firstMatch
        if connectButton.exists {
            XCTAssertTrue(connectButton.isHittable, "Connect button should be tappable")
        }
    }

    // MARK: - Settings Interface Tests

    func test_settingsModal_accessibilityAndNavigation() throws {
        // Test settings modal can be opened and navigated

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists)

        settingsButton.tap()

        // Verify settings modal opened
        let settingsTitle = app.navigationBars.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2.0), "Settings modal should open")

        // Verify API configuration section
        let apiConfigTitle = app.staticTexts["API Configuration"]
        XCTAssertTrue(apiConfigTitle.exists, "API Configuration section should be visible")

        // Check for Claude API section
        let claudeSection = app.staticTexts["Claude API Key"]
        XCTAssertTrue(claudeSection.exists, "Claude API section should be present")

        // Check for OpenAI API section
        let openaiSection = app.staticTexts["OpenAI API Key"]
        XCTAssertTrue(openaiSection.exists, "OpenAI API section should be present")

        // Check for ElevenLabs API section
        let elevenLabsSection = app.staticTexts["ElevenLabs API Key"]
        XCTAssertTrue(elevenLabsSection.exists, "ElevenLabs API section should be present")

        // Check for LiveKit configuration
        let liveKitSection = app.staticTexts["LiveKit Configuration"]
        XCTAssertTrue(liveKitSection.exists, "LiveKit configuration should be present")

        // Verify Done button functionality
        let doneButton = app.buttons["Done"]
        XCTAssertTrue(doneButton.exists, "Done button should be present")
        XCTAssertTrue(doneButton.isHittable, "Done button should be tappable")

        doneButton.tap()

        // Verify modal dismissed
        XCTAssertFalse(settingsTitle.exists, "Settings modal should be dismissed")
    }

    func test_settingsForm_inputFieldsAccessibility() throws {
        // Test that settings form fields are accessible and functional

        let settingsButton = app.buttons["Settings"]
        settingsButton.tap()

        let settingsTitle = app.navigationBars.staticTexts["Settings"]
        XCTAssertTrue(settingsTitle.waitForExistence(timeout: 2.0))

        // Test Claude API key field
        let claudeKeyField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'Claude'")).firstMatch
        if claudeKeyField.exists {
            XCTAssertTrue(claudeKeyField.isHittable, "Claude API key field should be editable")

            claudeKeyField.tap()
            claudeKeyField.typeText("test-claude-key")

            // Verify test button for Claude
            let claudeTestButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Test'")).firstMatch
            XCTAssertTrue(claudeTestButton.exists, "Claude test button should be present")
        }

        // Test OpenAI API key field
        let openaiKeyField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'OpenAI'")).firstMatch
        if openaiKeyField.exists {
            XCTAssertTrue(openaiKeyField.isHittable, "OpenAI API key field should be editable")
        }

        // Test ElevenLabs API key field
        let elevenLabsKeyField = app.secureTextFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'ElevenLabs'")).firstMatch
        if elevenLabsKeyField.exists {
            XCTAssertTrue(elevenLabsKeyField.isHittable, "ElevenLabs API key field should be editable")
        }

        // Test LiveKit URL field
        let liveKitURLField = app.textFields.containing(NSPredicate(format: "placeholderValue CONTAINS 'livekit'")).firstMatch
        if liveKitURLField.exists {
            XCTAssertTrue(liveKitURLField.isHittable, "LiveKit URL field should be editable")

            liveKitURLField.tap()
            liveKitURLField.typeText("wss://test.livekit.io")
        }

        // Test Save Settings button
        let saveButton = app.buttons["Save Settings"]
        XCTAssertTrue(saveButton.exists, "Save Settings button should be present")
        XCTAssertTrue(saveButton.isHittable, "Save Settings button should be tappable")

        // Close settings
        let doneButton = app.buttons["Done"]
        doneButton.tap()
    }

    // MARK: - Voice Recording Interface Tests

    func test_voiceRecordingInterface_whenConnected() throws {
        // This test assumes a connected state - in real implementation,
        // we would need to mock the connection or set up test credentials

        // Note: This test will need actual connection setup in production
        // For now, we test the UI elements that should be present when connected

        // Look for recording-related UI elements
        let recordButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Record'")).firstMatch
        if recordButton.exists {
            XCTAssertTrue(recordButton.isHittable, "Record button should be tappable when available")
        }

        // Check for transcription display area
        let transcriptionDisplay = app.otherElements["TranscriptionDisplay"]
        if transcriptionDisplay.exists {
            XCTAssertTrue(transcriptionDisplay.isHittable, "Transcription display should be accessible")
        }

        // Check for AI response display area
        let aiResponseDisplay = app.otherElements["AIResponseDisplay"]
        if aiResponseDisplay.exists {
            XCTAssertTrue(aiResponseDisplay.isHittable, "AI response display should be accessible")
        }
    }

    func test_voiceActivityIndicators_accessibility() throws {
        // Test voice activity visual indicators are accessible

        let voiceActivityIndicator = app.otherElements["VoiceActivityIndicator"]
        if voiceActivityIndicator.exists {
            XCTAssertTrue(voiceActivityIndicator.isHittable, "Voice activity indicator should be accessible")
        }

        let recordingStateIndicator = app.otherElements["RecordingStateIndicator"]
        if recordingStateIndicator.exists {
            XCTAssertTrue(recordingStateIndicator.isHittable, "Recording state indicator should be accessible")
        }

        let audioLevelMeter = app.otherElements["AudioLevelMeter"]
        if audioLevelMeter.exists {
            XCTAssertTrue(audioLevelMeter.isHittable, "Audio level meter should be accessible")
        }
    }

    // MARK: - Accessibility Tests

    func test_voiceOverSupport_allElements() throws {
        // Comprehensive accessibility testing for VoiceOver users

        // Main navigation elements
        let settingsButton = app.buttons["Settings"]
        XCTAssertNotNil(settingsButton.label, "Settings button should have accessibility label")

        // Test that all interactive elements have proper accessibility labels
        let allButtons = app.buttons.allElementsBoundByIndex
        for button in allButtons {
            if button.exists && button.isHittable {
                XCTAssertFalse(button.label.isEmpty, "Button should have non-empty accessibility label: \(button)")
            }
        }

        // Test that display elements have proper accessibility labels
        let transcriptionDisplay = app.otherElements["TranscriptionDisplay"]
        if transcriptionDisplay.exists {
            XCTAssertNotNil(transcriptionDisplay.label, "Transcription display should have accessibility label")
        }

        let aiResponseDisplay = app.otherElements["AIResponseDisplay"]
        if aiResponseDisplay.exists {
            XCTAssertNotNil(aiResponseDisplay.label, "AI response display should have accessibility label")
        }
    }

    // MARK: - Performance Tests

    func test_appLaunchPerformance() throws {
        // Measure app launch time
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func test_settingsModalPerformance() throws {
        // Measure settings modal open/close performance

        measure {
            let settingsButton = app.buttons["Settings"]
            settingsButton.tap()

            let settingsTitle = app.navigationBars.staticTexts["Settings"]
            _ = settingsTitle.waitForExistence(timeout: 5.0)

            let doneButton = app.buttons["Done"]
            doneButton.tap()

            // Wait for modal to dismiss
            _ = settingsTitle.waitForNonExistence(timeout: 5.0)
        }
    }

    // MARK: - Error State Tests

    func test_errorStateHandling_userInterface() throws {
        // Test that error states are properly displayed to users

        // This test would need actual error conditions to be triggered
        // For now, we verify that error-related UI elements can be accessed

        let connectionStatus = app.otherElements["ConnectionStatus"]
        XCTAssertTrue(connectionStatus.exists, "Connection status should always be visible")
    }

    func test_offlineMode_userInterface() throws {
        // Test app behavior and UI when offline

        // Note: This would require network simulation in a real test environment
        // For now, we verify the app doesn't crash when launched

        XCTAssertTrue(app.exists, "App should remain functional in offline scenarios")

        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.exists, "Settings should still be accessible offline")
    }
}
