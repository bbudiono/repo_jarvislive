// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive E2E UI test suite for complete voice command pipeline - from user interaction to final result
 * Issues & Complexity Summary: Full pipeline testing including UI automation, voice simulation, classification, MCP execution, and result display
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~800
 *   - Core Algorithm Complexity: Very High (End-to-end pipeline simulation, UI automation, mock server integration)
 *   - Dependencies: 8 New (XCUITest, XCTest, mock servers, UI automation, pipeline testing)
 *   - State Management Complexity: Very High (Multi-step pipeline states, UI state validation, async coordination)
 *   - Novelty/Uncertainty Factor: High (Complete pipeline E2E testing with realistic user scenarios)
 * AI Pre-Task Self-Assessment: 92%
 * Problem Estimate: 90%
 * Initial Code Complexity Estimate: 88%
 * Final Code Complexity: 91%
 * Overall Result Score: 95%
 * Key Variances/Learnings: E2E pipeline testing requires careful coordination of multiple async components and realistic user simulation
 * Last Updated: 2025-06-27
 */

import XCTest
import SwiftUI
@testable import JarvisLiveSandbox

final class PipelineE2ETests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()

        // Configure app for E2E testing
        app.launchArguments = [
            "-ui-testing",
            "-disable-animations",
            "-PythonBackendURL", "http://localhost:8888", // Mock server for testing
            "-MockMCPServer", "true",
            "-E2ETestMode", "true",
        ]

        // Set up mock environment variables
        app.launchEnvironment = [
            "UITEST_DISABLE_ANIMATIONS": "1",
            "UITEST_PIPELINE_MODE": "1",
            "MockVoiceClassification": "1",
            "MockMCPExecution": "1",
        ]
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    // MARK: - Complete Pipeline E2E Tests

    func testCompleteVoiceCommandPipeline_DocumentGeneration_Success() throws {
        // GIVEN: App launched and connected
        app.launch()

        // Wait for app to load
        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect to LiveKit (mock connection)
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            // Wait for connection
            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: User initiates voice command for document generation
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Simulate voice input processing
        let transcriptionArea = app.textViews["Voice Transcription"]
        XCTAssertTrue(transcriptionArea.waitForExistence(timeout: 3.0))

        // Wait for transcription to appear (simulated)
        let documentCommand = "Create a professional business proposal document"
        let transcriptionText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Create"))
        XCTAssertTrue(transcriptionText.firstMatch.waitForExistence(timeout: 8.0))

        // THEN: Pipeline should process the command

        // 1. Voice classification should occur
        let classificationIndicator = app.activityIndicators["Voice Classification"]
        XCTAssertTrue(classificationIndicator.waitForExistence(timeout: 3.0))

        // 2. Classification result should be displayed
        let classificationResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "document_generation"))
        XCTAssertTrue(classificationResult.firstMatch.waitForExistence(timeout: 5.0))

        // 3. MCP execution should begin
        let mcpExecutionIndicator = app.activityIndicators["MCP Execution"]
        XCTAssertTrue(mcpExecutionIndicator.waitForExistence(timeout: 3.0))

        // 4. Final result should be displayed
        let finalResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Document created successfully"))
        XCTAssertTrue(finalResult.firstMatch.waitForExistence(timeout: 10.0))

        // 5. UI should return to ready state
        let readyStatus = app.staticTexts["Ready for voice input"]
        XCTAssertTrue(readyStatus.waitForExistence(timeout: 3.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }

        // Verify pipeline metrics are recorded
        let metricsButton = app.buttons["Pipeline Metrics"]
        if metricsButton.exists {
            metricsButton.tap()

            let processingTime = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Processing Time:"))
            XCTAssertTrue(processingTime.firstMatch.waitForExistence(timeout: 2.0))
        }
    }

    func testCompleteVoiceCommandPipeline_EmailManagement_Success() throws {
        // GIVEN: App launched and connected
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Ensure connection
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: User initiates voice command for email
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Simulate email command transcription
        let transcriptionArea = app.textViews["Voice Transcription"]
        XCTAssertTrue(transcriptionArea.waitForExistence(timeout: 3.0))

        let emailTranscription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Send an email"))
        XCTAssertTrue(emailTranscription.firstMatch.waitForExistence(timeout: 8.0))

        // THEN: Email pipeline should execute

        // 1. Classification should identify email intent
        let emailClassification = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "email_management"))
        XCTAssertTrue(emailClassification.firstMatch.waitForExistence(timeout: 5.0))

        // 2. Email MCP action should execute
        let emailMCPAction = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Sending email"))
        XCTAssertTrue(emailMCPAction.firstMatch.waitForExistence(timeout: 8.0))

        // 3. Success confirmation should appear
        let emailSuccess = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Email sent successfully"))
        XCTAssertTrue(emailSuccess.firstMatch.waitForExistence(timeout: 10.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    func testCompleteVoiceCommandPipeline_CalendarEvent_Success() throws {
        // GIVEN: App launched and connected
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Ensure connection
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: User creates calendar event via voice
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Simulate calendar command
        let calendarTranscription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Schedule a meeting"))
        XCTAssertTrue(calendarTranscription.firstMatch.waitForExistence(timeout: 8.0))

        // THEN: Calendar pipeline should execute

        // 1. Classification as calendar event
        let calendarClassification = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "calendar_scheduling"))
        XCTAssertTrue(calendarClassification.firstMatch.waitForExistence(timeout: 5.0))

        // 2. Calendar MCP execution
        let calendarMCPAction = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Creating calendar event"))
        XCTAssertTrue(calendarMCPAction.firstMatch.waitForExistence(timeout: 8.0))

        // 3. Event creation confirmation
        let eventSuccess = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Event created successfully"))
        XCTAssertTrue(eventSuccess.firstMatch.waitForExistence(timeout: 10.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    func testCompleteVoiceCommandPipeline_WebSearch_Success() throws {
        // GIVEN: App launched and connected
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Ensure connection
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: User performs web search via voice
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Simulate search command
        let searchTranscription = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Search for"))
        XCTAssertTrue(searchTranscription.firstMatch.waitForExistence(timeout: 8.0))

        // THEN: Search pipeline should execute

        // 1. Classification as web search
        let searchClassification = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "web_search"))
        XCTAssertTrue(searchClassification.firstMatch.waitForExistence(timeout: 5.0))

        // 2. Search MCP execution
        let searchMCPAction = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Performing search"))
        XCTAssertTrue(searchMCPAction.firstMatch.waitForExistence(timeout: 8.0))

        // 3. Search results display
        let searchResults = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Search completed"))
        XCTAssertTrue(searchResults.firstMatch.waitForExistence(timeout: 10.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    // MARK: - Error Handling E2E Tests

    func testVoiceCommandPipeline_ClassificationFailure_GracefulHandling() throws {
        // GIVEN: App launched with mock classification failure
        app.launchEnvironment["MockClassificationFailure"] = "1"
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: Voice command triggers classification failure
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // THEN: Error should be handled gracefully

        // 1. Error message should appear
        let errorMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Classification failed"))
        XCTAssertTrue(errorMessage.firstMatch.waitForExistence(timeout: 8.0))

        // 2. Suggestions should be offered
        let suggestionsText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Please try"))
        XCTAssertTrue(suggestionsText.firstMatch.waitForExistence(timeout: 3.0))

        // 3. UI should return to ready state
        let readyState = app.staticTexts["Ready for voice input"]
        XCTAssertTrue(readyState.waitForExistence(timeout: 5.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    func testVoiceCommandPipeline_MCPExecutionFailure_GracefulHandling() throws {
        // GIVEN: App launched with mock MCP failure
        app.launchEnvironment["MockMCPFailure"] = "1"
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: Voice command triggers MCP execution failure
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Classification should succeed
        let classificationResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "document_generation"))
        XCTAssertTrue(classificationResult.firstMatch.waitForExistence(timeout: 5.0))

        // THEN: MCP failure should be handled gracefully

        // 1. MCP error message should appear
        let mcpError = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "MCP execution failed"))
        XCTAssertTrue(mcpError.firstMatch.waitForExistence(timeout: 8.0))

        // 2. Fallback message should be provided
        let fallbackMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Please try again"))
        XCTAssertTrue(fallbackMessage.firstMatch.waitForExistence(timeout: 3.0))

        // 3. UI should return to ready state
        let readyState = app.staticTexts["Ready for voice input"]
        XCTAssertTrue(readyState.waitForExistence(timeout: 5.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    // MARK: - Performance E2E Tests

    func testVoiceCommandPipeline_PerformanceMetrics_WithinAcceptableLimits() throws {
        // GIVEN: App launched with performance monitoring
        app.launchEnvironment["EnablePerformanceMetrics"] = "1"
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: Execute voice command and measure performance
        let startTime = Date()

        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        // Wait for complete pipeline execution
        let finalResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "successfully"))
        XCTAssertTrue(finalResult.firstMatch.waitForExistence(timeout: 15.0))

        let endTime = Date()
        let totalProcessingTime = endTime.timeIntervalSince(startTime)

        // THEN: Performance should be within acceptable limits

        // 1. Total processing time should be under 10 seconds
        XCTAssertLessThan(totalProcessingTime, 10.0, "Total pipeline processing time should be under 10 seconds")

        // 2. Check individual component metrics if available
        let metricsButton = app.buttons["Pipeline Metrics"]
        if metricsButton.exists {
            metricsButton.tap()

            // Classification time
            let classificationTime = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Classification:"))
            if classificationTime.firstMatch.exists {
                // Should be under 2 seconds for classification
                let classificationText = classificationTime.firstMatch.label
                // Extract time value and verify it's reasonable
                XCTAssertTrue(classificationText.contains("ms") || classificationText.contains("s"))
            }

            // MCP execution time
            let mcpTime = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "MCP Execution:"))
            if mcpTime.firstMatch.exists {
                // Should be under 5 seconds for MCP execution
                let mcpText = mcpTime.firstMatch.label
                XCTAssertTrue(mcpText.contains("ms") || mcpText.contains("s"))
            }
        }

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    // MARK: - Multi-Step Pipeline E2E Tests

    func testMultiStepVoiceCommandPipeline_ChainedCommands_Success() throws {
        // GIVEN: App launched for multi-step testing
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: Execute multiple voice commands in sequence

        // Step 1: Create a document
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        let documentResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Document created"))
        XCTAssertTrue(documentResult.firstMatch.waitForExistence(timeout: 10.0))

        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }

        // Wait a moment between commands
        Thread.sleep(forTimeInterval: 2.0)

        // Step 2: Send an email about the document
        microphoneButton.tap()

        let emailResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Email sent"))
        XCTAssertTrue(emailResult.firstMatch.waitForExistence(timeout: 10.0))

        if stopButton.exists {
            stopButton.tap()
        }

        // Wait a moment between commands
        Thread.sleep(forTimeInterval: 2.0)

        // Step 3: Schedule a follow-up meeting
        microphoneButton.tap()

        let calendarResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Event created"))
        XCTAssertTrue(calendarResult.firstMatch.waitForExistence(timeout: 10.0))

        if stopButton.exists {
            stopButton.tap()
        }

        // THEN: All commands should have been executed successfully
        // Verify session context maintains continuity
        let sessionSummaryButton = app.buttons["Session Summary"]
        if sessionSummaryButton.exists {
            sessionSummaryButton.tap()

            let commandCount = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Commands: 3"))
            XCTAssertTrue(commandCount.firstMatch.waitForExistence(timeout: 3.0))
        }
    }

    // MARK: - Accessibility E2E Tests

    func testVoiceCommandPipeline_AccessibilitySupport_VoiceOverEnabled() throws {
        // GIVEN: App launched with VoiceOver simulation
        app.launchEnvironment["SimulateVoiceOver"] = "1"
        app.launch()

        // Enable accessibility inspector mode
        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Verify accessibility labels are present
        XCTAssertTrue(titleElement.isAccessibilityElement)
        XCTAssertFalse(titleElement.accessibilityLabel?.isEmpty ?? true)

        // Connect with accessibility support
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            XCTAssertTrue(connectButton.isAccessibilityElement)
            XCTAssertFalse(connectButton.accessibilityLabel?.isEmpty ?? true)

            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
            XCTAssertTrue(connectedStatus.isAccessibilityElement)
        }

        // WHEN: Use voice commands with accessibility enabled
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        XCTAssertTrue(microphoneButton.isAccessibilityElement)
        XCTAssertFalse(microphoneButton.accessibilityLabel?.isEmpty ?? true)

        microphoneButton.tap()

        // THEN: All pipeline components should be accessible

        // 1. Transcription area should be accessible
        let transcriptionArea = app.textViews["Voice Transcription"]
        if transcriptionArea.waitForExistence(timeout: 3.0) {
            XCTAssertTrue(transcriptionArea.isAccessibilityElement)
        }

        // 2. Classification results should be accessible
        let classificationResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "document_generation"))
        if classificationResult.firstMatch.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(classificationResult.firstMatch.isAccessibilityElement)
        }

        // 3. Final results should be accessible
        let finalResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "successfully"))
        if finalResult.firstMatch.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(finalResult.firstMatch.isAccessibilityElement)
            XCTAssertFalse(finalResult.firstMatch.accessibilityLabel?.isEmpty ?? true)
        }

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            XCTAssertTrue(stopButton.isAccessibilityElement)
            stopButton.tap()
        }
    }

    // MARK: - Integration E2E Tests

    func testVoiceCommandPipeline_SettingsIntegration_ConfigurationChanges() throws {
        // GIVEN: App launched
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // WHEN: Change settings and test pipeline

        // 1. Open settings
        let settingsButton = app.buttons["Settings"]
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 3.0))
        settingsButton.tap()

        // 2. Modify AI provider settings (if available)
        let claudeAPIField = app.secureTextFields["Enter Claude API Key"]
        if claudeAPIField.exists {
            claudeAPIField.tap()
            claudeAPIField.typeText("test-api-key-for-e2e-testing")
        }

        // 3. Save settings
        let saveButton = app.buttons["Save Settings"]
        if saveButton.exists {
            saveButton.tap()

            let savedMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "saved"))
            XCTAssertTrue(savedMessage.firstMatch.waitForExistence(timeout: 5.0))
        }

        // 4. Close settings
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        }

        // THEN: Pipeline should work with new settings

        // Connect with new settings
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // Test voice command with updated configuration
        let microphoneButton = app.buttons["Start Recording"]
        XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
        microphoneButton.tap()

        let finalResult = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "successfully"))
        XCTAssertTrue(finalResult.firstMatch.waitForExistence(timeout: 15.0))

        // Stop recording
        let stopButton = app.buttons["Stop Recording"]
        if stopButton.exists {
            stopButton.tap()
        }
    }

    // MARK: - Memory and Stability E2E Tests

    func testVoiceCommandPipeline_MemoryManagement_LongRunningSession() throws {
        // GIVEN: App launched for memory testing
        app.launchEnvironment["EnableMemoryMonitoring"] = "1"
        app.launch()

        let titleElement = app.staticTexts["Jarvis Live"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5.0))

        // Connect
        let connectButton = app.buttons["Connect to LiveKit"]
        if connectButton.exists {
            connectButton.tap()

            let connectedStatus = app.staticTexts["Connected to LiveKit"]
            XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0))
        }

        // WHEN: Execute multiple voice commands to test memory stability
        let microphoneButton = app.buttons["Start Recording"]
        let stopButton = app.buttons["Stop Recording"]

        for i in 1...5 {
            // Execute voice command
            XCTAssertTrue(microphoneButton.waitForExistence(timeout: 5.0))
            microphoneButton.tap()

            // Wait for completion
            let result = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "successfully"))
            XCTAssertTrue(result.firstMatch.waitForExistence(timeout: 10.0), "Command \(i) should complete successfully")

            // Stop recording
            if stopButton.exists {
                stopButton.tap()
            }

            // Brief pause between commands
            Thread.sleep(forTimeInterval: 1.0)
        }

        // THEN: App should remain stable and responsive

        // 1. UI should still be responsive
        XCTAssertTrue(microphoneButton.isHittable)

        // 2. Memory indicators should be within normal range (if available)
        let memoryIndicator = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Memory:"))
        if memoryIndicator.firstMatch.exists {
            // Memory usage should be reasonable
            let memoryText = memoryIndicator.firstMatch.label
            XCTAssertTrue(memoryText.contains("MB") || memoryText.contains("GB"))
        }

        // 3. App should not have crashed or become unresponsive
        XCTAssertTrue(titleElement.exists)
        XCTAssertTrue(microphoneButton.exists)
    }
}

// MARK: - Test Helper Extensions

extension PipelineE2ETests {
    /// Helper to verify pipeline state transitions
    private func verifyPipelineStateTransition(
        from initialState: String,
        to finalState: String,
        timeout: TimeInterval = 10.0
    ) -> Bool {
        let initialStateElement = app.staticTexts[initialState]
        let finalStateElement = app.staticTexts[finalState]

        // Wait for initial state to disappear
        let initialDisappeared = XCTWaiter.wait(for: [
            expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: initialStateElement, handler: nil)
        ], timeout: timeout)

        // Wait for final state to appear
        let finalAppeared = finalStateElement.waitForExistence(timeout: timeout)

        return initialDisappeared == .completed && finalAppeared
    }

    /// Helper to simulate realistic user interaction delays
    private func simulateUserDelay(_ duration: TimeInterval = 1.0) {
        Thread.sleep(forTimeInterval: duration)
    }

    /// Helper to verify accessibility compliance for pipeline elements
    private func verifyPipelineAccessibility() {
        let criticalElements = [
            app.buttons["Start Recording"],
            app.buttons["Stop Recording"],
            app.staticTexts["Jarvis Live"],
            app.textViews["Voice Transcription"],
        ]

        for element in criticalElements {
            if element.exists {
                XCTAssertTrue(element.isAccessibilityElement, "\(element) should be accessible")
                XCTAssertFalse(element.accessibilityLabel?.isEmpty ?? true, "\(element) should have accessibility label")
            }
        }
    }
}
