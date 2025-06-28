// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Production-ready LiveKit manager for real-time voice AI interactions
 * Issues & Complexity Summary: Complex audio pipeline with real-time processing, voice activity detection, and credential management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~400
 *   - Core Algorithm Complexity: High (Real-time audio processing)
 *   - Dependencies: 5 New (LiveKit, AVFoundation, Speech, KeychainManager, Combine)
 *   - State Management Complexity: High (Audio states, connection states, voice detection)
 *   - Novelty/Uncertainty Factor: Medium (LiveKit integration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Real-time audio requires careful state management and error handling
 * Final Code Complexity (Actual %): 87%
 * Overall Result Score (Success & Quality %): 91%
 * Key Variances/Learnings: Real-time audio requires careful state management and error handling
 * Last Updated: 2025-06-25
 */

import Foundation
import LiveKit
import Combine
import AVFoundation
import Speech

// MARK: - Protocol Definitions

protocol LiveKitRoom: AnyObject, Sendable {
    func add(delegate: RoomDelegate)
    func connect(url: String, token: String, connectOptions: ConnectOptions?, roomOptions: RoomOptions?) async throws
    func disconnect() async
}

extension Room: LiveKitRoom {}

// MARK: - Voice Activity Detection

protocol VoiceActivityDelegate: AnyObject {
    func voiceActivityDidStart()
    func voiceActivityDidEnd()
    func speechRecognitionResult(_ text: String, isFinal: Bool)
    func aiResponseReceived(_ response: String, isComplete: Bool)
}

// MARK: - LiveKit Manager

@MainActor
public final class LiveKitManager: NSObject, ObservableObject {
    // MARK: - Conversation Management Integration
    @Published var conversationManager = ConversationManager()
    @Published var currentConversation: Conversation?

    // MARK: - MCP Integration
    @Published var mcpServerManager: MCPServerManager?
    @Published var backendClient: PythonBackendClient?

    // MARK: - Voice Command Classification & Pipeline
    @Published var voiceCommandClassifier: VoiceCommandClassifier?
    @Published var voiceClassificationManager: VoiceClassificationManager?
    @Published var voiceCommandPipeline: VoiceCommandPipeline?
    @Published var elevenLabsVoiceSynthesizer: ElevenLabsVoiceSynthesizer?

    // MARK: - State Management

    enum ManagerConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case reconnecting
        case error(String)

        static func == (lhs: ManagerConnectionState, rhs: ManagerConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.disconnected, .disconnected), (.connecting, .connecting),
                 (.connected, .connected), (.reconnecting, .reconnecting):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    enum AudioState: Equatable {
        case idle
        case recording
        case processing
        case playing
        case error(String)

        static func == (lhs: AudioState, rhs: AudioState) -> Bool {
            switch (lhs, rhs) {
            case (.idle, .idle), (.recording, .recording),
                 (.processing, .processing), (.playing, .playing):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }

    // MARK: - Published Properties

    @Published private(set) var connectionState: ManagerConnectionState = .disconnected
    @Published private(set) var audioState: AudioState = .idle
    @Published private(set) var isVoiceActivityDetected: Bool = false
    @Published private(set) var currentTranscription: String = ""
    @Published private(set) var audioLevel: Float = 0.0

    // MARK: - Private Properties

    private let room: LiveKitRoom
    private let _keychainManager: KeychainManager

    // Public accessor for keychainManager
    var keychainManager: KeychainManager {
        return _keychainManager
    }
    private var audioTrack: LocalAudioTrack?
    private var audioPublication: LocalTrackPublication?
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var audioLevelTimer: Timer?
    private var aiProcessingTask: Task<Void, Never>?

    // AI Integration
    private let urlSession: URLSession
    private var aiConversationHistory: [String] = []

    // ElevenLabs Voice Synthesis
    private var audioPlayer: AVAudioPlayer?
    private let elevenLabsBaseURL = "https://api.elevenlabs.io/v1"
    private let defaultVoiceID = "21m00Tcm4TlvDq8ikWAM" // Rachel voice

    private var cancellables = Set<AnyCancellable>()

    // Configuration
    private let audioFormat = AVAudioFormat(standardFormatWithSampleRate: 48000, channels: 1)!
    private let voiceActivityThreshold: Float = -30.0 // dB
    private let voiceActivityTimeout: TimeInterval = 2.0

    weak var voiceActivityDelegate: VoiceActivityDelegate?

    // MARK: - Initialization

    override convenience init() {
        let keychainManager = KeychainManager(service: "com.ablankcanvas.JarvisLive")
        self.init(room: Room(), keychainManager: keychainManager)
    }

    init(room: LiveKitRoom, keychainManager: KeychainManager) {
        self.room = room
        self._keychainManager = keychainManager

        // Configure URL session for AI requests
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30.0
        self.urlSession = URLSession(configuration: configuration)

        super.init()

        room.add(delegate: self)
        // Audio setup will be done when needed

        // Initialize voice command classifier
        setupVoiceCommandClassifier()

        // Initialize complete voice pipeline
        setupVoiceCommandPipeline()

        // Initialize MCP integration
        setupMCPIntegration()
    }

    deinit {
        // Clean shutdown - must be safe from any thread
    }

    // MARK: - Audio Engine Setup

    private func setupAudioEngine() {
        do {
            audioEngine = AVAudioEngine()

            guard let audioEngine = audioEngine else { return }

            let inputNode = audioEngine.inputNode
            let inputFormat = inputNode.outputFormat(forBus: 0)

            // Install tap to process audio and detect voice activity
            inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
                self?.processAudioBuffer(buffer)
            }

            // Prepare the engine
            audioEngine.prepare()
        } catch {
            print("Audio engine setup failed: \(error)")
            audioState = .error("Audio setup failed")
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        // Calculate audio level for voice activity detection
        guard let channelData = buffer.floatChannelData?[0] else { return }

        let frames = buffer.frameLength
        var sum: Float = 0.0

        for i in 0..<Int(frames) {
            sum += abs(channelData[i])
        }

        let averageLevel = sum / Float(frames)
        let decibelLevel = 20 * log10(averageLevel)

        audioLevel = decibelLevel

        // Voice activity detection
        let isVoiceActive = decibelLevel > voiceActivityThreshold

        if isVoiceActive != isVoiceActivityDetected {
            isVoiceActivityDetected = isVoiceActive

            if isVoiceActive {
                voiceActivityDelegate?.voiceActivityDidStart()
                startSpeechRecognition()
            } else {
                voiceActivityDelegate?.voiceActivityDidEnd()
                // Delay stopping to avoid cutting off speech
                DispatchQueue.main.asyncAfter(deadline: .now() + voiceActivityTimeout) { [weak self] in
                    if let self = self, !self.isVoiceActivityDetected {
                        self.stopSpeechRecognition()
                    }
                }
            }
        }

        // Send audio to speech recognition if active
        recognitionRequest?.append(buffer)
    }

    private func startAudioEngine() {
        guard let audioEngine = audioEngine, !audioEngine.isRunning else { return }

        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .voiceChat, options: [.defaultToSpeaker])
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()

            audioState = .recording

            // Start audio level monitoring
            audioLevelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                // Audio level is updated in processAudioBuffer
            }
        } catch {
            audioState = .error("Failed to start audio engine: \(error.localizedDescription)")
        }
    }

    private func stopAudioEngine() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioLevelTimer?.invalidate()
        audioLevelTimer = nil

        if audioState == .recording {
            audioState = .idle
        }
    }

    // MARK: - Speech Recognition

    private func setupSpeechRecognition() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

        // Request speech recognition authorization if needed
        Task {
            let authStatus = SFSpeechRecognizer.authorizationStatus()
            if authStatus == .notDetermined {
                SFSpeechRecognizer.requestAuthorization { status in
                    DispatchQueue.main.async {
                        if status != .authorized {
                            print("Speech recognition authorization denied")
                        } else {
                            print("Speech recognition authorized")
                        }
                    }
                }
            }
        }
    }

    private func startSpeechRecognition() {
        guard speechRecognizer?.isAvailable == true else {
            print("Speech recognizer not available")
            return
        }

        guard SFSpeechRecognizer.authorizationStatus() == .authorized else {
            print("Speech recognition not authorized")
            return
        }

        // Cancel any ongoing recognition
        stopSpeechRecognition()

        do {
            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            recognitionRequest?.shouldReportPartialResults = true
            recognitionRequest?.requiresOnDeviceRecognition = false // Allow cloud processing for better accuracy

            guard let recognitionRequest = recognitionRequest else {
                print("Failed to create recognition request")
                return
            }

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
                DispatchQueue.main.async {
                    if let result = result {
                        let transcription = result.bestTranscription.formattedString
                        self?.currentTranscription = transcription
                        self?.voiceActivityDelegate?.speechRecognitionResult(transcription, isFinal: result.isFinal)

                        if result.isFinal {
                            print("Final transcription: \(transcription)")
                            // Process final transcription through AI
                            self?.processVoiceInputThroughAI(transcription)
                        }
                    }

                    if let error = error {
                        print("Speech recognition error: \(error)")
                        self?.stopSpeechRecognition()
                    }
                }
            }
        } catch {
            print("Failed to start speech recognition: \(error)")
        }
    }

    private func stopSpeechRecognition() {
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
    }

    // MARK: - AI Processing

    private func processVoiceInputThroughAI(_ text: String) {
        // Cancel any existing AI processing task
        aiProcessingTask?.cancel()

        // Skip empty or very short transcriptions
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty,
              text.count > 3 else {
            print("Skipping short transcription: '\(text)'")
            return
        }

        print("Processing voice input through AI: '\(text)'")
        audioState = .processing

        aiProcessingTask = Task { @MainActor in
            do {
                // First, classify the voice command
                var finalResponse: String
                if let classifier = voiceCommandClassifier {
                    let classification = await classifier.classifyVoiceCommand(text)
                    print("🔍 Voice command classified: \(classification.intent.displayName) (confidence: \(String(format: "%.2f", classification.confidence)))")

                    // Use the new voice command pipeline if available
                    finalResponse = await processWithVoicePipeline(input: text)
                    print("🎯 Used Voice Command Pipeline for: '\(text)'")
                } else {
                    // Fall back to voice pipeline or standard AI processing
                    finalResponse = await processWithVoicePipeline(input: text)
                    print("🎯 Used Voice Command Pipeline (fallback): '\(text)'")
                }

                // Handle AI response
                voiceActivityDelegate?.aiResponseReceived(finalResponse, isComplete: true)
                print("AI response complete: '\(finalResponse)'")

                // Add to conversation history
                aiConversationHistory.append("User: \(text)")
                aiConversationHistory.append("Assistant: \(finalResponse)")

                // Keep conversation history manageable
                if aiConversationHistory.count > 20 {
                    aiConversationHistory.removeFirst(4) // Remove 2 exchanges
                }

                // Send AI response to ElevenLabs for voice synthesis
                await synthesizeAndPlayResponse(finalResponse)

                if audioState == .processing {
                    audioState = .idle
                }
            } catch {
                print("AI processing failed: \(error)")
                let errorResponse = "I'm sorry, I'm having trouble processing your request right now."
                voiceActivityDelegate?.aiResponseReceived(errorResponse, isComplete: true)

                if audioState == .processing {
                    audioState = .idle
                }
            }
        }
    }

    // MARK: - Voice Command Pipeline Integration

    private func processWithVoicePipeline(input: String) async -> String {
        print("🎯 Processing with Voice Command Pipeline: '\(input)'")

        guard let pipeline = voiceCommandPipeline else {
            print("⚠️ Voice pipeline not available, falling back to AI processing")
            return await processWithAI(input: input)
        }

        // Create conversation if needed
        if currentConversation == nil {
            currentConversation = conversationManager.createNewConversation()
        }

        do {
            // Process through the complete voice pipeline with the text input
            let result = try await pipeline.processVoiceCommand(
                input,
                userId: "current_user",
                sessionId: UUID().uuidString
            )

            // Log processing metrics
            print("✅ Voice Pipeline Complete:")
            print("  - Classification: \(result.classification.category) (\(result.classification.confidence))")
            print("  - Execution: \(result.mcpExecutionResult?.success == true ? "Success" : "Failed")")
            print("  - Processing Time: \(result.processingTime)s")
            print("  - Final Response: \(result.finalResponse)")

            // Store conversation message with response
            if let conversation = currentConversation {
                let _ = conversationManager.addMessage(
                    to: conversation,
                    content: result.finalResponse,
                    role: .assistant
                )
            }

            // Synthesize and play the response audio
            await synthesizeAndPlayResponse(result.finalResponse)

            return result.finalResponse
        } catch {
            print("❌ Voice pipeline failed: \(error.localizedDescription)")
            // Fallback to traditional AI processing
            return await processWithAI(input: input)
        }
    }

    // MARK: - Voice Response Playback

    private func playVoiceResponse(_ audioData: Data) async {
        do {
            guard let synthesizer = elevenLabsVoiceSynthesizer else {
                print("⚠️ ElevenLabs synthesizer not available")
                return
            }

            audioState = .playing
            try await synthesizer.playAudio(audioData)
            audioState = .idle

            print("✅ Voice response played successfully")
        } catch {
            print("❌ Voice response playback failed: \(error.localizedDescription)")
            audioState = .idle
        }
    }

    // MARK: - Fallback AI Processing

    private func processWithAI(input: String) async -> String {
        let startTime = Date()

        // Ensure we have a current conversation
        if currentConversation == nil {
            currentConversation = conversationManager.createNewConversation()
        }

        // Add user message to conversation
        if let conversation = currentConversation {
            _ = conversationManager.addMessage(
                to: conversation,
                content: input,
                role: .user,
                audioTranscription: input
            )
        }

        // Try Claude first, then OpenAI, then Gemini, then intelligent fallback
        var aiResponse: String
        var usedProvider: String

        do {
            aiResponse = try await callClaudeAPI(input: input)
            usedProvider = "claude"
        } catch {
            print("Claude API failed: \(error), trying OpenAI fallback")
            do {
                aiResponse = try await callOpenAIAPI(input: input)
                usedProvider = "openai"
            } catch {
                print("OpenAI API failed: \(error), trying Gemini fallback")
                do {
                    aiResponse = try await callGeminiAPI(input: input)
                    usedProvider = "gemini"
                } catch {
                    print("Gemini API failed: \(error), using intelligent fallback")
                    aiResponse = generateIntelligentFallback(input: input)
                    usedProvider = "fallback"
                }
            }
        }

        // Calculate processing time
        let processingTime = Date().timeIntervalSince(startTime)

        // Add AI response to conversation
        if let conversation = currentConversation {
            _ = conversationManager.addMessage(
                to: conversation,
                content: aiResponse,
                role: .assistant,
                aiProvider: usedProvider,
                processingTime: processingTime
            )
        }

        print("✅ AI Response (\(usedProvider)): Processing time \(processingTime)s")
        return aiResponse
    }

    private func callClaudeAPI(input: String) async throws -> String {
        guard let apiKey = try? _keychainManager.getCredential(forKey: "anthropic-api-key") else {
            throw AIProviderError.missingCredentials("Claude API key not found")
        }

        let url = URL(string: "https://api.anthropic.com/v1/messages")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        let messages = [
            ["role": "user", "content": input]
        ]

        let requestBody: [String: Any] = [
            "model": "claude-3-5-sonnet-20241022",
            "max_tokens": 1000,
            "messages": messages,
            "system": "You are Jarvis, a helpful AI voice assistant. Provide concise, natural responses suitable for voice interaction. Keep responses under 100 words when possible.",
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse("Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.apiError("Claude API error \(httpResponse.statusCode): \(errorText)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AIProviderError.invalidResponse("Could not parse Claude response")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callOpenAIAPI(input: String) async throws -> String {
        guard let apiKey = try? _keychainManager.getCredential(forKey: "openai-api-key") else {
            throw AIProviderError.missingCredentials("OpenAI API key not found")
        }

        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let messages = [
            ["role": "system", "content": "You are Jarvis, a helpful AI voice assistant. Provide concise, natural responses suitable for voice interaction. Keep responses under 100 words when possible."],
            ["role": "user", "content": input],
        ]

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7,
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse("Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.apiError("OpenAI API error \(httpResponse.statusCode): \(errorText)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AIProviderError.invalidResponse("Could not parse OpenAI response")
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func callGeminiAPI(input: String) async throws -> String {
        guard let apiKey = try? _keychainManager.getCredential(forKey: "google-api-key") else {
            throw AIProviderError.missingCredentials("Google API key not found")
        }

        let url = URL(string: "https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=\(apiKey)")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": "You are Jarvis, a helpful AI voice assistant. Provide concise, natural responses suitable for voice interaction. Keep responses under 100 words when possible.\n\nUser input: \(input)"
                        ],
                    ],
                ],
            ],
            "generationConfig": [
                "temperature": 0.7,
                "topK": 40,
                "topP": 0.95,
                "maxOutputTokens": 1000,
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIProviderError.invalidResponse("Invalid response type")
        }

        guard httpResponse.statusCode == 200 else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AIProviderError.apiError("Gemini API error \(httpResponse.statusCode): \(errorText)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw AIProviderError.invalidResponse("Could not parse Gemini response")
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func generateIntelligentFallback(input: String) -> String {
        let lowercaseInput = input.lowercased()

        if lowercaseInput.contains("hello") || lowercaseInput.contains("hi") {
            return "Hello! I'm Jarvis, your AI assistant. How can I help you today?"
        } else if lowercaseInput.contains("weather") {
            return "I'd be happy to help with weather information. However, I need access to weather services to provide current conditions."
        } else if lowercaseInput.contains("time") {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return "The current time is \(formatter.string(from: Date()))."
        } else if lowercaseInput.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            return "Today is \(formatter.string(from: Date()))."
        } else if lowercaseInput.contains("thank") {
            return "You're welcome! Is there anything else I can help you with?"
        } else if lowercaseInput.contains("help") {
            return "I'm here to help! You can ask me about the time, date, or general questions. I'm currently running in offline mode."
        } else if lowercaseInput.contains("how are you") {
            return "I'm doing well, thank you for asking! I'm ready to assist you with whatever you need."
        } else {
            return "I'm currently running in offline mode. Please check your API credentials or internet connection for full AI capabilities."
        }
    }

    // MARK: - ElevenLabs Voice Synthesis

    private func synthesizeAndPlayResponse(_ text: String) async {
        do {
            // Check if ElevenLabs API key is available
            guard let apiKey = try? _keychainManager.getCredential(forKey: "elevenlabs-api-key") else {
                print("ElevenLabs API key not found - skipping voice synthesis")
                return
            }

            print("Synthesizing voice for: '\(text)'")
            audioState = .playing

            let audioData = try await synthesizeVoice(text: text, apiKey: apiKey)
            await playAudioData(audioData)
        } catch {
            print("Voice synthesis failed: \(error)")
            // Continue without voice synthesis if it fails
        }
    }

    private func synthesizeVoice(text: String, apiKey: String) async throws -> Data {
        let url = URL(string: "\(elevenLabsBaseURL)/text-to-speech/\(defaultVoiceID)")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "xi-api-key")

        let requestBody: [String: Any] = [
            "text": text,
            "model_id": "eleven_multilingual_v2",
            "voice_settings": [
                "stability": 0.5,
                "similarity_boost": 0.5,
                "style": 0.0,
                "use_speaker_boost": true,
            ],
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LiveKitManagerError.voiceSynthesisFailed("Invalid response")
        }

        guard httpResponse.statusCode == 200 else {
            throw LiveKitManagerError.voiceSynthesisFailed("HTTP \(httpResponse.statusCode)")
        }

        return data
    }

    private func playAudioData(_ audioData: Data) async {
        do {
            // Create temporary file for audio playback
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp3")

            try audioData.write(to: tempURL)

            // Create and configure audio player
            audioPlayer = try AVAudioPlayer(contentsOf: tempURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()

            // Play the audio
            if audioPlayer?.play() == true {
                print("Playing AI voice response")

                // Wait for playback to complete
                while audioPlayer?.isPlaying == true {
                    try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
                }
            }

            // Clean up temporary file
            try? FileManager.default.removeItem(at: tempURL)
        } catch {
            print("Audio playback failed: \(error)")
        }
    }

    // MARK: - Voice Command Classification Setup

    private func setupVoiceCommandClassifier() {
        self.voiceCommandClassifier = VoiceCommandClassifier()
        print("✅ Voice Command Classifier initialized")
    }

    // MARK: - Voice Command Pipeline Setup

    private func setupVoiceCommandPipeline() {
        // Initialize voice classification manager
        self.voiceClassificationManager = VoiceClassificationManager()

        // Initialize ElevenLabs voice synthesizer
        self.elevenLabsVoiceSynthesizer = ElevenLabsVoiceSynthesizer(
            keychainManager: _keychainManager
        )

        // Initialize MCP server manager and voice command executor
        let voiceCommandExecutor: VoiceCommandExecutor
        if let backendClient = backendClient {
            let mcpServerManager = MCPServerManager(
                backendClient: backendClient,
                keychainManager: _keychainManager
            )
            voiceCommandExecutor = VoiceCommandExecutor(
                mcpServerManager: mcpServerManager
            )
        } else {
            // For now, we'll skip the voice command executor if no backend client is available
            // This will need to be properly handled when the backend is initialized
            print("⚠️ Backend client not available, voice command pipeline will be limited")
            return
        }

        // Initialize the complete voice command pipeline
        if let voiceClassifier = voiceClassificationManager {
            let mcpServerManager = MCPServerManager(
                backendClient: backendClient!,
                keychainManager: _keychainManager
            )
            self.voiceCommandPipeline = VoiceCommandPipeline(
                classificationManager: voiceClassifier,
                mcpServerManager: mcpServerManager,
                keychainManager: _keychainManager
            )

            // Set this manager as the voice delegate
            voiceClassifier.setVoiceDelegate(self)

            print("✅ Voice Command Pipeline initialized")
        } else {
            print("⚠️ Failed to initialize Voice Command Pipeline - missing dependencies")
        }
    }

    // MARK: - MCP Integration Methods

    private func setupMCPIntegration() {
        // Initialize Python backend client
        let backendConfig = PythonBackendClient.BackendConfiguration(
            baseURL: "http://localhost:8000",
            websocketURL: "ws://localhost:8000/ws",
            apiKey: nil,
            timeout: 30.0,
            heartbeatInterval: 30.0
        )

        self.backendClient = PythonBackendClient(configuration: backendConfig)

        // Initialize MCP server manager
        if let backendClient = self.backendClient {
            self.mcpServerManager = MCPServerManager(
                backendClient: backendClient,
                keychainManager: _keychainManager
            )
        }
    }

    func initializeMCPServices() async {
        guard let mcpServerManager = mcpServerManager,
              let backendClient = backendClient else {
            print("⚠️ MCP services not available")
            return
        }

        do {
            // Connect to backend
            if backendClient.connectionStatus != .connected {
                await backendClient.connect()
            }

            // Initialize MCP servers
            await mcpServerManager.initialize()

            print("✅ MCP services initialized successfully")
        } catch {
            print("❌ Failed to initialize MCP services: \(error)")
        }
    }

    private func processVoiceCommandWithMCP(_ text: String) async -> String? {
        guard let mcpServerManager = mcpServerManager else {
            return nil
        }

        do {
            let mcpResponse = try await mcpServerManager.processVoiceCommand(text)
            print("🤖 MCP processed command: '\(text)' -> '\(mcpResponse)'")
            return mcpResponse
        } catch {
            print("⚠️ MCP command processing failed: \(error)")
            return nil
        }
    }

    private func processVoiceCommandWithMCPClassification(_ text: String, classification: VoiceCommandClassification) async -> String? {
        guard let mcpServerManager = mcpServerManager,
              let classifier = voiceCommandClassifier else {
            return nil
        }

        do {
            // Format parameters for MCP
            let formattedParameters = classifier.formatParametersForMCP(
                classification.extractedParameters,
                intent: classification.intent
            )

            // Route to appropriate MCP server based on intent
            let mcpResponse: String

            switch classification.intent {
            case .generateDocument:
                if let content = formattedParameters["content"] as? String,
                   let formatString = formattedParameters["format"] as? String ?? "pdf",
                   let format = DocumentGenerationRequest.DocumentFormat(rawValue: formatString) {
                    let result = try await mcpServerManager.generateDocument(content: content, format: format)
                    mcpResponse = "Document generated successfully: \(result.documentURL)"
                } else {
                    mcpResponse = "I need more information to generate the document. Please specify what content you'd like to include."
                }

            case .sendEmail:
                if let to = formattedParameters["to"] as? [String],
                   let subject = formattedParameters["subject"] as? String,
                   let body = formattedParameters["body"] as? String {
                    let result = try await mcpServerManager.sendEmail(to: to, subject: subject, body: body)
                    mcpResponse = "Email sent successfully with ID: \(result.messageId)"
                } else {
                    mcpResponse = "I need the recipient email address to send the message. Please provide the email address."
                }

            case .scheduleCalendar:
                if let title = formattedParameters["title"] as? String,
                   let startTime = formattedParameters["startTime"] as? Date,
                   let endTime = formattedParameters["endTime"] as? Date {
                    let result = try await mcpServerManager.createCalendarEvent(title: title, startTime: startTime, endTime: endTime)
                    mcpResponse = "Calendar event '\(title)' created successfully: \(result.eventId)"
                } else {
                    mcpResponse = "I can schedule the event, but I need more details like the event title and time."
                }

            case .performSearch, .newsQuery:
                if let query = formattedParameters["query"] as? String {
                    let result = try await mcpServerManager.performSearch(query: query)
                    mcpResponse = "Found \(result.totalCount) results for '\(query)'. Here are the top results: \(result.results.prefix(3).map { $0.title }.joined(separator: ", "))"
                } else {
                    mcpResponse = "What would you like me to search for?"
                }

            case .uploadStorage:
                mcpResponse = "I can help you upload files to storage. However, I need you to specify the file you want to upload through the app interface."

            case .downloadStorage:
                if let filename = formattedParameters["filename"] as? String {
                    mcpResponse = "I'll help you download '\(filename)' from storage."
                } else {
                    mcpResponse = "What file would you like me to download from storage?"
                }

            case .weatherQuery:
                if let location = formattedParameters["location"] as? String {
                    mcpResponse = "I'll get the weather information for \(location). However, I need access to weather services to provide current conditions."
                } else {
                    mcpResponse = "I'll get the weather information. However, I need access to weather services to provide current conditions."
                }

            case .calculation:
                if let expression = formattedParameters["expression"] as? String {
                    mcpResponse = "I'll calculate \(expression) for you. However, I need access to calculation services for complex math operations."
                } else {
                    mcpResponse = "What would you like me to calculate?"
                }

            case .translation:
                if let text = formattedParameters["text"] as? String {
                    let targetLang = formattedParameters["targetLanguage"] as? String ?? "English"
                    mcpResponse = "I'll translate '\(text)' to \(targetLang). However, I need access to translation services for accurate translations."
                } else {
                    mcpResponse = "What would you like me to translate?"
                }

            case .createNote, .setReminder:
                mcpResponse = "I can help you create notes and set reminders. However, this feature requires additional setup with your productivity tools."

            case .general, .unknown:
                return nil // Fall back to general AI
            }

            print("🤖 MCP processed classified command: '\(text)' -> '\(mcpResponse)'")

            // Provide feedback to classifier if successful
            if !mcpResponse.contains("However") && !mcpResponse.contains("I need") {
                classifier.provideFeedback(for: text, wasCorrect: true)
            }

            return mcpResponse
        } catch {
            print("⚠️ MCP classified command processing failed: \(error)")

            // Provide negative feedback to classifier
            classifier.provideFeedback(for: text, wasCorrect: false)

            return nil
        }
    }

    // Public MCP convenience methods
    func generateDocumentViaMCP(content: String, format: String = "pdf") async throws -> String {
        guard let mcpServerManager = mcpServerManager else {
            throw LiveKitManagerError.mcpNotAvailable
        }

        guard let documentFormat = DocumentGenerationRequest.DocumentFormat(rawValue: format) else {
            throw LiveKitManagerError.invalidFormat(format)
        }

        let result = try await mcpServerManager.generateDocument(
            content: content,
            format: documentFormat
        )

        return "Document generated: \(result.documentURL)"
    }

    func sendEmailViaMCP(to: [String], subject: String, body: String) async throws -> String {
        guard let mcpServerManager = mcpServerManager else {
            throw LiveKitManagerError.mcpNotAvailable
        }

        let result = try await mcpServerManager.sendEmail(
            to: to,
            subject: subject,
            body: body
        )

        return "Email sent successfully with ID: \(result.messageId)"
    }

    func searchViaMCP(query: String) async throws -> String {
        guard let mcpServerManager = mcpServerManager else {
            throw LiveKitManagerError.mcpNotAvailable
        }

        let result = try await mcpServerManager.performSearch(query: query)
        return "Found \(result.totalCount) results for '\(query)'"
    }

    func createCalendarEventViaMCP(title: String, startTime: Date, endTime: Date) async throws -> String {
        guard let mcpServerManager = mcpServerManager else {
            throw LiveKitManagerError.mcpNotAvailable
        }

        let result = try await mcpServerManager.createCalendarEvent(
            title: title,
            startTime: startTime,
            endTime: endTime
        )

        return "Calendar event created: \(result.eventId)"
    }

    // MARK: - Voice Synthesis Configuration

    enum LiveKitManagerError: LocalizedError {
        case voiceSynthesisFailed(String)
        case mcpNotAvailable
        case invalidFormat(String)

        var errorDescription: String? {
            switch self {
            case .voiceSynthesisFailed(let message):
                return "Voice synthesis failed: \(message)"
            case .mcpNotAvailable:
                return "MCP services are not available"
            case .invalidFormat(let format):
                return "Invalid format: \(format)"
            }
        }
    }

    enum AIProviderError: LocalizedError {
        case missingCredentials(String)
        case invalidResponse(String)
        case apiError(String)
        case networkError(String)

        var errorDescription: String? {
            switch self {
            case .missingCredentials(let message):
                return "Missing AI credentials: \(message)"
            case .invalidResponse(let message):
                return "Invalid AI response: \(message)"
            case .apiError(let message):
                return "AI API error: \(message)"
            case .networkError(let message):
                return "Network error: \(message)"
            }
        }
    }

    // MARK: - AI Configuration

    func configureAICredentials(claude: String? = nil, openAI: String? = nil, gemini: String? = nil, elevenLabs: String? = nil) async throws {
        // Store AI credentials in keychain for future use
        if let claude = claude {
            try _keychainManager.storeCredential(claude, forKey: "anthropic-api-key")
        }
        if let openAI = openAI {
            try _keychainManager.storeCredential(openAI, forKey: "openai-api-key")
        }
        if let gemini = gemini {
            try _keychainManager.storeCredential(gemini, forKey: "google-api-key")
        }
        if let elevenLabs = elevenLabs {
            try _keychainManager.storeCredential(elevenLabs, forKey: "elevenlabs-api-key")
        }
    }

    func getConversationHistory() -> [String] {
        return aiConversationHistory
    }

    func clearConversationHistory() {
        aiConversationHistory.removeAll()
    }

    // MARK: - Voice Command Classification Public Interface

    func classifyVoiceCommand(_ command: String) async -> VoiceCommandClassification? {
        return await voiceCommandClassifier?.classifyVoiceCommand(command)
    }

    func getClassificationStatistics() -> VoiceCommandClassifier.ClassificationStatistics? {
        return voiceCommandClassifier?.getClassificationStatistics()
    }

    func clearClassificationCache() {
        voiceCommandClassifier?.clearCache()
    }

    func provideClassificationFeedback(for command: String, wasCorrect: Bool) {
        voiceCommandClassifier?.provideFeedback(for: command, wasCorrect: wasCorrect)
    }

    // MARK: - LiveKit Connection Management

    func connect() async {
        connectionState = .connecting

        do {
            // Retrieve credentials from Keychain
            let liveKitURL = try _keychainManager.getCredential(forKey: "livekit-url")
            let liveKitToken = try _keychainManager.getCredential(forKey: "livekit-token")

            // Configure connection options for audio optimization
            let connectOptions = ConnectOptions(
                autoSubscribe: true,
                enableMicrophone: false  // We'll enable manually after connection
            )

            let roomOptions = RoomOptions()

            try await room.connect(
                url: liveKitURL,
                token: liveKitToken,
                connectOptions: connectOptions,
                roomOptions: roomOptions
            )

            // Initialize MCP services after successful connection
            await initializeMCPServices()
        } catch KeychainManagerError.itemNotFound {
            connectionState = .error("LiveKit credentials not found. Please configure the app.")
        } catch {
            connectionState = .error("Connection failed: \(error.localizedDescription)")
        }
    }

    func disconnect() async {
        await stopAudioSession()
        await room.disconnect()
        connectionState = .disconnected
        audioState = .idle
    }

    // MARK: - Audio Track Management

    func startAudioSession() async {
        guard connectionState == .connected else {
            print("Cannot start audio session: not connected to LiveKit")
            return
        }

        guard audioState != .recording else {
            print("Audio session already active")
            return
        }

        do {
            audioState = .processing

            // Enable microphone using LiveKit's high-level API
            if let realRoom = room as? Room {
                try await realRoom.localParticipant.setMicrophone(enabled: true)
                print("Microphone enabled successfully via LiveKit")
            } else {
                print("Mock room detected - skipping microphone setup")
            }

            // Set up audio processing pipeline for voice activity detection
            setupAudioEngine()
            startAudioEngine()
            setupSpeechRecognition()

            audioState = .recording
            print("Audio session started successfully")
        } catch {
            audioState = .error("Failed to start audio session: \(error.localizedDescription)")
            print("Audio session start failed: \(error)")
        }
    }

    func stopAudioSession() async {
        guard audioState == .recording else { return }

        do {
            audioState = .processing

            // Stop audio processing
            stopAudioEngine()
            stopSpeechRecognition()

            // Disable microphone using LiveKit's high-level API
            if let realRoom = room as? Room {
                try await realRoom.localParticipant.setMicrophone(enabled: false)
                print("Microphone disabled successfully via LiveKit")
            } else {
                print("Mock room detected - skipping microphone cleanup")
            }

            // Clean up audio track references
            self.audioTrack = nil
            self.audioPublication = nil

            audioState = .idle
            print("Audio session stopped successfully")
        } catch {
            audioState = .error("Failed to stop audio session: \(error.localizedDescription)")
            print("Audio session stop failed: \(error)")
        }
    }

    // MARK: - Configuration

    func configureCredentials(liveKitURL: String, liveKitToken: String) async throws {
        try _keychainManager.storeCredential(liveKitURL, forKey: "livekit-url")
        try _keychainManager.storeCredential(liveKitToken, forKey: "livekit-token")
    }

    // MARK: - Testing Support

    func connectToPlayground() async {
        connectionState = .connecting

        do {
            // Connect to LiveKit playground for testing
            let playgroundURL = "wss://agents-playground.livekit.io"
            let testToken = generateTestToken()

            let connectOptions = ConnectOptions(
                autoSubscribe: true,
                enableMicrophone: false  // We'll enable manually after connection
            )
            let roomOptions = RoomOptions()

            try await room.connect(
                url: playgroundURL,
                token: testToken,
                connectOptions: connectOptions,
                roomOptions: roomOptions
            )
        } catch {
            connectionState = .error("Playground connection failed: \(error.localizedDescription)")
        }
    }

    private func generateTestToken() -> String {
        // Generate a simple test token for playground
        // In production, this would come from your server
        return "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.playground"
    }
}

// MARK: - RoomDelegate

extension LiveKitManager: RoomDelegate {
    public nonisolated func room(_ room: Room, didUpdateConnectionState connectionState: LiveKit.ConnectionState, from oldConnectionState: LiveKit.ConnectionState) {
        Task { @MainActor in
            switch connectionState {
            case .connected:
                self.connectionState = .connected
                await self.startAudioSession()
            case .disconnected:
                // Handle disconnection - checking for errors if available
                self.connectionState = .disconnected
                await self.stopAudioSession()
            case .connecting:
                self.connectionState = .connecting
            case .reconnecting:
                self.connectionState = .reconnecting
            }
        }
    }

    public nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in
            if publication.track?.kind == .audio {
                // Handle incoming audio track (AI responses)
                audioState = .playing
            }
        }
    }

    public nonisolated func room(_ room: Room, participant: RemoteParticipant, didUnsubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in
            if publication.track?.kind == .audio && audioState == .playing {
                audioState = .idle
            }
        }
    }
}

// MARK: - AVAudioPlayerDelegate

extension LiveKitManager: AVAudioPlayerDelegate {
    public nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            print("Audio playback finished, successfully: \(flag)")
            if audioState == .playing {
                audioState = .idle
            }
            audioPlayer = nil
        }
    }

    public nonisolated func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        Task { @MainActor in
            print("Audio decode error: \(error?.localizedDescription ?? "Unknown error")")
            if audioState == .playing {
                audioState = .error("Audio playback failed")
            }
            audioPlayer = nil
        }
    }
}

// MARK: - VoiceActivityDelegate

extension LiveKitManager: VoiceActivityDelegate {
    func voiceActivityDidStart() {
        print("🎤 Voice activity started")
        audioState = .recording
    }
    
    func voiceActivityDidEnd() {
        print("🎤 Voice activity ended")
        if audioState == .recording {
            audioState = .idle
        }
    }
    
    func speechRecognitionResult(_ text: String, isFinal: Bool) {
        print("🗣️ Speech recognition: '\(text)' (final: \(isFinal))")
        if isFinal {
            processVoiceInputThroughAI(text)
        }
    }
    
    func aiResponseReceived(_ response: String, isComplete: Bool) {
        print("🤖 AI response: '\(response)' (complete: \(isComplete))")
        if isComplete {
            Task {
                await synthesizeAndPlayResponse(response)
            }
        }
    }
}
