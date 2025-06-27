/*
* Purpose: Supporting UI components for post-classification flows
* Issues & Complexity Summary: Reusable components for different flow states with animations
* Key Complexity Drivers:
  - Logic Scope (Est. LoC): ~500
  - Core Algorithm Complexity: Medium (state-specific UI, animations)
  - Dependencies: 3 New (SwiftUI animations, flow states, accessibility)
  - State Management Complexity: Medium (individual component states)
  - Novelty/Uncertainty Factor: Low (standard SwiftUI patterns)
* AI Pre-Task Self-Assessment: 90%
* Problem Estimate: 75%
* Initial Code Complexity Estimate: 80%
* Final Code Complexity: TBD
* Overall Result Score: TBD
* Key Variances/Learnings: TBD
* Last Updated: 2025-06-26
*/

import SwiftUI

// MARK: - Confidence Indicator

struct ConfidenceIndicatorView: View {
    let confidence: Double
    @State private var animatedConfidence: Double = 0

    var body: some View {
        HStack(spacing: 8) {
            // Confidence meter
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.quaternary)
                    .frame(width: 60, height: 6)

                Capsule()
                    .fill(confidenceColor)
                    .frame(width: 60 * animatedConfidence, height: 6)
                    .animation(.easeInOut(duration: 0.8), value: animatedConfidence)
            }

            // Confidence percentage
            Text("\(Int(confidence * 100))%")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(confidenceColor)
                .monospacedDigit()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                animatedConfidence = confidence
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Confidence \(Int(confidence * 100)) percent")
    }

    private var confidenceColor: Color {
        switch confidence {
        case 0.8...1.0: return .green
        case 0.5..<0.8: return .orange
        case 0.3..<0.5: return .yellow
        default: return .red
        }
    }
}

// MARK: - Processing View

struct ProcessingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 24) {
            // Processing animation
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.blue.opacity(0.3), .blue]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 60 + CGFloat(index * 20))
                        .rotationEffect(.degrees(rotationAngle + Double(index * 120)))
                        .scaleEffect(scale)
                }
            }
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    rotationAngle = 360
                }
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    scale = 1.1
                }
            }

            Text("Analyzing your command...")
                .font(.headline)
                .foregroundColor(.primary)

            Text("Understanding your intent and extracting parameters")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .modifier(GlassViewModifier())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Processing voice command")
    }
}

// MARK: - Preview View

struct PreviewView: View {
    let data: PreviewData
    let onExecute: () -> Void
    @State private var showingDetails = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text(data.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(data.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Preview content (category-specific)
                if let previewContent = data.previewContent {
                    previewContent
                        .transition(.scale.combined(with: .opacity))
                }

                // Parameters
                if !data.parameters.isEmpty {
                    ParametersView(parameters: data.parameters, showingDetails: $showingDetails)
                }

                // Execute button
                Button(action: onExecute) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Execute Command")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .blue.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        in: RoundedRectangle(cornerRadius: 12)
                    )
                }
                .accessibilityLabel("Execute command")
                .accessibilityHint("Starts executing the voice command")
            }
            .padding()
        }
        .modifier(GlassViewModifier())
    }
}

// MARK: - Confirmation View

struct ConfirmationView: View {
    let data: ConfirmationData
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Icon
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
                .scaleEffect(1.0)
                .animation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true), value: UUID())

            // Content
            VStack(spacing: 12) {
                Text(data.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(data.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Buttons
            HStack(spacing: 16) {
                // Cancel button
                Button(action: onCancel) {
                    Text(data.cancelButtonTitle)
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.white.opacity(0.2), lineWidth: 1)
                        )
                }
                .accessibilityLabel(data.cancelButtonTitle)

                // Confirm button
                Button(action: onConfirm) {
                    Text(data.confirmButtonTitle)
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            data.destructive ? .red : .blue,
                            in: RoundedRectangle(cornerRadius: 12)
                        )
                }
                .accessibilityLabel(data.confirmButtonTitle)
            }
        }
        .padding()
        .modifier(GlassViewModifier())
    }
}

// MARK: - Execution View

struct ExecutionView: View {
    let data: ExecutionData
    let onCancel: () -> Void
    @State private var animatedProgress: Double = 0

    var body: some View {
        VStack(spacing: 24) {
            // Progress ring
            ZStack {
                Circle()
                    .stroke(.quaternary, lineWidth: 8)
                    .frame(width: 120, height: 120)

                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.blue, .cyan]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: animatedProgress)

                VStack {
                    Text("\(Int(data.progress * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .monospacedDigit()

                    Text("Complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Status
            VStack(spacing: 8) {
                Text(data.title)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(data.message)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                if let timeRemaining = data.estimatedTimeRemaining, timeRemaining > 0 {
                    Text("Estimated time remaining: \(Int(timeRemaining))s")
                        .font(.caption)
                        .foregroundColor(.tertiary)
                }
            }

            // Cancel button (if allowed)
            if data.canCancel {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.red.opacity(0.3), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Cancel execution")
            }
        }
        .padding()
        .modifier(GlassViewModifier())
        .onChange(of: data.progress) { newProgress in
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = newProgress
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                animatedProgress = data.progress
            }
        }
    }
}

// MARK: - Result View

struct ResultView: View {
    let data: ResultData
    @State private var showingContent = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Success/failure icon
                Image(systemName: data.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(data.success ? .green : .red)
                    .scaleEffect(showingContent ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showingContent)

                // Title and message
                VStack(spacing: 12) {
                    Text(data.title)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(data.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .opacity(showingContent ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.8).delay(0.3), value: showingContent)

                // Result content
                if let resultContent = data.resultContent {
                    resultContent
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // Action buttons
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 12) {
                    ForEach(data.actions.indices, id: \.self) { index in
                        let action = data.actions[index]

                        Button(action: action.action) {
                            HStack {
                                Image(systemName: action.icon)
                                Text(action.title)
                            }
                            .font(.headline)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel(action.title)
                    }
                }
            }
            .padding()
        }
        .modifier(GlassViewModifier())
        .onAppear {
            showingContent = true
        }
    }
}

// MARK: - Error View

struct ErrorView: View {
    let data: ErrorData
    let onRetry: () -> Void
    let onDismiss: () -> Void
    @State private var showingSuggestions = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Error icon
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

                // Title and message
                VStack(spacing: 12) {
                    Text(data.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(data.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Error details
                DisclosureGroup("Error Details", isExpanded: $showingSuggestions) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(data.error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        if !data.suggestions.isEmpty {
                            Text("Suggestions:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)

                            ForEach(data.suggestions, id: \.self) { suggestion in
                                Text("• \(suggestion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))

                // Action buttons
                HStack(spacing: 16) {
                    Button(action: onDismiss) {
                        Text("Dismiss")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Dismiss error")

                    if data.canRetry {
                        Button(action: onRetry) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Retry")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(.blue, in: RoundedRectangle(cornerRadius: 12))
                        }
                        .accessibilityLabel("Retry command")
                    }
                }
            }
            .padding()
        }
        .modifier(GlassViewModifier())
    }
}

// MARK: - Clarification View

struct ClarificationView: View {
    let data: ClarificationData
    let onSelection: (String) -> Void
    @State private var manualInput = ""
    @State private var showingManualInput = false

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Question icon
                Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

                // Title and message
                VStack(spacing: 12) {
                    Text(data.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text(data.message)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Suggestions
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 12) {
                    ForEach(data.suggestions, id: \.self) { suggestion in
                        Button(action: { onSelection(suggestion) }) {
                            HStack {
                                Image(systemName: "lightbulb")
                                    .foregroundColor(.orange)

                                Text(suggestion)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(.white.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .accessibilityLabel("Try suggestion: \(suggestion)")
                    }
                }

                // Manual input option
                if data.allowManualInput {
                    VStack(spacing: 12) {
                        Button(action: { showingManualInput.toggle() }) {
                            HStack {
                                Image(systemName: "pencil")
                                Text("Type your own command")
                                Spacer()
                                Image(systemName: showingManualInput ? "chevron.down" : "chevron.right")
                                    .rotationEffect(.degrees(showingManualInput ? 0 : -90))
                                    .animation(.easeInOut(duration: 0.3), value: showingManualInput)
                            }
                            .font(.headline)
                            .foregroundColor(.blue)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        }

                        if showingManualInput {
                            VStack(spacing: 12) {
                                TextField("Enter your command", text: $manualInput)
                                    .textFieldStyle(.roundedBorder)

                                Button(action: { onSelection(manualInput) }) {
                                    Text("Submit")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(.blue, in: RoundedRectangle(cornerRadius: 8))
                                }
                                .disabled(manualInput.isEmpty)
                            }
                            .transition(.move(edge: .top).combined(with: .opacity))
                        }
                    }
                }
            }
            .padding()
        }
        .modifier(GlassViewModifier())
        .animation(.easeInOut(duration: 0.3), value: showingManualInput)
    }
}

// MARK: - Parameters View

struct ParametersView: View {
    let parameters: [String: AnyCodable]
    @Binding var showingDetails: Bool

    var body: some View {
        VStack(spacing: 12) {
            Button(action: { showingDetails.toggle() }) {
                HStack {
                    Image(systemName: "gear")
                        .foregroundColor(.blue)

                    Text("Command Parameters")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()

                    Text("\(parameters.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.quaternary, in: Capsule())

                    Image(systemName: showingDetails ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .rotationEffect(.degrees(showingDetails ? 0 : -90))
                        .animation(.easeInOut(duration: 0.3), value: showingDetails)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.white.opacity(0.2), lineWidth: 1)
                )
            }
            .accessibilityLabel("Toggle command parameters")

            if showingDetails {
                LazyVGrid(columns: [GridItem(.flexible())], spacing: 8) {
                    ForEach(Array(parameters.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text(key.capitalized)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Text(String(describing: parameters[key]?.value ?? ""))
                                .font(.caption)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showingDetails)
    }
}

#Preview("Confidence Indicator") {
    VStack(spacing: 20) {
        ConfidenceIndicatorView(confidence: 0.95)
        ConfidenceIndicatorView(confidence: 0.72)
        ConfidenceIndicatorView(confidence: 0.45)
        ConfidenceIndicatorView(confidence: 0.18)
    }
    .padding()
    .modifier(GlassViewModifier())
}

#Preview("Processing View") {
    ProcessingView()
}

#Preview("Parameters View") {
    ParametersView(
        parameters: [
            "format": AnyCodable("PDF"),
            "content": AnyCodable("quarterly results"),
            "title": AnyCodable("Q3 Report"),
        ],
        showingDetails: .constant(true)
    )
    .padding()
    .modifier(GlassViewModifier())
}
