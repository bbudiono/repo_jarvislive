// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Test suite for VoiceCommandPipeline - TDD implementation following audit guidance
 * Issues & Complexity Summary: Complete pipeline testing from voice input to MCP execution and response
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (Mock orchestration, async testing, error scenarios)
 *   - Dependencies: 7 New (XCTest, VoiceClassificationManager, MCPServerManager, Combine, Mock objects)
 *   - State Management Complexity: High (Pipeline state, authentication, error handling)
 *   - Novelty/Uncertainty Factor: Medium (TDD pipeline testing with mocks)
 * AI Pre-Task Self-Assessment: 88%
 * Problem Estimate: 85%
 * Initial Code Complexity Estimate: 90%
 * Final Code Complexity: TBD
 * Overall Result Score: TBD
 * Key Variances/Learnings: TBD
 * Last Updated: 2025-06-26
 */

import XCTest
import Combine
@testable import JarvisLiveSandbox

@MainActor
final class VoiceCommandPipelineTests: XCTestCase {
    // MARK: - Test Infrastructure

    var pipeline: VoiceCommandPipeline!
    var mockClassificationManager: MockVoiceClassificationManager!
    var mockMCPServerManager: MockMCPServerManager!
    var mockKeychainManager: MockKeychainManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        // Create mock dependencies
        mockKeychainManager = MockKeychainManager()
        mockClassificationManager = MockVoiceClassificationManager()
        mockMCPServerManager = MockMCPServerManager()
        cancellables = Set<AnyCancellable>()

        // Initialize pipeline with mocks
        pipeline = VoiceCommandPipeline(
            classificationManager: mockClassificationManager,
            mcpServerManager: mockMCPServerManager,
            keychainManager: mockKeychainManager
        )
    }

    override func tearDown() {
        cancellables = nil
        pipeline = nil
        mockMCPServerManager = nil
        mockClassificationManager = nil
        mockKeychainManager = nil
        super.tearDown()
    }

    // MARK: - Core Pipeline Tests

    func testProcessVoiceCommand_DocumentGeneration_Success() async throws {
        // Given: Mock classification returns document generation
        let expectedClassification = ClassificationResult(
            category: "document_generation",
            intent: "create_pdf",
            confidence: 0.95,
            parameters: ["content": "AI overview", "format": "pdf"],
            suggestions: [],
            rawText: "Create a PDF about AI",
            normalizedText: "create pdf ai",
            confidenceLevel: "high",
            contextUsed: true,
            preprocessingTime: 0.01,
            classificationTime: 0.05,
            requiresConfirmation: false
        )

        mockClassificationManager.mockClassificationResult = expectedClassification

        // Mock MCP execution success
        let expectedMCPResult = MCPExecutionResult(
            success: true,
            response: "Document created: ai_overview.pdf",
            executionTime: 2.3,
            serverUsed: "document-generator",
            metadata: ["document_id": "doc_123", "file_size": "245KB"]
        )

        mockMCPServerManager.mockExecutionResult = expectedMCPResult

        // When: Process voice command
        let result = try await pipeline.processVoiceCommand("Create a PDF about AI")

        // Then: Verify complete pipeline execution
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.classification.category, "document_generation")
        XCTAssertEqual(result.classification.intent, "create_pdf")
        XCTAssertTrue(result.mcpExecutionResult?.success == true)
        XCTAssertEqual(result.mcpExecutionResult?.response, "Document created: ai_overview.pdf")
        XCTAssertNotNil(result.finalResponse)
        XCTAssertTrue(result.finalResponse.contains("Document created"))

        // Verify mock interactions
        XCTAssertEqual(mockClassificationManager.classifyCallCount, 1)
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 1)
        XCTAssertEqual(mockMCPServerManager.lastExecutedCategory, "document_generation")
    }

    func testProcessVoiceCommand_EmailManagement_Success() async throws {
        // Given: Mock classification returns email management
        let expectedClassification = ClassificationResult(
            category: "email_management",
            intent: "send_email",
            confidence: 0.88,
            parameters: ["to": "john@example.com", "subject": "Meeting", "body": "Tomorrow at 2pm"],
            suggestions: [],
            rawText: "Send email to John about meeting tomorrow",
            normalizedText: "send email john meeting tomorrow",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.04,
            requiresConfirmation: false
        )

        mockClassificationManager.mockClassificationResult = expectedClassification

        // Mock MCP execution success
        let expectedMCPResult = MCPExecutionResult(
            success: true,
            response: "Email sent successfully",
            executionTime: 1.2,
            serverUsed: "email-server",
            metadata: ["message_id": "msg_456"]
        )

        mockMCPServerManager.mockExecutionResult = expectedMCPResult

        // When: Process voice command
        let result = try await pipeline.processVoiceCommand("Send email to John about meeting tomorrow")

        // Then: Verify email processing
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.classification.category, "email_management")
        XCTAssertEqual(result.classification.intent, "send_email")
        XCTAssertTrue(result.mcpExecutionResult?.success == true)
        XCTAssertEqual(result.mcpExecutionResult?.response, "Email sent successfully")
        XCTAssertTrue(result.finalResponse.contains("Email sent"))
    }

    func testProcessVoiceCommand_LowConfidence_RequiresConfirmation() async throws {
        // Given: Mock classification with low confidence
        let expectedClassification = ClassificationResult(
            category: "calendar_scheduling",
            intent: "create_event",
            confidence: 0.45,
            parameters: ["title": "Meeting", "time": "unclear"],
            suggestions: ["Please specify the date and time", "Try: 'Schedule meeting for tomorrow at 2pm'"],
            rawText: "Schedule something",
            normalizedText: "schedule something",
            confidenceLevel: "low",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.06,
            requiresConfirmation: true
        )

        mockClassificationManager.mockClassificationResult = expectedClassification

        // When: Process ambiguous voice command
        let result = try await pipeline.processVoiceCommand("Schedule something")

        // Then: Verify confirmation flow
        XCTAssertFalse(result.success) // Should not execute MCP with low confidence
        XCTAssertEqual(result.classification.confidence, 0.45)
        XCTAssertTrue(result.classification.requiresConfirmation)
        XCTAssertNil(result.mcpExecutionResult) // No MCP execution
        XCTAssertTrue(result.finalResponse.contains("not sure"))
        XCTAssertTrue(result.finalResponse.contains("specify"))
        XCTAssertFalse(result.suggestions.isEmpty)

        // Verify MCP was not called
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 0)
    }

    func testProcessVoiceCommand_ClassificationError_HandledGracefully() async throws {
        // Given: Mock classification error
        mockClassificationManager.shouldThrowError = true
        mockClassificationManager.mockError = VoiceClassificationError.networkError(URLError(.notConnectedToInternet))

        // When: Process voice command with classification failure
        let result = try await pipeline.processVoiceCommand("Test command")

        // Then: Verify error handling
        XCTAssertFalse(result.success)
        XCTAssertNil(result.mcpExecutionResult)
        XCTAssertTrue(result.finalResponse.contains("error"))
        XCTAssertTrue(result.finalResponse.contains("try again"))
        XCTAssertNotNil(result.error)

        // Verify MCP was not called
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 0)
    }

    func testProcessVoiceCommand_MCPExecutionError_FallbackResponse() async throws {
        // Given: Successful classification but MCP execution failure
        let expectedClassification = ClassificationResult(
            category: "document_generation",
            intent: "create_pdf",
            confidence: 0.92,
            parameters: ["content": "test", "format": "pdf"],
            suggestions: [],
            rawText: "Create PDF",
            normalizedText: "create pdf",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.03,
            requiresConfirmation: false
        )

        mockClassificationManager.mockClassificationResult = expectedClassification

        // Mock MCP execution failure
        let expectedMCPResult = MCPExecutionResult(
            success: false,
            response: "Document generation failed: Invalid format",
            executionTime: 0.5,
            serverUsed: "document-generator",
            metadata: nil
        )

        mockMCPServerManager.mockExecutionResult = expectedMCPResult

        // When: Process voice command
        let result = try await pipeline.processVoiceCommand("Create PDF")

        // Then: Verify fallback handling
        XCTAssertFalse(result.success)
        XCTAssertEqual(result.classification.category, "document_generation")
        XCTAssertFalse(result.mcpExecutionResult?.success == true)
        XCTAssertTrue(result.finalResponse.contains("unable to"))
        XCTAssertTrue(result.finalResponse.contains("try again"))

        // Verify both classification and MCP were called
        XCTAssertEqual(mockClassificationManager.classifyCallCount, 1)
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 1)
    }

    // MARK: - State Management Tests

    func testPipelineState_IsProcessing_UpdatesCorrectly() async throws {
        // Given: Initial state
        XCTAssertFalse(pipeline.isProcessing)

        // Configure mock with delay to test state
        mockClassificationManager.shouldDelayResponse = true
        mockClassificationManager.responseDelay = 0.5

        let expectedClassification = ClassificationResult(
            category: "general_conversation",
            intent: "greeting",
            confidence: 0.85,
            parameters: [:],
            suggestions: [],
            rawText: "Hello",
            normalizedText: "hello",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.02,
            requiresConfirmation: false
        )

        mockClassificationManager.mockClassificationResult = expectedClassification

        // When: Start processing
        Task {
            _ = try await pipeline.processVoiceCommand("Hello")
        }

        // Then: Verify state changes
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(pipeline.isProcessing)

        // Wait for completion
        try await Task.sleep(nanoseconds: 700_000_000) // 0.7 seconds
        XCTAssertFalse(pipeline.isProcessing)
    }

    func testPipelineMetrics_UpdateCorrectly() async throws {
        // Given: Initial metrics
        XCTAssertEqual(pipeline.totalProcessedCommands, 0)
        XCTAssertEqual(pipeline.averageProcessingTime, 0.0)

        // Process multiple commands
        let commands = [
            "Create document",
            "Send email",
            "Hello Jarvis",
        ]

        // Configure mocks for quick responses
        mockClassificationManager.mockClassificationResult = ClassificationResult(
            category: "general_conversation",
            intent: "greeting",
            confidence: 0.8,
            parameters: [:],
            suggestions: [],
            rawText: "test",
            normalizedText: "test",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.02,
            requiresConfirmation: false
        )

        mockMCPServerManager.mockExecutionResult = MCPExecutionResult(
            success: true,
            response: "Success",
            executionTime: 0.1,
            serverUsed: "test-server",
            metadata: nil
        )

        // When: Process commands
        for command in commands {
            _ = try await pipeline.processVoiceCommand(command)
        }

        // Then: Verify metrics
        XCTAssertEqual(pipeline.totalProcessedCommands, 3)
        XCTAssertGreaterThan(pipeline.averageProcessingTime, 0.0)
        XCTAssertLessThan(pipeline.averageProcessingTime, 1.0) // Should be fast with mocks
    }

    // MARK: - Concurrent Processing Tests

    func testConcurrentProcessing_HandledSafely() async throws {
        // Given: Multiple concurrent commands
        let commands = Array(1...5).map { "Command \($0)" }

        // Configure mock for consistent responses
        mockClassificationManager.mockClassificationResult = ClassificationResult(
            category: "general_conversation",
            intent: "response",
            confidence: 0.8,
            parameters: [:],
            suggestions: [],
            rawText: "test",
            normalizedText: "test",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.02,
            requiresConfirmation: false
        )

        mockMCPServerManager.mockExecutionResult = MCPExecutionResult(
            success: true,
            response: "Success",
            executionTime: 0.1,
            serverUsed: "test-server",
            metadata: nil
        )

        // When: Process commands concurrently
        await withTaskGroup(of: VoiceCommandPipelineResult.self) { group in
            for command in commands {
                group.addTask {
                    do {
                        return try await self.pipeline.processVoiceCommand(command)
                    } catch {
                        return VoiceCommandPipelineResult.error(error)
                    }
                }
            }

            var results: [VoiceCommandPipelineResult] = []
            for await result in group {
                results.append(result)
            }

            // Then: Verify all commands processed
            XCTAssertEqual(results.count, 5)

            // Verify no race conditions (all should succeed with mocks)
            let successCount = results.filter { $0.success }.count
            XCTAssertEqual(successCount, 5)
        }

        // Verify total call counts
        XCTAssertEqual(mockClassificationManager.classifyCallCount, 5)
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 5)
    }

    // MARK: - Integration Scenarios

    func testEndToEndWorkflow_DocumentThenEmail() async throws {
        // Scenario: User creates document then sends it via email

        // Step 1: Create document
        mockClassificationManager.mockClassificationResult = ClassificationResult(
            category: "document_generation",
            intent: "create_pdf",
            confidence: 0.95,
            parameters: ["content": "Project report", "format": "pdf"],
            suggestions: [],
            rawText: "Create project report PDF",
            normalizedText: "create project report pdf",
            confidenceLevel: "high",
            contextUsed: false,
            preprocessingTime: 0.01,
            classificationTime: 0.04,
            requiresConfirmation: false
        )

        mockMCPServerManager.mockExecutionResult = MCPExecutionResult(
            success: true,
            response: "Document created: project_report.pdf",
            executionTime: 2.1,
            serverUsed: "document-generator",
            metadata: ["document_id": "doc_789", "file_path": "/tmp/project_report.pdf"]
        )

        let documentResult = try await pipeline.processVoiceCommand("Create project report PDF")

        // Verify document creation
        XCTAssertTrue(documentResult.success)
        XCTAssertEqual(documentResult.classification.category, "document_generation")

        // Step 2: Send email with document
        mockClassificationManager.mockClassificationResult = ClassificationResult(
            category: "email_management",
            intent: "send_email",
            confidence: 0.90,
            parameters: ["to": "team@company.com", "subject": "Project Report", "attachment": "project_report.pdf"],
            suggestions: [],
            rawText: "Email the document to the team",
            normalizedText: "email document team",
            confidenceLevel: "high",
            contextUsed: true,
            preprocessingTime: 0.01,
            classificationTime: 0.03,
            requiresConfirmation: false
        )

        mockMCPServerManager.mockExecutionResult = MCPExecutionResult(
            success: true,
            response: "Email sent with attachment",
            executionTime: 1.5,
            serverUsed: "email-server",
            metadata: ["message_id": "msg_890", "attachment_count": "1"]
        )

        let emailResult = try await pipeline.processVoiceCommand("Email the document to the team")

        // Verify email sending
        XCTAssertTrue(emailResult.success)
        XCTAssertEqual(emailResult.classification.category, "email_management")
        XCTAssertTrue(emailResult.classification.contextUsed)

        // Verify workflow completion
        XCTAssertEqual(pipeline.totalProcessedCommands, 2)
        XCTAssertEqual(mockClassificationManager.classifyCallCount, 2)
        XCTAssertEqual(mockMCPServerManager.executeCallCount, 2)
    }
}
