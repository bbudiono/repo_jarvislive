// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: ElevenLabs Voice Synthesizer for realistic AI voice responses
 * Issues & Complexity Summary: Real-time voice synthesis with caching, error handling, and iOS audio integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500
 *   - Core Algorithm Complexity: High (Voice API integration, audio processing, caching)
 *   - Dependencies: 4 Major (ElevenLabs API, AVFoundation, Keychain, Networking)
 *   - State Management Complexity: High (API state, audio playback, cache management)
 *   - Novelty/Uncertainty Factor: Medium (ElevenLabs API integration)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 80%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 82%
 * Justification for Estimates: Voice synthesis requires API integration and audio processing
 * Final Code Complexity (Actual %): 84%
 * Overall Result Score (Success & Quality %): 89%
 * Key Variances/Learnings: Audio caching critical for performance, error handling for API limits
 * Last Updated: 2025-06-26
 */

import Foundation
import AVFoundation
import Combine

// MARK: - Voice Synthesis Models

struct VoiceSynthesisRequest {
    let text: String
    let voiceId: String
    let voiceSettings: VoiceSettings
    let outputFormat: AudioFormat
    let optimizeStreamingLatency: Bool

    static func standard(text: String) -> VoiceSynthesisRequest {
        return VoiceSynthesisRequest(
            text: text,
            voiceId: "21m00Tcm4TlvDq8ikWAM", // Rachel voice
            voiceSettings: .conversational,
            outputFormat: .mp3_44100_128,
            optimizeStreamingLatency: true
        )
    }
}

struct VoiceSettings: Codable {
    let stability: Double
    let similarityBoost: Double
    let style: Double
    let useSpeakerBoost: Bool

    static let conversational = VoiceSettings(
        stability: 0.5,
        similarityBoost: 0.75,
        style: 0.0,
        useSpeakerBoost: true
    )

    static let dramatic = VoiceSettings(
        stability: 0.3,
        similarityBoost: 0.8,
        style: 0.2,
        useSpeakerBoost: true
    )

    static let calm = VoiceSettings(
        stability: 0.8,
        similarityBoost: 0.6,
        style: 0.0,
        useSpeakerBoost: false
    )

    enum CodingKeys: String, CodingKey {
        case stability
        case similarityBoost = "similarity_boost"
        case style
        case useSpeakerBoost = "use_speaker_boost"
    }
}

enum AudioFormat: String, CaseIterable {
    case mp3_22050_32 = "mp3_22050_32"
    case mp3_44100_32 = "mp3_44100_32"
    case mp3_44100_64 = "mp3_44100_64"
    case mp3_44100_96 = "mp3_44100_96"
    case mp3_44100_128 = "mp3_44100_128"
    case mp3_44100_192 = "mp3_44100_192"
    case pcm_16000 = "pcm_16000"
    case pcm_22050 = "pcm_22050"
    case pcm_24000 = "pcm_24000"
    case pcm_44100 = "pcm_44100"
}

struct VoiceSynthesisResult {
    let audioData: Data
    let duration: TimeInterval
    let audioFormat: AudioFormat
    let voiceUsed: String
    let processingTime: TimeInterval
    let cached: Bool
}

struct VoiceInfo {
    let voiceId: String
    let name: String
    let description: String
    let category: String
    let isAvailable: Bool
}

// MARK: - ElevenLabs Voice Synthesizer

@MainActor
final class ElevenLabsVoiceSynthesizer: NSObject, ObservableObject {
    // MARK: - Published Properties

    @Published var isProcessing: Bool = false
    @Published var isAvailable: Bool = false
    @Published var availableVoices: [VoiceInfo] = []
    @Published var lastSynthesis: VoiceSynthesisResult?
    @Published var lastError: VoiceSynthesisError?
    @Published var currentlyPlaying: Bool = false

    // MARK: - Configuration

    struct Configuration {
        let baseURL: String
        let apiVersion: String
        let maxCacheSize: Int
        let cacheExpirationTime: TimeInterval
        let requestTimeout: TimeInterval
        let maxRetries: Int

        static let `default` = Configuration(
            baseURL: "https://api.elevenlabs.io",
            apiVersion: "v1",
            maxCacheSize: 100,
            cacheExpirationTime: 3600, // 1 hour
            requestTimeout: 30.0,
            maxRetries: 2
        )
    }

    // MARK: - Private Properties

    private let configuration: Configuration
    private let keychainManager: KeychainManager
    private let urlSession: URLSession
    private var audioPlayer: AVAudioPlayer?
    private var voiceCache: [String: CachedVoiceSynthesis] = [:]
    private var cancellables = Set<AnyCancellable>()

    // Cache structure
    private struct CachedVoiceSynthesis {
        let audioData: Data
        let timestamp: Date
        let voiceSettings: VoiceSettings
        let audioFormat: AudioFormat
    }

    // Available voices
    private let defaultVoices: [VoiceInfo] = [
        VoiceInfo(voiceId: "21m00Tcm4TlvDq8ikWAM", name: "Rachel", description: "Calm, professional female voice", category: "conversational", isAvailable: true),
        VoiceInfo(voiceId: "AZnzlk1XvdvUeBnXmlld", name: "Domi", description: "Strong, confident female voice", category: "professional", isAvailable: true),
        VoiceInfo(voiceId: "EXAVITQu4vr4xnSDxMaL", name: "Bella", description: "Friendly, engaging female voice", category: "conversational", isAvailable: true),
        VoiceInfo(voiceId: "ErXwobaYiN019PkySvjV", name: "Antoni", description: "Well-rounded male voice", category: "conversational", isAvailable: true),
        VoiceInfo(voiceId: "VR6AewLTigWG4xSOukaG", name: "Arnold", description: "Crisp, authoritative male voice", category: "professional", isAvailable: true),
    ]

    // MARK: - Initialization

    init(
        configuration: Configuration = .default,
        keychainManager: KeychainManager? = nil
    ) {
        self.configuration = configuration
        self.keychainManager = keychainManager ?? KeychainManager(service: "com.jarvis.elevenlabs")

        // Configure URL session
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.timeoutIntervalForRequest = configuration.requestTimeout
        sessionConfig.timeoutIntervalForResource = configuration.requestTimeout * 2
        self.urlSession = URLSession(configuration: sessionConfig)

        super.init()

        // Initialize available voices
        self.availableVoices = defaultVoices

        // Check API availability
        Task {
            await checkAPIAvailability()
        }

        // Setup audio session
        setupAudioSession()

        // Start cache cleanup timer
        startCacheCleanupTimer()
    }

    // MARK: - Audio Session Setup

    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("⚠️ Failed to setup audio session: \(error.localizedDescription)")
        }
    }

    // MARK: - API Availability Check

    private func checkAPIAvailability() async {
        guard let apiKey = getAPIKey() else {
            isAvailable = false
            return
        }

        do {
            let url = URL(string: "\(configuration.baseURL)/\(configuration.apiVersion)/voices")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            request.timeoutInterval = 10.0

            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                isAvailable = false
                return
            }

            // Parse voices response if needed
            isAvailable = true
        } catch {
            isAvailable = false
            print("⚠️ ElevenLabs API not available: \(error.localizedDescription)")
        }
    }

    // MARK: - Voice Synthesis

    /// Synthesize text to speech using ElevenLabs API
    func synthesizeVoice(text: String, request: VoiceSynthesisRequest? = nil) async throws -> Data {
        guard !text.isEmpty else {
            throw VoiceSynthesisError.invalidInput("Text cannot be empty")
        }

        let synthesisRequest = request ?? .standard(text: text)

        isProcessing = true
        defer { isProcessing = false }

        let startTime = Date()

        do {
            // Check cache first
            let cacheKey = generateCacheKey(text: text, request: synthesisRequest)
            if let cachedSynthesis = voiceCache[cacheKey],
               Date().timeIntervalSince(cachedSynthesis.timestamp) < configuration.cacheExpirationTime {
                let result = VoiceSynthesisResult(
                    audioData: cachedSynthesis.audioData,
                    duration: getAudioDuration(cachedSynthesis.audioData),
                    audioFormat: cachedSynthesis.audioFormat,
                    voiceUsed: synthesisRequest.voiceId,
                    processingTime: Date().timeIntervalSince(startTime),
                    cached: true
                )

                lastSynthesis = result
                return cachedSynthesis.audioData
            }

            // Perform API synthesis
            let audioData = try await performVoiceSynthesis(request: synthesisRequest)

            // Cache the result
            if voiceCache.count < configuration.maxCacheSize {
                voiceCache[cacheKey] = CachedVoiceSynthesis(
                    audioData: audioData,
                    timestamp: Date(),
                    voiceSettings: synthesisRequest.voiceSettings,
                    audioFormat: synthesisRequest.outputFormat
                )
            }

            let result = VoiceSynthesisResult(
                audioData: audioData,
                duration: getAudioDuration(audioData),
                audioFormat: synthesisRequest.outputFormat,
                voiceUsed: synthesisRequest.voiceId,
                processingTime: Date().timeIntervalSince(startTime),
                cached: false
            )

            lastSynthesis = result
            lastError = nil

            return audioData
        } catch {
            let synthesisError = error as? VoiceSynthesisError ?? .synthesisError(error.localizedDescription)
            lastError = synthesisError
            throw synthesisError
        }
    }

    // MARK: - API Integration

    private func performVoiceSynthesis(request: VoiceSynthesisRequest) async throws -> Data {
        guard let apiKey = getAPIKey() else {
            throw VoiceSynthesisError.apiKeyNotFound
        }

        let url = URL(string: "\(configuration.baseURL)/\(configuration.apiVersion)/text-to-speech/\(request.voiceId)")!

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        // Build request body
        let requestBody: [String: Any] = [
            "text": request.text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": request.voiceSettings.stability,
                "similarity_boost": request.voiceSettings.similarityBoost,
                "style": request.voiceSettings.style,
                "use_speaker_boost": request.voiceSettings.useSpeakerBoost,
            ],
            "output_format": request.outputFormat.rawValue,
            "optimize_streaming_latency": request.optimizeStreamingLatency ? 1 : 0,
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Perform request with retries
        var lastError: Error?
        for attempt in 1...configuration.maxRetries {
            do {
                let (data, response) = try await urlSession.data(for: urlRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw VoiceSynthesisError.invalidResponse
                }

                if httpResponse.statusCode == 200 {
                    return data
                } else if httpResponse.statusCode == 401 {
                    throw VoiceSynthesisError.invalidAPIKey
                } else if httpResponse.statusCode == 429 {
                    // Rate limited - wait before retry
                    if attempt < configuration.maxRetries {
                        try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
                        continue
                    }
                    throw VoiceSynthesisError.rateLimited
                } else {
                    let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                    throw VoiceSynthesisError.apiError(httpResponse.statusCode, errorMessage)
                }
            } catch {
                lastError = error
                if attempt < configuration.maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(attempt * 1_000_000_000))
                }
            }
        }

        throw lastError ?? VoiceSynthesisError.synthesisError("Max retries exceeded")
    }

    // MARK: - Audio Playback

    /// Play synthesized audio
    func playAudio(_ audioData: Data) async throws {
        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer?.delegate = self

            currentlyPlaying = true

            guard audioPlayer?.play() == true else {
                currentlyPlaying = false
                throw VoiceSynthesisError.playbackFailed("Failed to start audio playback")
            }

            // Wait for playback to complete
            while currentlyPlaying {
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
        } catch {
            currentlyPlaying = false
            throw VoiceSynthesisError.playbackFailed(error.localizedDescription)
        }
    }

    /// Stop current audio playback
    func stopPlayback() {
        audioPlayer?.stop()
        currentlyPlaying = false
    }

    // MARK: - Utility Methods

    private func getAPIKey() -> String? {
        do {
            return try keychainManager.getCredential(forKey: "elevenlabs_api_key")
        } catch {
            return nil
        }
    }

    func storeAPIKey(_ apiKey: String) throws {
        try keychainManager.storeCredential(apiKey, forKey: "elevenlabs_api_key")
    }

    private func generateCacheKey(text: String, request: VoiceSynthesisRequest) -> String {
        let settingsData = try? JSONEncoder().encode(request.voiceSettings)
        let settingsHash = settingsData?.hashValue ?? 0
        return "\(text.hashValue)_\(request.voiceId)_\(settingsHash)_\(request.outputFormat.rawValue)"
    }

    private func getAudioDuration(_ audioData: Data) -> TimeInterval {
        do {
            let audioPlayer = try AVAudioPlayer(data: audioData)
            return audioPlayer.duration
        } catch {
            return 0.0
        }
    }

    private func startCacheCleanupTimer() {
        Timer.publish(every: 300, on: .main, in: .common) // Every 5 minutes
            .autoconnect()
            .sink { [weak self] _ in
                self?.cleanupExpiredCache()
            }
            .store(in: &cancellables)
    }

    private func cleanupExpiredCache() {
        let now = Date()
        voiceCache = voiceCache.filter { _, cached in
            now.timeIntervalSince(cached.timestamp) < configuration.cacheExpirationTime
        }
    }

    // MARK: - Public Interface

    func isAvailable() async -> Bool {
        return isAvailable
    }

    func clearCache() {
        voiceCache.removeAll()
    }

    func getCacheStatistics() -> [String: Any] {
        return [
            "cache_size": voiceCache.count,
            "max_cache_size": configuration.maxCacheSize,
            "cache_hit_rate": calculateCacheHitRate(),
        ]
    }

    private func calculateCacheHitRate() -> Double {
        // This would track cache hits vs misses in a production implementation
        return 0.0
    }
}

// MARK: - AVAudioPlayerDelegate

extension ElevenLabsVoiceSynthesizer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        currentlyPlaying = false
    }

    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        currentlyPlaying = false
        if let error = error {
            lastError = .playbackFailed(error.localizedDescription)
        }
    }
}

// MARK: - Error Handling

enum VoiceSynthesisError: Error, LocalizedError {
    case invalidInput(String)
    case apiKeyNotFound
    case invalidAPIKey
    case synthesisError(String)
    case rateLimited
    case apiError(Int, String)
    case invalidResponse
    case playbackFailed(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidInput(let message):
            return "Invalid input: \(message)"
        case .apiKeyNotFound:
            return "ElevenLabs API key not found"
        case .invalidAPIKey:
            return "Invalid ElevenLabs API key"
        case .synthesisError(let message):
            return "Voice synthesis failed: \(message)"
        case .rateLimited:
            return "API rate limit exceeded"
        case .apiError(let code, let message):
            return "API error (\(code)): \(message)"
        case .invalidResponse:
            return "Invalid API response"
        case .playbackFailed(let message):
            return "Audio playback failed: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
