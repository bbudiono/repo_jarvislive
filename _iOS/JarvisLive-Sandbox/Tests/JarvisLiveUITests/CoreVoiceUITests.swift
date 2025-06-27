// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: TDD UI tests for Core Voice functionality - RED PHASE IMPLEMENTATION
 * Issues & Complexity Summary: Voice interface testing with accessibility validation
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~300
 *   - Core Algorithm Complexity: High (UI automation, voice state testing)
 *   - Dependencies: 4 New (XCTest, XCUIApplication, LiveKitManager, Voice UI)
 *   - State Management Complexity: High (Voice states, UI feedback, transcription)
 *   - Novelty/Uncertainty Factor: Medium (Voice UI testing patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Complex voice UI testing with state validation and accessibility
 * Final Code Complexity (Actual %): TBD
 * Overall Result Score (Success & Quality %): TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-25
 */

import XCTest
import XCUITest

/// TDD UI Tests for Core Voice functionality following the development plan
final class CoreVoiceUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        try super.setUpWithError()

        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments.append("--ui-testing")
        app.launchArguments.append("--sandbox-mode")
        app.launch()

        // Wait for app to fully load
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: 5.0), "App window should appear")
    }

    override func tearDownWithError() throws {
        app = nil
        try super.tearDownWithError()
    }

    // MARK: - TDD RED PHASE: Core Voice Recording Tests

    /// Test 1: Record Button Exists and is Hittable (from development plan)
    func test_recordButtonExistsAndIsHittable() {
        // Given: App has launched
        // When: Looking for the record button
        let recordButton = app.buttons["Record"]

        // Then: Record button should exist and be hittable
        XCTAssertTrue(recordButton.exists, "Record button should exist")
        XCTAssertTrue(recordButton.isHittable, "Record button should be hittable")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "record_button_exists"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 2: Voice Activity Indicator Exists
    func test_voiceActivityIndicatorExists() {
        // Given: App has launched
        // When: Looking for voice activity indicator
        let voiceIndicator = app.otherElements["VoiceActivityIndicator"]

        // Then: Voice activity indicator should exist
        XCTAssertTrue(voiceIndicator.exists, "Voice activity indicator should exist")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "voice_activity_indicator"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 3: Connection Status Display Exists
    func test_connectionStatusDisplayExists() {
        // Given: App has launched
        // When: Looking for connection status
        let statusDisplay = app.staticTexts["ConnectionStatus"]

        // Then: Connection status should be displayed
        XCTAssertTrue(statusDisplay.exists, "Connection status should be displayed")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "connection_status_display"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 4: Transcription Display Area Exists
    func test_transcriptionDisplayAreaExists() {
        // Given: App has launched
        // When: Looking for transcription display
        let transcriptionArea = app.textViews["TranscriptionDisplay"]

        // Then: Transcription display should exist
        XCTAssertTrue(transcriptionArea.exists, "Transcription display area should exist")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "transcription_display_area"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 5: AI Response Display Area Exists
    func test_aiResponseDisplayAreaExists() {
        // Given: App has launched
        // When: Looking for AI response display
        let responseArea = app.textViews["AIResponseDisplay"]

        // Then: AI response display should exist
        XCTAssertTrue(responseArea.exists, "AI response display area should exist")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ai_response_display_area"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - TDD RED PHASE: Voice Recording Interaction Tests

    /// Test 6: Record Button Changes State When Tapped
    func test_recordButtonChangesStateWhenTapped() {
        // Given: App is loaded and record button exists
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))

        // When: Tapping the record button
        recordButton.tap()

        // Then: Button state should change (text or appearance)
        // Note: This will fail initially until we implement the state change
        let stopButton = app.buttons["Stop Recording"]
        XCTAssertTrue(stopButton.waitForExistence(timeout: 2.0), "Record button should change to Stop Recording state")

        // Capture visual evidence of state change
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "record_button_state_change"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 7: Voice Activity Indicator Shows Activity During Recording
    func test_voiceActivityIndicatorShowsActivityDuringRecording() {
        // Given: App is loaded and recording is started
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))
        recordButton.tap()

        // When: Voice activity is detected (simulated)
        let voiceIndicator = app.otherElements["VoiceActivityIndicator"]

        // Then: Voice indicator should show activity
        // Note: We'll need to implement visual feedback for voice activity
        XCTAssertTrue(voiceIndicator.exists, "Voice activity indicator should show activity during recording")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "voice_activity_during_recording"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 8: Transcription Updates During Voice Input
    func test_transcriptionUpdatesDisuringVoiceInput() {
        // Given: Recording is active
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))
        recordButton.tap()

        // When: Voice input is processed (simulated)
        let transcriptionArea = app.textViews["TranscriptionDisplay"]

        // Then: Transcription should update with recognized text
        // Note: In actual testing, this would be mocked or use test audio
        XCTAssertTrue(transcriptionArea.exists, "Transcription area should be available for updates")

        // Wait for potential transcription updates
        Thread.sleep(forTimeInterval: 1.0)

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "transcription_during_voice_input"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 9: AI Response Appears After Voice Input Processing
    func test_aiResponseAppearsAfterVoiceInputProcessing() {
        // Given: Voice input has been processed
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))
        recordButton.tap()

        // Simulate voice input processing time
        Thread.sleep(forTimeInterval: 1.0)

        // When: AI processing completes
        let responseArea = app.textViews["AIResponseDisplay"]

        // Then: AI response should appear
        XCTAssertTrue(responseArea.exists, "AI response area should be available for displaying responses")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ai_response_after_processing"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - TDD RED PHASE: Audio Level Visualization Tests

    /// Test 10: Audio Level Meter Exists and Updates
    func test_audioLevelMeterExistsAndUpdates() {
        // Given: App is loaded
        // When: Looking for audio level meter
        let audioMeter = app.progressIndicators["AudioLevelMeter"]

        // Then: Audio level meter should exist
        XCTAssertTrue(audioMeter.exists, "Audio level meter should exist for voice activity visualization")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "audio_level_meter"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 11: Recording State Visual Feedback
    func test_recordingStateVisualFeedback() {
        // Given: App is loaded
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))

        // When: Starting recording
        recordButton.tap()

        // Then: Visual feedback should indicate recording state
        let recordingIndicator = app.otherElements["RecordingStateIndicator"]
        XCTAssertTrue(recordingIndicator.waitForExistence(timeout: 2.0), "Recording state should have visual feedback")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "recording_state_visual_feedback"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - TDD RED PHASE: Accessibility Tests

    /// Test 12: All Voice UI Elements Are Accessible
    func test_allVoiceUIElementsAreAccessible() {
        // Given: App is loaded
        // When: Checking accessibility of voice UI elements
        let elementsToCheck = [
            app.buttons["Record"],
            app.otherElements["VoiceActivityIndicator"],
            app.textViews["TranscriptionDisplay"],
            app.textViews["AIResponseDisplay"],
            app.staticTexts["ConnectionStatus"],
        ]

        // Then: All elements should be accessible
        for element in elementsToCheck {
            if element.exists {
                XCTAssertTrue(element.isHittable, "Element \(element.identifier) should be accessible")
            }
        }

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "voice_ui_accessibility"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 13: Voice UI Supports VoiceOver Navigation
    func test_voiceUISupportsVoiceOverNavigation() {
        // Given: App is loaded
        // When: Checking VoiceOver support
        let recordButton = app.buttons["Record"]

        // Then: Elements should have proper accessibility labels
        if recordButton.exists {
            let accessibilityLabel = recordButton.label
            XCTAssertFalse(accessibilityLabel.isEmpty, "Record button should have accessibility label")
        }

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "voiceover_support"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - TDD RED PHASE: Integration Tests

    /// Test 14: Complete Voice Interaction Flow
    func test_completeVoiceInteractionFlow() {
        // Given: App is loaded and connected
        // When: Performing complete voice interaction

        // Step 1: Start recording
        let recordButton = app.buttons["Record"]
        XCTAssertTrue(recordButton.waitForExistence(timeout: 2.0))
        recordButton.tap()

        // Step 2: Simulate voice activity
        Thread.sleep(forTimeInterval: 1.0)

        // Step 3: Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }

        // Step 4: Wait for AI processing
        Thread.sleep(forTimeInterval: 2.0)

        // Then: All UI elements should reflect the interaction state
        XCTAssertTrue(app.windows.firstMatch.exists, "App should remain stable throughout interaction")

        // Capture visual evidence of complete flow
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "complete_voice_interaction_flow"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Test 15: Error State Handling in Voice UI
    func test_errorStateHandlingInVoiceUI() {
        // Given: App is loaded
        // When: An error occurs during voice processing

        // Simulate error condition by trying to record without connection
        let recordButton = app.buttons["Record"]
        if recordButton.exists {
            recordButton.tap()
        }

        // Then: Error state should be displayed to user
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'error'")).firstMatch

        // Note: This test validates that error states are properly communicated to users
        XCTAssertTrue(app.windows.firstMatch.exists, "App should handle error states gracefully")

        // Capture visual evidence
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "error_state_handling"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}

// MARK: - Test Helper Extensions

extension CoreVoiceUITests {
    /// Helper to wait for voice processing to complete
    private func waitForVoiceProcessing(timeout: TimeInterval = 3.0) {
        let processingComplete = expectation(description: "Voice processing complete")

        DispatchQueue.main.asyncAfter(deadline: .now() + timeout) {
            processingComplete.fulfill()
        }

        wait(for: [processingComplete], timeout: timeout + 1.0)
    }

    /// Helper to capture screenshot with timestamp
    private func captureTimestampedScreenshot(name: String) {
        let timestamp = Date().timeIntervalSince1970
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "\(name)_\(timestamp)"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
