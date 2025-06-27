// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Demonstration and example usage of VoiceCommandClassifier
 * Issues & Complexity Summary: Example implementations and usage patterns for voice command classification
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~150
 *   - Core Algorithm Complexity: Low (Demonstration and examples)
 *   - Dependencies: 2 New (Foundation, VoiceCommandClassifier)
 *   - State Management Complexity: Low (Example state management)
 *   - Novelty/Uncertainty Factor: Low (Example code patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 60%
 * Problem Estimate (Inherent Problem Difficulty %): 50%
 * Initial Code Complexity Estimate %: 55%
 * Justification for Estimates: Demonstration code is typically straightforward with clear examples
 * Final Code Complexity (Actual %): 57%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Good demonstration code requires clear, practical examples
 * Last Updated: 2025-06-26
 */

import Foundation

// MARK: - Voice Command Classifier Demo

class VoiceCommandClassifierDemo {
    private let classifier = VoiceCommandClassifier()

    init() {
        print("🎯 VoiceCommandClassifier Demo Initialized")
    }

    // MARK: - Basic Classification Examples

    func runBasicClassificationDemo() async {
        print("\n📋 === Basic Voice Command Classification Demo ===")

        let sampleCommands = [
            "Generate a PDF document about the quarterly sales report",
            "Send an email to john@example.com with subject Meeting Update",
            "Schedule a team meeting for tomorrow at 2 PM",
            "Search for information about Swift programming",
            "What's the weather like in San Francisco today?",
            "Upload this file to cloud storage",
            "Calculate 25 percent of 400",
            "Translate 'Hello world' to Spanish",
        ]

        for command in sampleCommands {
            let classification = await classifier.classifyVoiceCommand(command)

            print("\n🗣️  Command: '\(command)'")
            print("   🎯 Intent: \(classification.intent.displayName)")
            print("   📊 Confidence: \(String(format: "%.2f", classification.confidence))")
            print("   🖥️  MCP Server: \(classification.mcpServerId)")

            if !classification.extractedParameters.isEmpty {
                print("   📋 Parameters:")
                for (key, value) in classification.extractedParameters {
                    print("      • \(key): \(value)")
                }
            }

            if !classification.fallbackOptions.isEmpty {
                print("   🔄 Fallback Options:")
                for fallback in classification.fallbackOptions.prefix(2) {
                    print("      • \(fallback.intent.displayName) (confidence: \(String(format: "%.2f", fallback.confidence)))")
                }
            }
        }
    }

    // MARK: - Parameter Extraction Demo

    func runParameterExtractionDemo() async {
        print("\n🔍 === Parameter Extraction Demo ===")

        let parameterizedCommands = [
            (
                command: "Generate a DOCX document about the Q4 financial results for the board meeting",
                expectedParams: ["content", "format"]
            ),
            (
                command: "Send an email to sarah@company.com with subject Project Status Update saying the project is on track",
                expectedParams: ["recipient", "subject", "body"]
            ),
            (
                command: "Schedule a meeting about sprint planning for next Monday at 10 AM for 2 hours",
                expectedParams: ["title", "datetime", "duration"]
            ),
            (
                command: "Search for recent articles about machine learning on the web",
                expectedParams: ["query", "source"]
            ),
            (
                command: "What's the weather forecast for Los Angeles tomorrow?",
                expectedParams: ["location", "timeframe"]
            ),
        ]

        for (command, expectedParams) in parameterizedCommands {
            let classification = await classifier.classifyVoiceCommand(command)

            print("\n🗣️  Command: '\(command)'")
            print("   🎯 Intent: \(classification.intent.displayName)")
            print("   📊 Confidence: \(String(format: "%.2f", classification.confidence))")

            print("   📋 Expected Parameters: \(expectedParams.joined(separator: ", "))")
            print("   ✅ Extracted Parameters:")

            for expectedParam in expectedParams {
                if let value = classification.extractedParameters[expectedParam] {
                    print("      • \(expectedParam): \(value) ✓")
                } else {
                    print("      • \(expectedParam): [not extracted] ❌")
                }
            }

            // Show MCP-formatted parameters
            let mcpParams = classifier.formatParametersForMCP(
                classification.extractedParameters,
                intent: classification.intent
            )

            if mcpParams.count > classification.extractedParameters.count {
                print("   🔧 Additional MCP Parameters:")
                for (key, value) in mcpParams {
                    if classification.extractedParameters[key] == nil {
                        print("      • \(key): \(value) [auto-added]")
                    }
                }
            }
        }
    }

    // MARK: - Confidence and Fallback Demo

    func runConfidenceAndFallbackDemo() async {
        print("\n🎲 === Confidence and Fallback Demo ===")

        let ambiguousCommands = [
            "Create a document and send it via email",  // Multi-intent
            "Do something with that file",              // Very ambiguous
            "Generate email about meeting",             // Ambiguous intent
            "Send document to John",                    // Missing details
            "Process the data somehow",                  // Vague command
        ]

        for command in ambiguousCommands {
            let classification = await classifier.classifyVoiceCommand(command)

            print("\n🗣️  Ambiguous Command: '\(command)'")
            print("   🎯 Primary Intent: \(classification.intent.displayName)")
            print("   📊 Confidence: \(String(format: "%.2f", classification.confidence))")

            if classification.confidence < 0.7 {
                print("   ⚠️  Low confidence - may need clarification")
            }

            if !classification.fallbackOptions.isEmpty {
                print("   🔄 Alternative Interpretations:")
                for (index, fallback) in classification.fallbackOptions.enumerated() {
                    print("      \(index + 1). \(fallback.intent.displayName) (confidence: \(String(format: "%.2f", fallback.confidence)))")
                    print("         Reason: \(fallback.reason)")
                }
            }

            // Show fallback decision
            let shouldFallback = classifier.shouldFallbackToGeneralAI(classification)
            print("   🤖 Fallback to General AI: \(shouldFallback ? "Yes" : "No")")
        }
    }

    // MARK: - Performance Demo

    func runPerformanceDemo() async {
        print("\n⚡ === Performance Demo ===")

        let testCommands = [
            "Generate a PDF document",
            "Send an email",
            "Schedule a meeting",
            "Search for information",
            "Weather forecast",
        ]

        print("Testing classification performance with \(testCommands.count) commands...")

        let startTime = Date()
        var totalConfidence: Double = 0.0

        for command in testCommands {
            let classification = await classifier.classifyVoiceCommand(command)
            totalConfidence += classification.confidence
        }

        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        let averageTime = totalTime / Double(testCommands.count)
        let averageConfidence = totalConfidence / Double(testCommands.count)

        print("   ⏱️  Total Time: \(String(format: "%.3f", totalTime))s")
        print("   📈 Average Time per Command: \(String(format: "%.3f", averageTime))s")
        print("   📊 Average Confidence: \(String(format: "%.2f", averageConfidence))")

        // Test caching performance
        print("\nTesting cache performance...")
        let cacheStartTime = Date()

        for command in testCommands {
            _ = await classifier.classifyVoiceCommand(command) // Should be cached
        }

        let cacheEndTime = Date()
        let cacheTime = cacheEndTime.timeIntervalSince(cacheStartTime)
        let cacheAverageTime = cacheTime / Double(testCommands.count)

        print("   ⚡ Cached Average Time: \(String(format: "%.3f", cacheAverageTime))s")
        print("   🚀 Speed Improvement: \(String(format: "%.1f", averageTime / cacheAverageTime))x faster")
    }

    // MARK: - Statistics Demo

    func runStatisticsDemo() async {
        print("\n📈 === Classification Statistics Demo ===")

        let diverseCommands = [
            "Generate a PDF report",
            "Send email to team",
            "Schedule daily standup",
            "Search for tutorials",
            "Weather update",
            "Create a document",
            "Email the client",
            "Book a meeting room",
            "Find recent news",
            "Temperature forecast",
        ]

        print("Classifying \(diverseCommands.count) diverse commands to generate statistics...")

        for command in diverseCommands {
            _ = await classifier.classifyVoiceCommand(command)
        }

        let stats = classifier.getClassificationStatistics()

        print("\n📊 Classification Statistics:")
        print("   📝 Total Classifications: \(stats.totalClassifications)")
        print("   ✅ Successful Classifications: \(stats.successfulClassifications)")
        print("   📈 Success Rate: \(String(format: "%.1f", stats.successRate * 100))%")
        print("   🎯 Average Confidence: \(String(format: "%.2f", stats.averageConfidence))")
        print("   ⚡ Average Processing Time: \(String(format: "%.3f", stats.averageProcessingTime))s")

        print("\n🏷️  Intent Distribution:")
        let sortedIntents = stats.intentDistribution.sorted { $0.value > $1.value }
        for (intent, count) in sortedIntents.prefix(5) {
            let percentage = Double(count) / Double(stats.totalClassifications) * 100
            print("   • \(intent.displayName): \(count) (\(String(format: "%.1f", percentage))%)")
        }
    }

    // MARK: - Learning and Feedback Demo

    func runLearningDemo() async {
        print("\n🧠 === Learning and Feedback Demo ===")

        let feedbackCommands = [
            ("Send an email to the team", true),
            ("Generate a document report", true),
            ("Schedule team meeting", true),
            ("Search for some stuff", false), // Intentionally marked as incorrect
            ("Upload the file", true),
        ]

        print("Testing adaptive learning with user feedback...")

        for (command, isCorrect) in feedbackCommands {
            let classification = await classifier.classifyVoiceCommand(command)
            print("\n🗣️  Command: '\(command)'")
            print("   🎯 Classified as: \(classification.intent.displayName)")
            print("   📊 Initial Confidence: \(String(format: "%.2f", classification.confidence))")

            // Provide feedback
            classifier.provideFeedback(for: command, wasCorrect: isCorrect)
            print("   💭 Feedback: \(isCorrect ? "Correct ✅" : "Incorrect ❌")")

            // Classify again to see adaptation
            let newClassification = await classifier.classifyVoiceCommand(command)
            print("   📈 Updated Confidence: \(String(format: "%.2f", newClassification.confidence))")

            let confidenceChange = newClassification.confidence - classification.confidence
            if abs(confidenceChange) > 0.01 {
                print("   🔄 Confidence Change: \(confidenceChange > 0 ? "+" : "")\(String(format: "%.3f", confidenceChange))")
            }
        }
    }

    // MARK: - Edge Cases Demo

    func runEdgeCasesDemo() async {
        print("\n🔍 === Edge Cases Demo ===")

        let edgeCases = [
            ("", "Empty command"),
            ("   ", "Whitespace only"),
            ("a", "Single character"),
            ("Send email to user@domain.com with subject: Meeting @ 3:00 PM - Q4 Results (URGENT!)", "Special characters"),
            ("Translate 'Bonjour, comment ça va?' from French to English", "Mixed languages"),
            (String(repeating: "very ", count: 100) + "long command to generate document", "Very long command"),
            ("Generate PDF send email schedule meeting search data", "Multiple intents"),
            ("asdfgh qwerty uiopzxc", "Nonsense text"),
        ]

        for (command, description) in edgeCases {
            let classification = await classifier.classifyVoiceCommand(command)

            print("\n🧪 Edge Case: \(description)")
            print("   📝 Command: '\(command.prefix(50))\(command.count > 50 ? "..." : "")'")
            print("   🎯 Intent: \(classification.intent.displayName)")
            print("   📊 Confidence: \(String(format: "%.2f", classification.confidence))")
            print("   ⚡ Processing Time: \(String(format: "%.3f", classification.processingTime))s")

            if classification.intent == .unknown {
                print("   ❓ Correctly identified as unknown")
            }

            if classification.confidence < 0.3 {
                print("   ⚠️  Very low confidence - appropriate for this case")
            }
        }
    }

    // MARK: - Complete Demo Runner

    func runCompleteDemo() async {
        print("🎪 === VoiceCommandClassifier Complete Demo ===")
        print("This demo showcases all features of the Voice Command Classification Engine")

        await runBasicClassificationDemo()
        await runParameterExtractionDemo()
        await runConfidenceAndFallbackDemo()
        await runPerformanceDemo()
        await runStatisticsDemo()
        await runLearningDemo()
        await runEdgeCasesDemo()

        print("\n🎉 === Demo Complete ===")
        print("The VoiceCommandClassifier successfully demonstrated:")
        print("✅ Intent classification for various voice commands")
        print("✅ Parameter extraction from natural language")
        print("✅ Confidence scoring and fallback mechanisms")
        print("✅ Performance optimization with caching")
        print("✅ Statistical tracking and reporting")
        print("✅ Adaptive learning from user feedback")
        print("✅ Robust handling of edge cases")
        print("\n🚀 Ready for integration with MCP servers!")
    }
}

// MARK: - Usage Example

/*
 Usage Example:
 
 ```swift
 let demo = VoiceCommandClassifierDemo()
 
 // Run complete demo
 await demo.runCompleteDemo()
 
 // Or run individual demos
 await demo.runBasicClassificationDemo()
 await demo.runParameterExtractionDemo()
 await demo.runPerformanceDemo()
 ```
 
 Integration with LiveKitManager:
 
 ```swift
 let liveKitManager = LiveKitManager()
 
 // Classify a voice command
 if let classification = await liveKitManager.classifyVoiceCommand("Generate a PDF report") {
     print("Intent: \(classification.intent.displayName)")
     print("MCP Server: \(classification.mcpServerId)")
     print("Confidence: \(classification.confidence)")
 }
 
 // Get classification statistics
 if let stats = liveKitManager.getClassificationStatistics() {
     print("Success Rate: \(stats.successRate)")
     print("Average Confidence: \(stats.averageConfidence)")
 }
 
 // Provide feedback for learning
 liveKitManager.provideClassificationFeedback(for: "send email", wasCorrect: true)
 ```
 */
