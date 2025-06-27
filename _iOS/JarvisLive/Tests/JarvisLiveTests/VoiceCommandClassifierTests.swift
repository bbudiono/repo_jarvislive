// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Comprehensive test suite for VoiceCommandClassifier functionality
 * Issues & Complexity Summary: Testing voice command classification patterns, parameter extraction, confidence scoring, and MCP routing
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~300
 *   - Core Algorithm Complexity: Medium (Test case design and validation)
 *   - Dependencies: 3 New (XCTest, VoiceCommandClassifier, Foundation)
 *   - State Management Complexity: Low (Test state management)
 *   - Novelty/Uncertainty Factor: Medium (NLP testing patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 70%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 72%
 * Justification for Estimates: Comprehensive testing requires good coverage of NLP edge cases
 * Final Code Complexity (Actual %): 74%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: NLP testing requires diverse test cases to ensure robust classification
 * Last Updated: 2025-06-26
 */

import XCTest
@testable import JarvisLiveSandbox

@MainActor
final class VoiceCommandClassifierTests: XCTestCase {
    var classifier: VoiceCommandClassifier!

    override func setUp() async throws {
        try await super.setUp()
        classifier = VoiceCommandClassifier()

        // Wait for initialization
        while !classifier.isInitialized {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
    }

    override func tearDown() async throws {
        classifier = nil
        try await super.tearDown()
    }

    // MARK: - Document Generation Tests

    func testDocumentGenerationClassification() async throws {
        let testCases = [
            "Generate a PDF document about project status",
            "Create a document with the meeting notes",
            "Write a report in DOCX format",
            "Generate document containing the quarterly results",
            "Make a PDF with the user manual",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .generateDocument, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "document-generator")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")

            // Verify parameter extraction
            if testCase.contains("PDF") || testCase.contains("pdf") {
                XCTAssertEqual(classification.extractedParameters["format"] as? String, "pdf")
            }
            if testCase.contains("DOCX") || testCase.contains("docx") {
                XCTAssertEqual(classification.extractedParameters["format"] as? String, "docx")
            }
        }
    }

    func testDocumentParameterExtraction() async throws {
        let command = "Generate a PDF document about the Q4 financial results in PDF format"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .generateDocument)
        XCTAssertNotNil(classification.extractedParameters["content"])
        XCTAssertEqual(classification.extractedParameters["format"] as? String, "pdf")
    }

    // MARK: - Email Tests

    func testEmailClassification() async throws {
        let testCases = [
            "Send an email to john@example.com",
            "Compose email to team@company.com with subject Meeting Update",
            "Write email to sarah.jones@test.com saying thanks for the meeting",
            "Send message to admin@website.org",
            "Email someone about the project deadline",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .sendEmail, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "email-server")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
        }
    }

    func testEmailParameterExtraction() async throws {
        let command = "Send an email to test@example.com with subject Project Update saying the project is on track"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .sendEmail)
        XCTAssertEqual(classification.extractedParameters["recipient"] as? String, "test@example.com")
        XCTAssertNotNil(classification.extractedParameters["subject"])
        XCTAssertNotNil(classification.extractedParameters["body"])
    }

    // MARK: - Calendar Tests

    func testCalendarClassification() async throws {
        let testCases = [
            "Schedule a meeting for tomorrow at 2 PM",
            "Create calendar event for team standup",
            "Book appointment with Dr. Smith",
            "Plan meeting with the development team",
            "Set up event for next Monday",
            "Add to calendar: lunch with client",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .scheduleCalendar, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "calendar-server")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
        }
    }

    func testCalendarParameterExtraction() async throws {
        let command = "Schedule a meeting about project review for tomorrow at 3 PM"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .scheduleCalendar)
        XCTAssertNotNil(classification.extractedParameters["title"])
        XCTAssertNotNil(classification.extractedParameters["datetime"])
    }

    // MARK: - Search Tests

    func testSearchClassification() async throws {
        let testCases = [
            "Search for information about machine learning",
            "Find articles on climate change",
            "Look up the latest news about technology",
            "Research Swift programming tutorials",
            "Find results for iOS development",
            "Search the internet for restaurant reviews",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .performSearch, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "search-server")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")

            // Verify query extraction
            XCTAssertNotNil(classification.extractedParameters["query"])
        }
    }

    // MARK: - Weather Tests

    func testWeatherClassification() async throws {
        let testCases = [
            "What's the weather like today?",
            "Weather forecast for tomorrow",
            "How's the weather in New York?",
            "Will it rain this afternoon?",
            "Temperature for this week",
            "Weather update for San Francisco",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .weatherQuery, "Failed to classify: '\(testCase)'")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
        }
    }

    func testWeatherParameterExtraction() async throws {
        let command = "What's the weather forecast for Los Angeles tomorrow?"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .weatherQuery)
        XCTAssertNotNil(classification.extractedParameters["location"])
        XCTAssertNotNil(classification.extractedParameters["timeframe"])
    }

    // MARK: - News Tests

    func testNewsClassification() async throws {
        let testCases = [
            "Latest news about technology",
            "Current events today",
            "What's happening in the world?",
            "News update on politics",
            "Headlines for today",
            "Recent news about sports",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .newsQuery, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "search-server")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
        }
    }

    // MARK: - Calculation Tests

    func testCalculationClassification() async throws {
        let testCases = [
            "Calculate 15 plus 27",
            "What is 100 minus 45?",
            "Compute 12 times 8",
            "Solve 144 divided by 12",
            "Do the math for 25 percent of 200",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .calculation, "Failed to classify: '\(testCase)'")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
            XCTAssertNotNil(classification.extractedParameters["expression"])
        }
    }

    // MARK: - Translation Tests

    func testTranslationClassification() async throws {
        let testCases = [
            "Translate 'hello world' to Spanish",
            "How do you say good morning in French?",
            "Translate this to German: thank you",
            "What does bonjour mean in English?",
            "Translate from English to Italian",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .translation, "Failed to classify: '\(testCase)'")
            XCTAssertGreaterThan(classification.confidence, 0.6, "Low confidence for: '\(testCase)'")
        }
    }

    // MARK: - Storage Tests

    func testStorageClassification() async throws {
        let testCases = [
            "Upload this file to cloud storage",
            "Save the document to my drive",
            "Store this backup in the cloud",
            "Sync this file with storage",
            "Put this in my storage folder",
        ]

        for testCase in testCases {
            let classification = await classifier.classifyVoiceCommand(testCase)

            XCTAssertEqual(classification.intent, .uploadStorage, "Failed to classify: '\(testCase)'")
            XCTAssertEqual(classification.mcpServerId, "storage-server")
            XCTAssertGreaterThan(classification.confidence, 0.5, "Low confidence for: '\(testCase)'")
        }
    }

    // MARK: - Confidence and Fallback Tests

    func testLowConfidenceClassification() async throws {
        let ambiguousCommands = [
            "Do something with that thing",
            "Handle this somehow",
            "Process the data or whatever",
            "I need help with stuff",
        ]

        for command in ambiguousCommands {
            let classification = await classifier.classifyVoiceCommand(command)

            // Should have low confidence or be classified as unknown
            if classification.confidence > 0.6 {
                XCTFail("Unexpectedly high confidence for ambiguous command: '\(command)'")
            }

            // Should have fallback options
            XCTAssertFalse(classification.fallbackOptions.isEmpty, "No fallback options for: '\(command)'")
        }
    }

    func testFallbackOptions() async throws {
        let command = "Create a document and send it via email"
        let classification = await classifier.classifyVoiceCommand(command)

        // Should have a primary classification
        XCTAssertNotEqual(classification.intent, .unknown)

        // Should have fallback options since it's ambiguous
        XCTAssertFalse(classification.fallbackOptions.isEmpty, "Expected fallback options for ambiguous command")

        // Verify fallback options have different intents
        let fallbackIntents = classification.fallbackOptions.map { $0.intent }
        XCTAssertTrue(fallbackIntents.contains(.sendEmail) || fallbackIntents.contains(.generateDocument))
    }

    // MARK: - Caching Tests

    func testClassificationCaching() async throws {
        let command = "Generate a PDF report about sales"

        // First classification
        let classification1 = await classifier.classifyVoiceCommand(command)

        // Second classification (should be cached)
        let classification2 = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification1.intent, classification2.intent)
        XCTAssertEqual(classification1.confidence, classification2.confidence, accuracy: 0.001)
        XCTAssertEqual(classification1.mcpServerId, classification2.mcpServerId)
    }

    func testCacheClear() async throws {
        let command = "Search for machine learning tutorials"

        // Classify to populate cache
        _ = await classifier.classifyVoiceCommand(command)

        // Clear cache
        classifier.clearCache()

        // Verify cache is empty
        XCTAssertTrue(classifier.classificationCache.isEmpty)
    }

    // MARK: - Feedback and Learning Tests

    func testUserFeedback() async throws {
        let command = "Send email to test@example.com"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .sendEmail)

        // Provide positive feedback
        classifier.provideFeedback(for: command, wasCorrect: true)

        // Classify again - should have same or higher confidence
        let newClassification = await classifier.classifyVoiceCommand(command)
        XCTAssertGreaterThanOrEqual(newClassification.confidence, classification.confidence)
    }

    // MARK: - Statistics Tests

    func testClassificationStatistics() async throws {
        let commands = [
            "Generate a PDF document",
            "Send an email",
            "Schedule a meeting",
            "Search for information",
            "What's the weather?",
        ]

        let initialStats = classifier.getClassificationStatistics()
        let initialCount = initialStats.totalClassifications

        // Classify multiple commands
        for command in commands {
            _ = await classifier.classifyVoiceCommand(command)
        }

        let finalStats = classifier.getClassificationStatistics()

        XCTAssertEqual(finalStats.totalClassifications, initialCount + commands.count)
        XCTAssertGreaterThan(finalStats.averageConfidence, 0.0)
        XCTAssertGreaterThan(finalStats.averageProcessingTime, 0.0)
        XCTAssertFalse(finalStats.intentDistribution.isEmpty)
    }

    // MARK: - Edge Cases

    func testEmptyCommand() async throws {
        let classification = await classifier.classifyVoiceCommand("")

        XCTAssertEqual(classification.intent, .unknown)
        XCTAssertLessThan(classification.confidence, 0.1)
    }

    func testVeryLongCommand() async throws {
        let longCommand = String(repeating: "test ", count: 1000) + "generate a document"
        let classification = await classifier.classifyVoiceCommand(longCommand)

        // Should still classify correctly despite length
        XCTAssertEqual(classification.intent, .generateDocument)
    }

    func testSpecialCharacters() async throws {
        let command = "Send email to user@domain.com with subject: Meeting @ 3:00 PM - Q4 Results (URGENT!)"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .sendEmail)
        XCTAssertGreaterThan(classification.confidence, 0.6)
    }

    func testMultiLanguageContent() async throws {
        // Test with mixed language content
        let command = "Translate 'Bonjour, comment allez-vous?' to English"
        let classification = await classifier.classifyVoiceCommand(command)

        XCTAssertEqual(classification.intent, .translation)
        XCTAssertGreaterThan(classification.confidence, 0.6)
    }

    // MARK: - Performance Tests

    func testClassificationPerformance() async throws {
        let commands = Array(repeating: "Generate a PDF document about project status", count: 100)

        let startTime = Date()

        for command in commands {
            _ = await classifier.classifyVoiceCommand(command)
        }

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / Double(commands.count)

        // Should process commands quickly (under 50ms average)
        XCTAssertLessThan(averageTime, 0.05, "Classification too slow: \(averageTime)s average")
    }

    // MARK: - Integration Tests

    func testMCPServerMapping() async throws {
        let testCases: [(String, CommandIntent, String)] = [
            ("Generate document", .generateDocument, "document-generator"),
            ("Send email", .sendEmail, "email-server"),
            ("Schedule meeting", .scheduleCalendar, "calendar-server"),
            ("Search information", .performSearch, "search-server"),
            ("Upload file", .uploadStorage, "storage-server"),
        ]

        for (command, expectedIntent, expectedServer) in testCases {
            let classification = await classifier.classifyVoiceCommand(command)

            XCTAssertEqual(classification.intent, expectedIntent)
            XCTAssertEqual(classification.mcpServerId, expectedServer)
        }
    }

    func testParameterFormatting() async throws {
        let command = "Send email to test@example.com"
        let classification = await classifier.classifyVoiceCommand(command)

        let formattedParams = classifier.formatParametersForMCP(
            classification.extractedParameters,
            intent: classification.intent
        )

        // Should format recipient as array for MCP
        if let to = formattedParams["to"] as? [String] {
            XCTAssertTrue(to.contains("test@example.com"))
        } else {
            XCTFail("Email recipient not properly formatted for MCP")
        }

        // Should have default subject
        XCTAssertNotNil(formattedParams["subject"])
    }

    func testFallbackToGeneralAI() async throws {
        let generalQuestions = [
            "How are you today?",
            "What's the meaning of life?",
            "Tell me a joke",
            "Explain quantum physics",
        ]

        for question in generalQuestions {
            let classification = await classifier.classifyVoiceCommand(question)
            let shouldFallback = classifier.shouldFallbackToGeneralAI(classification)

            XCTAssertTrue(shouldFallback, "Should fallback to general AI for: '\(question)'")
        }
    }
}
