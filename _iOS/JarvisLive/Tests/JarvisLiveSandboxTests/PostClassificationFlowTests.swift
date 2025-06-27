/*
* Purpose: Comprehensive unit tests for Post-Classification UI Flow
* Issues & Complexity Summary: Testing flow states, UI transitions, and category-specific behaviors
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~400
  - Core Algorithm Complexity: Medium (async testing, state transitions)
  - Dependencies: 3 New (XCTest async, SwiftUI testing, mock data)
  - State Management Complexity: High (multiple flow states and transitions)
  - Novelty/Uncertainty Factor: Low (standard testing patterns)
* AI Pre-Task Self-Assessment: 92%
* Problem Estimate: 70%
* Initial Code Complexity Estimate: 75%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
*/

import XCTest
import SwiftUI
@testable import JarvisLiveCore

@MainActor
final class PostClassificationFlowTests: XCTestCase {
    var flowManager: PostClassificationFlowManager!

    override func setUp() {
        super.setUp()
        flowManager = PostClassificationFlowManager()
    }

    override func tearDown() {
        flowManager = nil
        super.tearDown()
    }

    // MARK: - Classification Result Tests

    func testClassificationResultConfidenceLevels() {
        // High confidence
        let highConfidenceResult = ClassificationResult(
            category: .documentGeneration,
            intent: "Create PDF document",
            confidence: 0.95,
            parameters: [:],
            suggestions: [],
            rawText: "Create a PDF",
            normalizedText: "create pdf",
            processingTime: 0.05
        )
        XCTAssertEqual(highConfidenceResult.confidenceLevel, .high)
        XCTAssertFalse(highConfidenceResult.requiresConfirmation)

        // Medium confidence
        let mediumConfidenceResult = ClassificationResult(
            category: .emailManagement,
            intent: "Send email",
            confidence: 0.7,
            parameters: [:],
            suggestions: [],
            rawText: "Send email",
            normalizedText: "send email",
            processingTime: 0.03
        )
        XCTAssertEqual(mediumConfidenceResult.confidenceLevel, .medium)
        XCTAssertTrue(mediumConfidenceResult.requiresConfirmation)

        // Low confidence
        let lowConfidenceResult = ClassificationResult(
            category: .unknown,
            intent: "Unknown",
            confidence: 0.4,
            parameters: [:],
            suggestions: ["Try again", "Be more specific"],
            rawText: "Do something",
            normalizedText: "do something",
            processingTime: 0.02
        )
        XCTAssertEqual(lowConfidenceResult.confidenceLevel, .low)
        XCTAssertTrue(lowConfidenceResult.requiresConfirmation)

        // Very low confidence
        let veryLowConfidenceResult = ClassificationResult(
            category: .unknown,
            intent: "Unknown",
            confidence: 0.2,
            parameters: [:],
            suggestions: ["Please clarify"],
            rawText: "Hmm",
            normalizedText: "hmm",
            processingTime: 0.01
        )
        XCTAssertEqual(veryLowConfidenceResult.confidenceLevel, .veryLow)
        XCTAssertTrue(veryLowConfidenceResult.requiresConfirmation)
    }

    func testCommandCategoryProperties() {
        // Test display names
        XCTAssertEqual(CommandCategory.documentGeneration.displayName, "Document Generation")
        XCTAssertEqual(CommandCategory.emailManagement.displayName, "Email Management")
        XCTAssertEqual(CommandCategory.generalConversation.displayName, "Conversation")

        // Test icons
        XCTAssertEqual(CommandCategory.documentGeneration.icon, "doc.text")
        XCTAssertEqual(CommandCategory.emailManagement.icon, "envelope")
        XCTAssertEqual(CommandCategory.calendarScheduling.icon, "calendar")

        // Test colors
        XCTAssertEqual(CommandCategory.documentGeneration.color, .green)
        XCTAssertEqual(CommandCategory.emailManagement.color, .orange)
        XCTAssertEqual(CommandCategory.webSearch.color, .teal)
    }

    // MARK: - Flow Manager Tests

    func testFlowManagerInitialState() {
        XCTAssertEqual(flowManager.currentState, .processing)
        XCTAssertFalse(flowManager.isPresented)
    }

    func testHighConfidenceFlowProgression() async {
        let highConfidenceResult = createMockClassificationResult(confidence: 0.9)

        // Start processing
        flowManager.processClassification(highConfidenceResult)
        XCTAssertTrue(flowManager.isPresented)
        XCTAssertEqual(flowManager.currentState, .processing)

        // Wait for state transition
        await waitForStateChange(to: .preview, timeout: 2.0)

        // Should go directly to preview for high confidence
        if case .preview(let data) = flowManager.currentState {
            XCTAssertEqual(data.title, "Ready to Execute")
            XCTAssertTrue(data.description.contains("confident"))
        } else {
            XCTFail("Expected preview state for high confidence result")
        }
    }

    func testMediumConfidenceFlowProgression() async {
        let mediumConfidenceResult = createMockClassificationResult(confidence: 0.6)

        flowManager.processClassification(mediumConfidenceResult)
        await waitForStateChange(to: .confirmation, timeout: 2.0)

        // Should go to confirmation for medium confidence
        if case .confirmation(let data) = flowManager.currentState {
            XCTAssertEqual(data.title, "Confirm Command")
            XCTAssertTrue(data.message.contains("think you want"))
            XCTAssertEqual(data.confirmButtonTitle, "Yes, Execute")
            XCTAssertEqual(data.cancelButtonTitle, "Cancel")
        } else {
            XCTFail("Expected confirmation state for medium confidence result")
        }
    }

    func testLowConfidenceFlowProgression() async {
        let lowConfidenceResult = createMockClassificationResult(
            confidence: 0.3,
            suggestions: ["Try this", "Or this", "Maybe this"]
        )

        flowManager.processClassification(lowConfidenceResult)
        await waitForStateChange(to: .clarification, timeout: 2.0)

        // Should go to clarification for low confidence
        if case .clarification(let data) = flowManager.currentState {
            XCTAssertEqual(data.title, "Need Clarification")
            XCTAssertTrue(data.message.contains("not sure"))
            XCTAssertEqual(data.suggestions.count, 3)
            XCTAssertTrue(data.allowManualInput)
        } else {
            XCTFail("Expected clarification state for low confidence result")
        }
    }

    func testCommandExecution() async {
        let result = createMockClassificationResult(confidence: 0.9)
        flowManager.processClassification(result)

        await waitForStateChange(to: .preview, timeout: 2.0)

        // Execute command
        flowManager.executeCommand()

        // Should transition to execution state
        if case .execution(let data) = flowManager.currentState {
            XCTAssertEqual(data.title, "Executing Command")
            XCTAssertTrue(data.message.contains("Processing"))
            XCTAssertEqual(data.progress, 0.0)
            XCTAssertTrue(data.canCancel)
        } else {
            XCTFail("Expected execution state after executeCommand")
        }

        // Wait for execution to complete (simulated)
        await waitForExecutionCompletion(timeout: 10.0)

        // Should end in either result or error state
        switch flowManager.currentState {
        case .result(let data):
            XCTAssertNotNil(data.title)
            XCTAssertNotNil(data.message)
            XCTAssertFalse(data.actions.isEmpty)
        case .error(let data):
            XCTAssertEqual(data.title, "Execution Failed")
            XCTAssertTrue(data.canRetry)
        default:
            XCTFail("Expected result or error state after execution")
        }
    }

    func testRetryCommand() async {
        let result = createMockClassificationResult(confidence: 0.9)
        flowManager.processClassification(result)

        await waitForStateChange(to: .preview, timeout: 2.0)

        // Force execution to trigger retry scenario
        flowManager.executeCommand()
        await waitForExecutionCompletion(timeout: 10.0)

        // If we're in error state, test retry
        if case .error = flowManager.currentState {
            flowManager.retryCommand()

            // Should go back to execution state
            if case .execution = flowManager.currentState {
                XCTAssertTrue(true) // Retry worked
            } else {
                XCTFail("Expected execution state after retry")
            }
        }
    }

    func testDismissFlow() {
        let result = createMockClassificationResult(confidence: 0.9)
        flowManager.processClassification(result)

        XCTAssertTrue(flowManager.isPresented)

        flowManager.dismiss()

        XCTAssertFalse(flowManager.isPresented)
        XCTAssertEqual(flowManager.currentState, .processing)
    }

    // MARK: - Category-Specific Preview Tests

    func testDocumentGenerationPreviewData() async {
        let documentResult = ClassificationResult(
            category: .documentGeneration,
            intent: "Create PDF document",
            confidence: 0.9,
            parameters: [
                "format": AnyCodable("PDF"),
                "content": AnyCodable("quarterly results"),
                "title": AnyCodable("Q3 Report"),
            ],
            suggestions: [],
            rawText: "Create a PDF report",
            normalizedText: "create pdf report",
            processingTime: 0.05
        )

        flowManager.processClassification(documentResult)
        await waitForStateChange(to: .preview, timeout: 2.0)

        if case .preview(let data) = flowManager.currentState {
            XCTAssertNotNil(data.previewContent)
            XCTAssertEqual(data.parameters.count, 3)
            XCTAssertEqual(data.parameters["format"]?.value as? String, "PDF")
        } else {
            XCTFail("Expected preview state with document-specific content")
        }
    }

    func testEmailManagementPreviewData() async {
        let emailResult = ClassificationResult(
            category: .emailManagement,
            intent: "Send email",
            confidence: 0.8,
            parameters: [
                "recipient": AnyCodable("john@example.com"),
                "subject": AnyCodable("Meeting follow-up"),
                "body": AnyCodable("Thanks for the meeting"),
            ],
            suggestions: [],
            rawText: "Send email to John",
            normalizedText: "send email john",
            processingTime: 0.03
        )

        flowManager.processClassification(emailResult)
        await waitForStateChange(to: .preview, timeout: 2.0)

        if case .preview(let data) = flowManager.currentState {
            XCTAssertNotNil(data.previewContent)
            XCTAssertEqual(data.parameters.count, 3)
            XCTAssertEqual(data.parameters["recipient"]?.value as? String, "john@example.com")
        } else {
            XCTFail("Expected preview state with email-specific content")
        }
    }

    func testCalendarSchedulingPreviewData() async {
        let calendarResult = ClassificationResult(
            category: .calendarScheduling,
            intent: "Schedule meeting",
            confidence: 0.85,
            parameters: [
                "title": AnyCodable("Team standup"),
                "date": AnyCodable("Tomorrow"),
                "time": AnyCodable("9:00 AM"),
                "duration": AnyCodable(30),
            ],
            suggestions: [],
            rawText: "Schedule team meeting",
            normalizedText: "schedule team meeting",
            processingTime: 0.04
        )

        flowManager.processClassification(calendarResult)
        await waitForStateChange(to: .preview, timeout: 2.0)

        if case .preview(let data) = flowManager.currentState {
            XCTAssertNotNil(data.previewContent)
            XCTAssertEqual(data.parameters.count, 4)
            XCTAssertEqual(data.parameters["title"]?.value as? String, "Team standup")
        } else {
            XCTFail("Expected preview state with calendar-specific content")
        }
    }

    // MARK: - Error Handling Tests

    func testFallbackSuggestions() async {
        let unknownResult = ClassificationResult(
            category: .unknown,
            intent: "Unknown",
            confidence: 0.2,
            parameters: [:],
            suggestions: [], // Empty suggestions to test fallback
            rawText: "Do something unclear",
            normalizedText: "do something unclear",
            processingTime: 0.01
        )

        flowManager.processClassification(unknownResult)
        await waitForStateChange(to: .clarification, timeout: 2.0)

        if case .clarification(let data) = flowManager.currentState {
            // Should have fallback suggestions
            XCTAssertFalse(data.suggestions.isEmpty)
            XCTAssertTrue(data.suggestions.contains("Try saying it differently") ||
                         data.suggestions.contains("Be more specific") ||
                         data.suggestions.contains("Use keywords"))
        } else {
            XCTFail("Expected clarification state with fallback suggestions")
        }
    }

    func testCategorySpecificFallbackSuggestions() async {
        let documentResult = ClassificationResult(
            category: .documentGeneration,
            intent: "Create document",
            confidence: 0.2,
            parameters: [:],
            suggestions: [], // Empty to test category-specific fallbacks
            rawText: "Make something",
            normalizedText: "make something",
            processingTime: 0.01
        )

        flowManager.processClassification(documentResult)
        await waitForStateChange(to: .clarification, timeout: 2.0)

        if case .clarification(let data) = flowManager.currentState {
            // Should have document-specific suggestions
            XCTAssertTrue(data.suggestions.contains("Create a PDF document") ||
                         data.suggestions.contains("Generate a Word document") ||
                         data.suggestions.contains("Make a presentation"))
        } else {
            XCTFail("Expected clarification state with document-specific suggestions")
        }
    }

    // MARK: - Performance Tests

    func testFlowTransitionPerformance() {
        measure {
            let result = createMockClassificationResult(confidence: 0.9)
            flowManager.processClassification(result)

            // Simulate typical user interaction timing
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.flowManager.executeCommand()
            }
        }
    }

    func testLargeParameterSetPerformance() {
        // Create result with many parameters
        var largeParameters: [String: AnyCodable] = [:]
        for i in 0..<100 {
            largeParameters["param_\(i)"] = AnyCodable("value_\(i)")
        }

        measure {
            let result = ClassificationResult(
                category: .documentGeneration,
                intent: "Create complex document",
                confidence: 0.8,
                parameters: largeParameters,
                suggestions: [],
                rawText: "Create complex document",
                normalizedText: "create complex document",
                processingTime: 0.1
            )

            flowManager.processClassification(result)
        }
    }

    // MARK: - Helper Methods

    private func createMockClassificationResult(
        category: CommandCategory = .documentGeneration,
        confidence: Double,
        suggestions: [String] = []
    ) -> ClassificationResult {
        return ClassificationResult(
            category: category,
            intent: "Mock intent for \(category.displayName)",
            confidence: confidence,
            parameters: [
                "test_param": AnyCodable("test_value")
            ],
            suggestions: suggestions,
            rawText: "Mock voice command",
            normalizedText: "mock voice command",
            processingTime: 0.05
        )
    }

    private func waitForStateChange(to expectedState: PostClassificationFlowState, timeout: TimeInterval) async {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            if flowManager.currentState == expectedState {
                return
            }

            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }

        XCTFail("Timeout waiting for state change to \(expectedState)")
    }

    private func waitForExecutionCompletion(timeout: TimeInterval) async {
        let startTime = Date()

        while Date().timeIntervalSince(startTime) < timeout {
            switch flowManager.currentState {
            case .result, .error:
                return
            default:
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            }
        }

        XCTFail("Timeout waiting for execution completion")
    }
}

// MARK: - PostClassificationFlowState Equatable Extension

extension PostClassificationFlowState {
    static func == (lhs: PostClassificationFlowState, rhs: PostClassificationFlowState) -> Bool {
        switch (lhs, rhs) {
        case (.processing, .processing),
             (.preview, .preview),
             (.confirmation, .confirmation),
             (.execution, .execution),
             (.result, .result),
             (.error, .error),
             (.clarification, .clarification):
            return true
        default:
            return false
        }
    }
}

// MARK: - Mock Data Extensions

extension ClassificationResult {
    static func mockDocumentGeneration() -> ClassificationResult {
        return ClassificationResult(
            category: .documentGeneration,
            intent: "Create PDF document about quarterly results",
            confidence: 0.92,
            parameters: [
                "format": AnyCodable("PDF"),
                "content": AnyCodable("quarterly results"),
                "title": AnyCodable("Q3 2024 Results"),
            ],
            suggestions: [],
            rawText: "Create a PDF about Q3 results",
            normalizedText: "create pdf quarterly results",
            processingTime: 0.045
        )
    }

    static func mockEmailManagement() -> ClassificationResult {
        return ClassificationResult(
            category: .emailManagement,
            intent: "Send email to team about meeting",
            confidence: 0.78,
            parameters: [
                "recipient": AnyCodable("team@company.com"),
                "subject": AnyCodable("Meeting Tomorrow"),
                "body": AnyCodable("Don't forget about our meeting tomorrow at 2 PM"),
            ],
            suggestions: [],
            rawText: "Send email to team about tomorrow's meeting",
            normalizedText: "send email team meeting tomorrow",
            processingTime: 0.032
        )
    }

    static func mockLowConfidence() -> ClassificationResult {
        return ClassificationResult(
            category: .unknown,
            intent: "Unknown command",
            confidence: 0.25,
            parameters: [:],
            suggestions: [
                "Create a document",
                "Send an email",
                "Schedule a meeting",
                "Search the web",
            ],
            rawText: "Do that thing",
            normalizedText: "do thing",
            processingTime: 0.018
        )
    }
}
