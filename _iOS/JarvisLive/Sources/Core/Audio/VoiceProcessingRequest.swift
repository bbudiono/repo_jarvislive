// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Voice processing request model for LiveKit audio pipeline
 * Issues & Complexity Summary: Simple request model for voice processing
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~50
 *   - Core Algorithm Complexity: Low
 *   - Dependencies: 1 (Foundation)
 *   - State Management Complexity: Low
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 60%
 * Problem Estimate (Inherent Problem Difficulty %): 50%
 * Initial Code Complexity Estimate %: 55%
 * Justification for Estimates: Simple data model for voice processing requests
 * Final Code Complexity (Actual %): 60%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Basic request model to support LiveKit integration
 * Last Updated: 2025-06-28
 */

import Foundation

// MARK: - Voice Processing Request

struct VoiceProcessingRequest {
    let id: UUID
    let audioData: Data
    let timestamp: Date
    let processingType: ProcessingType
    let configuration: ProcessingConfiguration
    let metadata: [String: Any]
    
    enum ProcessingType {
        case speechToText
        case voiceActivity
        case classification
        case transcription
        case analysis
    }
    
    struct ProcessingConfiguration {
        let language: String
        let quality: QualityLevel
        let enableNoiseReduction: Bool
        let enableEcho: Bool
        let sampleRate: Int
        let channels: Int
        
        enum QualityLevel {
            case low
            case medium
            case high
            case maximum
        }
        
        static let `default` = ProcessingConfiguration(
            language: "en-US",
            quality: .medium,
            enableNoiseReduction: true,
            enableEcho: false,
            sampleRate: 48000,
            channels: 1
        )
    }
    
    init(audioData: Data, 
         processingType: ProcessingType = .speechToText, 
         configuration: ProcessingConfiguration = .default,
         metadata: [String: Any] = [:]) {
        self.id = UUID()
        self.audioData = audioData
        self.timestamp = Date()
        self.processingType = processingType
        self.configuration = configuration
        self.metadata = metadata
    }
}

// MARK: - Voice Processing Response

struct VoiceProcessingResponse {
    let requestId: UUID
    let result: ProcessingResult
    let confidence: Double
    let processingTime: TimeInterval
    let timestamp: Date
    let metadata: [String: Any]
    
    enum ProcessingResult {
        case text(String)
        case activity(VoiceActivity)
        case classification(VoiceClassification)
        case error(ProcessingError)
    }
    
    struct VoiceActivity {
        let isActive: Bool
        let activityLevel: Double
        let duration: TimeInterval
    }
    
    struct VoiceClassification {
        let intent: String
        let parameters: [String: Any]
        let confidence: Double
    }
    
    enum ProcessingError: Error {
        case audioTooShort
        case audioTooLong
        case noSpeechDetected
        case processingFailed
        case invalidConfiguration
        case timeout
    }
}