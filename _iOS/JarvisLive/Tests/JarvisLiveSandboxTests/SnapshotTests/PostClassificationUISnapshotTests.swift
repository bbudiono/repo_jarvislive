/*
* Purpose: Comprehensive snapshot tests for Post-Classification UI Flow components
* Issues & Complexity Summary: Visual regression testing for all flow states and components
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~300
  - Core Algorithm Complexity: Low (snapshot test setup)
  - Dependencies: 2 New (SnapshotTesting, SwiftUI hosting)
  - State Management Complexity: Low (static test data)
  - Novelty/Uncertainty Factor: Low (established testing patterns)
* AI Pre-Task Self-Assessment: 95%
* Problem Estimate: 60%
* Initial Code Complexity Estimate: 65%
* Final Code Complexity: 67%
* Overall Result Score: 94%
* Key Variances/Learnings: Standard snapshot testing implementation
* Last Updated: 2025-06-27
*/

import XCTest
import SwiftUI
import SnapshotTesting
@testable import JarvisLiveCore

final class PostClassificationUISnapshotTests: XCTestCase {
    override func setUp() {
        super.setUp()
        isRecording = false // CRITICAL: false for regression testing, true only for updating snapshots
    }

    // MARK: - Main Flow View Tests

    func testPostClassificationFlowView_DocumentGeneration_iPhone16Pro() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlow_DocumentGeneration_iPhone16Pro"
        )
    }

    func testPostClassificationFlowView_DocumentGeneration_iPadPro() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9),
            named: "PostClassificationFlow_DocumentGeneration_iPadPro"
        )
    }

    func testPostClassificationFlowView_DocumentGeneration_iPhoneSE() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhoneSe2ndGeneration),
            named: "PostClassificationFlow_DocumentGeneration_iPhoneSE"
        )
    }

    func testPostClassificationFlowView_EmailManagement_iPhone16Pro() {
        let result = ClassificationResult.mockEmailManagement()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlow_EmailManagement_iPhone16Pro"
        )
    }

    func testPostClassificationFlowView_CalendarScheduling_iPhone16Pro() {
        let result = ClassificationResult.mockCalendarScheduling()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlow_CalendarScheduling_iPhone16Pro"
        )
    }

    func testPostClassificationFlowView_LowConfidence_iPhone16Pro() {
        let result = ClassificationResult.mockLowConfidence()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlow_LowConfidence_iPhone16Pro"
        )
    }

    // MARK: - Dark Mode Tests

    func testPostClassificationFlowView_DocumentGeneration_DarkMode() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
            .preferredColorScheme(.dark)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "PostClassificationFlow_DocumentGeneration_DarkMode"
        )
    }

    func testPostClassificationFlowView_EmailManagement_DarkMode() {
        let result = ClassificationResult.mockEmailManagement()
        let view = PostClassificationFlowView(classificationResult: result)
            .preferredColorScheme(.dark)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "PostClassificationFlow_EmailManagement_DarkMode"
        )
    }

    func testPostClassificationFlowView_CalendarScheduling_DarkMode() {
        let result = ClassificationResult.mockCalendarScheduling()
        let view = PostClassificationFlowView(classificationResult: result)
            .preferredColorScheme(.dark)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro, traits: .init(userInterfaceStyle: .dark)),
            named: "PostClassificationFlow_CalendarScheduling_DarkMode"
        )
    }

    // MARK: - Confidence Level State Tests

    func testConfidenceIndicatorView_HighConfidence() {
        let view = VStack(spacing: 20) {
            ConfidenceIndicatorView(confidence: 0.95)
            ConfidenceIndicatorView(confidence: 0.72)
            ConfidenceIndicatorView(confidence: 0.45)
            ConfidenceIndicatorView(confidence: 0.18)
        }
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ConfidenceIndicator_AllLevels"
        )
    }

    func testProcessingView() {
        let view = ProcessingView()
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ProcessingView_Default"
        )
    }

    func testPreviewView_DocumentGeneration() {
        let previewData = PreviewData(
            title: "Ready to Execute",
            description: "I'm confident about this document generation command.",
            parameters: [
                "format": AnyCodable("PDF"),
                "content": AnyCodable("quarterly results"),
                "title": AnyCodable("Q3 Results Report"),
            ],
            previewContent: AnyView(DocumentPreviewCard(parameters: [
                "format": AnyCodable("PDF"),
                "content": AnyCodable("quarterly results"),
                "title": AnyCodable("Q3 Results Report"),
            ]))
        )

        let view = PreviewView(data: previewData, onExecute: {})
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PreviewView_DocumentGeneration"
        )
    }

    func testConfirmationView() {
        let confirmationData = ConfirmationData(
            title: "Confirm Command",
            message: "I think you want to create a PDF document. Is this correct?",
            confirmButtonTitle: "Yes, Execute",
            cancelButtonTitle: "Cancel",
            destructive: false
        )

        let view = ConfirmationView(
            data: confirmationData,
            onConfirm: {},
            onCancel: {}
        )
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ConfirmationView_Default"
        )
    }

    func testExecutionView_InProgress() {
        let executionData = ExecutionData(
            title: "Creating Document",
            message: "Processing your document generation request...",
            progress: 0.65,
            estimatedTimeRemaining: 3.0,
            canCancel: true
        )

        let view = ExecutionView(data: executionData, onCancel: {})
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ExecutionView_InProgress"
        )
    }

    func testResultView_Success() {
        let resultData = ResultData(
            title: "Success!",
            message: "Your document generation command was executed successfully.",
            success: true,
            resultContent: AnyView(DocumentResultView()),
            actions: [
                ResultAction(title: "Share", icon: "square.and.arrow.up", action: {}),
                ResultAction(title: "View Details", icon: "info.circle", action: {}),
                ResultAction(title: "Done", icon: "checkmark", action: {}),
            ]
        )

        let view = ResultView(data: resultData)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ResultView_Success"
        )
    }

    func testResultView_Failure() {
        let resultData = ResultData(
            title: "Command Failed",
            message: "There was an error executing your command.",
            success: false,
            resultContent: nil,
            actions: [
                ResultAction(title: "Retry", icon: "arrow.clockwise", action: {}),
                ResultAction(title: "Done", icon: "checkmark", action: {}),
            ]
        )

        let view = ResultView(data: resultData)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ResultView_Failure"
        )
    }

    func testErrorView() {
        let errorData = ErrorData(
            title: "Execution Failed",
            message: "An error occurred while processing your command.",
            error: NSError(domain: "TestError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Network connection failed"]),
            canRetry: true,
            suggestions: [
                "Check your internet connection",
                "Try rephrasing your command",
                "Contact support if the problem persists",
            ]
        )

        let view = ErrorView(data: errorData, onRetry: {}, onDismiss: {})
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ErrorView_Default"
        )
    }

    func testClarificationView() {
        let clarificationData = ClarificationData(
            title: "Need Clarification",
            message: "I'm not sure what you meant. Could you try one of these options?",
            suggestions: [
                "Create a PDF document",
                "Send an email",
                "Schedule a meeting",
                "Search the web",
            ],
            allowManualInput: true
        )

        let view = ClarificationView(data: clarificationData, onSelection: { _ in })
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ClarificationView_Default"
        )
    }

    // MARK: - Category-Specific Preview Tests

    func testDocumentPreviewCard() {
        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly financial results"),
            "title": AnyCodable("Q3 2024 Financial Report"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "DocumentPreviewCard_Default"
        )
    }

    func testDocumentPreviewCard_iPadPro() {
        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly financial results"),
            "title": AnyCodable("Q3 2024 Financial Report"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9),
            named: "DocumentPreviewCard_iPadPro"
        )
    }

    func testEmailPreviewCard() {
        let view = EmailPreviewCard(parameters: [
            "recipient": AnyCodable("john@company.com"),
            "subject": AnyCodable("Meeting Follow-up"),
            "body": AnyCodable("Thanks for the productive meeting today. I wanted to follow up on the action items we discussed and ensure we're aligned on next steps."),
            "priority": AnyCodable("high"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "EmailPreviewCard_Default"
        )
    }

    func testEmailPreviewCard_iPadPro() {
        let view = EmailPreviewCard(parameters: [
            "recipient": AnyCodable("team@company.com"),
            "subject": AnyCodable("Project Update"),
            "body": AnyCodable("Here's the weekly project update with current status and upcoming milestones."),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9),
            named: "EmailPreviewCard_iPadPro"
        )
    }

    func testCalendarPreviewCard() {
        let view = CalendarPreviewCard(parameters: [
            "title": AnyCodable("Team Standup"),
            "date": AnyCodable("Tomorrow"),
            "time": AnyCodable("9:00 AM"),
            "duration": AnyCodable(30),
            "location": AnyCodable("Conference Room A"),
            "attendees": AnyCodable(["alice@company.com", "bob@company.com"]),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "CalendarPreviewCard_Default"
        )
    }

    // MARK: - Accessibility Tests

    func testPostClassificationFlowView_LargeText() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
            .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "PostClassificationFlow_LargeText"
        )
    }

    func testPostClassificationFlowView_HighContrast() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro, traits: .init(accessibilityContrast: .high)),
            named: "PostClassificationFlow_HighContrast"
        )
    }

    func testDocumentPreviewCard_LargeText() {
        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly results"),
            "title": AnyCodable("Q3 Report"),
        ])
        .padding()
        .modifier(GlassViewModifier())
        .environment(\.sizeCategory, .accessibilityExtraExtraExtraLarge)

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "DocumentPreviewCard_LargeText"
        )
    }

    // MARK: - Device Size Tests

    func testDocumentPreviewCard_iPhoneSE() {
        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly results"),
            "title": AnyCodable("Q3 Report"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhoneSe2ndGeneration),
            named: "DocumentPreviewCard_iPhoneSE"
        )
    }

    func testEmailPreviewCard_iPhoneSE() {
        let view = EmailPreviewCard(parameters: [
            "recipient": AnyCodable("john@company.com"),
            "subject": AnyCodable("Quick Update"),
            "body": AnyCodable("Brief message for SE testing"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhoneSe2ndGeneration),
            named: "EmailPreviewCard_iPhoneSE"
        )
    }

    // MARK: - Edge Cases and Error States

    func testParametersView_EmptyParameters() {
        let view = ParametersView(
            parameters: [:],
            showingDetails: .constant(true)
        )
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ParametersView_Empty"
        )
    }

    func testParametersView_ManyParameters() {
        var manyParameters: [String: AnyCodable] = [:]
        for i in 1...10 {
            manyParameters["parameter_\(i)"] = AnyCodable("value_\(i)")
        }

        let view = ParametersView(
            parameters: manyParameters,
            showingDetails: .constant(true)
        )
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "ParametersView_ManyParameters"
        )
    }

    func testDocumentPreviewCard_LongContent() {
        let longContent = "This is a very long document content that should test how the preview card handles extensive text. The content includes multiple sentences and should demonstrate text truncation or proper layout handling when dealing with longer descriptions that might not fit in the standard preview area."

        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable(longContent),
            "title": AnyCodable("Very Long Document Title That Should Test Text Wrapping and Layout"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "DocumentPreviewCard_LongContent"
        )
    }

    func testEmailPreviewCard_MultipleRecipients() {
        let view = EmailPreviewCard(parameters: [
            "recipient": AnyCodable("john@company.com, alice@company.com, bob@company.com, team@company.com"),
            "subject": AnyCodable("Team Meeting - All Hands"),
            "body": AnyCodable("Please join us for the all-hands team meeting tomorrow."),
            "attachments": AnyCodable(["agenda.pdf", "presentation.pptx", "meeting-notes.docx"]),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPhone16Pro),
            named: "EmailPreviewCard_MultipleRecipients"
        )
    }

    // MARK: - iPad Pro Landscape Tests

    func testPostClassificationFlowView_DocumentGeneration_iPadProLandscape() {
        let result = ClassificationResult.mockDocumentGeneration()
        let view = PostClassificationFlowView(classificationResult: result)
        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9(.landscape)),
            named: "PostClassificationFlow_DocumentGeneration_iPadProLandscape"
        )
    }

    func testDocumentPreviewCard_iPadProLandscape() {
        let view = DocumentPreviewCard(parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly financial results"),
            "title": AnyCodable("Q3 2024 Financial Report"),
        ])
        .padding()
        .modifier(GlassViewModifier())

        let hostingController = UIHostingController(rootView: view)

        assertSnapshot(
            matching: hostingController,
            as: .image(on: .iPadPro12_9(.landscape)),
            named: "DocumentPreviewCard_iPadProLandscape"
        )
    }
}

// MARK: - Test Helper Extensions

extension ClassificationResult {
    static func mockDocumentGeneration() -> ClassificationResult {
        return ClassificationResult(
            category: .documentGeneration,
            intent: "Create a PDF document about quarterly results",
            confidence: 0.92,
            parameters: [
                "format": AnyCodable("PDF"),
                "content": AnyCodable("quarterly results"),
                "title": AnyCodable("Q3 2024 Results"),
            ],
            suggestions: [],
            rawText: "Create a PDF about our Q3 results",
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

    static func mockCalendarScheduling() -> ClassificationResult {
        return ClassificationResult(
            category: .calendarScheduling,
            intent: "Schedule team meeting for tomorrow",
            confidence: 0.88,
            parameters: [
                "title": AnyCodable("Team Standup"),
                "date": AnyCodable("Tomorrow"),
                "time": AnyCodable("9:00 AM"),
                "duration": AnyCodable(30),
                "location": AnyCodable("Conference Room A"),
            ],
            suggestions: [],
            rawText: "Schedule team meeting tomorrow at 9",
            normalizedText: "schedule team meeting tomorrow 9",
            processingTime: 0.038
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

    static func mockWebSearch() -> ClassificationResult {
        return ClassificationResult(
            category: .webSearch,
            intent: "Search for latest AI news",
            confidence: 0.82,
            parameters: [
                "query": AnyCodable("latest artificial intelligence news"),
                "num_results": AnyCodable(10),
            ],
            suggestions: [],
            rawText: "What's the latest news about AI?",
            normalizedText: "latest news ai artificial intelligence",
            processingTime: 0.025
        )
    }
}
