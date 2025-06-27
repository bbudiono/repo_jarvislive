// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Complete voice recording interface with controls, transcription, and AI response
 * Issues & Complexity Summary: Complex extracted component handling voice recording UI state
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~120
 *   - Core Algorithm Complexity: Medium (voice state management, audio level display)
 *   - Dependencies: 2 (SwiftUI, VoiceActivityCoordinator)
 *   - State Management Complexity: High (voice recording state, audio levels, transcription)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 85%
 * Problem Estimate (Inherent Problem Difficulty %): 75%
 * Initial Code Complexity Estimate %: 80%
 * Justification for Estimates: Complex voice UI component with multiple state dependencies
 * Final Code Complexity (Actual %): 82%
 * Overall Result Score (Success & Quality %): 92%
 * Key Variances/Learnings: Voice coordinator and audio level need to be passed via bindings
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct VoiceRecordingView: View {
    @ObservedObject var voiceCoordinator: VoiceActivityCoordinator
    let audioLevel: Float
    let onToggleRecording: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            // Voice Recording Button
            VStack(spacing: 15) {
                Button(action: onToggleRecording) {
                    ZStack {
                        // Voice Activity Indicator
                        if voiceCoordinator.showVoiceActivity && voiceCoordinator.isRecording {
                            Circle()
                                .stroke(Color.red.opacity(0.6), lineWidth: 3)
                                .frame(width: 100, height: 100)
                                .scaleEffect(1.2)
                                .animation(
                                    Animation.easeInOut(duration: 0.8)
                                        .repeatForever(autoreverses: true),
                                    value: voiceCoordinator.showVoiceActivity
                                )
                                .accessibilityIdentifier("VoiceActivityIndicator")
                        }

                        // Recording State Indicator
                        Circle()
                            .fill(voiceCoordinator.isRecording ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                            .frame(width: 80, height: 80)
                            .accessibilityIdentifier("RecordingStateIndicator")

                        // Record/Stop Icon
                        Image(systemName: voiceCoordinator.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(GlassmorphicButtonStyle())
                .accessibilityIdentifier(voiceCoordinator.isRecording ? "Stop Recording" : "Record")
                .accessibilityLabel(voiceCoordinator.isRecording ? "Stop Recording" : "Start Recording")

                Text(voiceCoordinator.isRecording ? "Recording..." : "Tap to Record")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))

                // Audio Level Meter
                if voiceCoordinator.isRecording {
                    VStack(spacing: 5) {
                        Text("Audio Level")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))

                        ProgressView(value: abs(audioLevel) / 60.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .cyan))
                            .frame(height: 8)
                            .accessibilityIdentifier("AudioLevelMeter")
                    }
                }
            }
            .modifier(GlassViewModifier())

            // Transcription Display
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "text.quote")
                        .foregroundColor(.cyan)
                    Text("Transcription")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ScrollView {
                    Text(voiceCoordinator.currentTranscription.isEmpty ? "Your voice will appear here..." : voiceCoordinator.currentTranscription)
                        .font(.body)
                        .foregroundColor(voiceCoordinator.currentTranscription.isEmpty ? .white.opacity(0.5) : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
                .frame(minHeight: 60, maxHeight: 120)
                .accessibilityIdentifier("TranscriptionDisplay")
                .accessibilityLabel("Speech transcription")
            }
            .modifier(GlassViewModifier())

            // AI Response Display
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.purple)
                    Text("AI Response")
                        .font(.headline)
                        .foregroundColor(.white)
                }

                ScrollView {
                    Text(voiceCoordinator.currentAIResponse.isEmpty ? "AI response will appear here..." : voiceCoordinator.currentAIResponse)
                        .font(.body)
                        .foregroundColor(voiceCoordinator.currentAIResponse.isEmpty ? .white.opacity(0.5) : .white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 10)
                }
                .frame(minHeight: 60, maxHeight: 120)
                .accessibilityIdentifier("AIResponseDisplay")
                .accessibilityLabel("AI assistant response")
            }
            .modifier(GlassViewModifier())
        }
    }
}

struct VoiceRecordingView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceRecordingView(
            voiceCoordinator: VoiceActivityCoordinator(),
            audioLevel: 30.0,
            onToggleRecording: {}
        )
        .preferredColorScheme(.dark)
    }
}
