// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Step editor for creating and modifying individual workflow steps with parameter configuration
 * Issues & Complexity Summary: Dynamic step configuration, parameter validation, intent selection, dependency management
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~500+
 *   - Core Algorithm Complexity: Medium (Form validation, parameter handling, intent configuration)
 *   - Dependencies: 3 New (SwiftUI, Combine, NaturalLanguage)
 *   - State Management Complexity: Medium (Step properties, validation states, parameter editing)
 *   - Novelty/Uncertainty Factor: Medium (Step configuration patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 72%
 * Justification for Estimates: Complex form with dynamic validation and parameter configuration
 * Final Code Complexity (Actual %): 78%
 * Overall Result Score (Success & Quality %): 91%
 * Key Variances/Learnings: Step editor requires careful form state management and validation
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine

// MARK: - Step Editor View

struct StepEditorView: View {
    @Binding var step: VoiceWorkflowStep?
    let isNewStep: Bool
    let onSave: (VoiceWorkflowStep?) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var stepTitle: String = ""
    @State private var stepDescription: String = ""
    @State private var expectedInput: String = ""
    @State private var selectedIntent: CommandIntent = .general
    @State private var isOptional: Bool = false
    @State private var estimatedDuration: Double = 30.0
    @State private var parameters: [String: String] = [:]
    @State private var validationErrors: [String] = []
    @State private var showingParameterEditor: Bool = false
    @State private var newParameterKey: String = ""
    @State private var newParameterValue: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                stepEditorBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Basic information
                        basicInfoSection

                        // Voice input configuration
                        voiceInputSection

                        // Intent and parameters
                        intentParametersSection

                        // Advanced settings
                        advancedSettingsSection

                        // Validation
                        validationSection
                    }
                    .padding()
                }
            }
            .navigationTitle(isNewStep ? "New Step" : "Edit Step")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onSave(nil)
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveStep()
                    }
                    .foregroundColor(.green)
                    .disabled(!validationErrors.isEmpty)
                }
            }
        }
        .onAppear {
            setupForEditing()
        }
        .onChange(of: stepTitle) { _ in validateStep() }
        .onChange(of: stepDescription) { _ in validateStep() }
        .onChange(of: expectedInput) { _ in validateStep() }
        .sheet(isPresented: $showingParameterEditor) {
            ParameterEditorView(
                key: $newParameterKey,
                value: $newParameterValue,
                parameters: $parameters
            )
        }
    }

    // MARK: - View Components

    private var stepEditorBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.06, green: 0.08, blue: 0.20),
                Color(red: 0.08, green: 0.06, blue: 0.18),
                Color(red: 0.04, green: 0.04, blue: 0.12),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var basicInfoSection: some View {
        stepEditorCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Basic Information")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Text("🧪 SANDBOX")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .cornerRadius(4)
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Title
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step Title *")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter step title", text: $stepTitle)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description *")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter step description", text: $stepDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                            .lineLimit(2...4)
                    }
                }
            }
            .padding()
        }
    }

    private var voiceInputSection: some View {
        stepEditorCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "mic.fill")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Voice Input")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Expected Voice Command *")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("What should the user say?", text: $expectedInput, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                            .lineLimit(2...3)
                    }

                    // Voice command suggestions
                    if !expectedInput.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Suggested Variations:")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(generateVoiceVariations(), id: \.self) { variation in
                                        Button(action: { expectedInput = variation }) {
                                            Text(variation)
                                                .font(.caption)
                                                .foregroundColor(.cyan)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.cyan.opacity(0.2))
                                                .cornerRadius(6)
                                        }
                                    }
                                }
                                .padding(.horizontal, 2)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var intentParametersSection: some View {
        stepEditorCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "brain.head.profile")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Text("Intent & Parameters")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Intent selection
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Command Intent")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        Picker("Intent", selection: $selectedIntent) {
                            ForEach(CommandIntent.allCases, id: \.self) { intent in
                                HStack {
                                    Image(systemName: iconForIntent(intent))
                                    Text(intent.rawValue)
                                }.tag(intent)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .foregroundColor(.cyan)
                    }

                    // Parameters
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Parameters")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Button(action: { showingParameterEditor = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add")
                                }
                                .font(.caption)
                                .foregroundColor(.green)
                            }
                        }

                        if parameters.isEmpty {
                            Text("No parameters configured")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                                .italic()
                        } else {
                            LazyVStack(spacing: 6) {
                                ForEach(Array(parameters.keys), id: \.self) { key in
                                    parameterRow(key: key, value: parameters[key] ?? "")
                                }
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var advancedSettingsSection: some View {
        stepEditorCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Advanced Settings")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Optional toggle
                    HStack {
                        Toggle("Optional Step", isOn: $isOptional)
                            .foregroundColor(.white)

                        Spacer()

                        if isOptional {
                            Text("OPTIONAL")
                                .font(.caption2)
                                .foregroundColor(.orange)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }

                    // Duration estimation
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Estimated Duration")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Spacer()

                            Text("\(Int(estimatedDuration))s")
                                .font(.subheadline)
                                .foregroundColor(.cyan)
                        }

                        Slider(value: $estimatedDuration, in: 5...300, step: 5)
                            .accentColor(.cyan)
                    }

                    // Duration guidelines
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Duration Guidelines:")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))

                        HStack {
                            durationGuide("Quick", "5-15s", .green)
                            durationGuide("Medium", "15-60s", .yellow)
                            durationGuide("Long", "60s+", .orange)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var validationSection: some View {
        Group {
            if !validationErrors.isEmpty {
                stepEditorCard {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(.red)

                            Text("Validation Issues")
                                .font(.headline)
                                .foregroundColor(.white)

                            Spacer()
                        }

                        ForEach(validationErrors, id: \.self) { error in
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)

                                Text(error)
                                    .font(.subheadline)
                                    .foregroundColor(.white)

                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Helper Views

    private func parameterRow(key: String, value: String) -> some View {
        HStack {
            Text(key)
                .font(.caption)
                .foregroundColor(.cyan)
                .frame(minWidth: 60, alignment: .leading)

            Text(":")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text(value)
                .font(.caption)
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            Button(action: { parameters.removeValue(forKey: key) }) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(6)
    }

    private func durationGuide(_ title: String, _ range: String, _ color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundColor(color)

            Text(range)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private func stepEditorCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.1),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
            )
    }

    // MARK: - Methods

    private func setupForEditing() {
        if let step = step {
            stepTitle = step.title
            stepDescription = step.description
            expectedInput = step.expectedVoiceInput
            selectedIntent = step.intent
            isOptional = step.isOptional
            estimatedDuration = step.estimatedDuration

            // Convert Any parameters to String for editing
            parameters = step.parameters.compactMapValues { value in
                if let stringValue = value as? String {
                    return stringValue
                } else {
                    return String(describing: value)
                }
            }
        }
        validateStep()
    }

    private func validateStep() {
        validationErrors.removeAll()

        if stepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Step title is required")
        }

        if stepDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Step description is required")
        }

        if expectedInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Expected voice input is required")
        }

        if expectedInput.count > 200 {
            validationErrors.append("Voice input should be under 200 characters")
        }

        if estimatedDuration < 5 {
            validationErrors.append("Duration should be at least 5 seconds")
        }
    }

    private func saveStep() {
        guard validationErrors.isEmpty else { return }

        let savedStep = VoiceWorkflowStep(
            title: stepTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: stepDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            expectedVoiceInput: expectedInput.trimmingCharacters(in: .whitespacesAndNewlines),
            intent: selectedIntent,
            parameters: parameters,
            isOptional: isOptional,
            estimatedDuration: estimatedDuration,
            dependencies: step?.dependencies ?? []
        )

        onSave(savedStep)
        dismiss()
    }

    private func generateVoiceVariations() -> [String] {
        // Simple variations based on the expected input
        let input = expectedInput.lowercased()
        var variations: [String] = []

        if input.contains("create") {
            variations.append(expectedInput.replacingOccurrences(of: "create", with: "generate", options: .caseInsensitive))
            variations.append(expectedInput.replacingOccurrences(of: "create", with: "make", options: .caseInsensitive))
        }

        if input.contains("send") {
            variations.append(expectedInput.replacingOccurrences(of: "send", with: "email", options: .caseInsensitive))
            variations.append(expectedInput.replacingOccurrences(of: "send", with: "compose", options: .caseInsensitive))
        }

        if input.contains("schedule") {
            variations.append(expectedInput.replacingOccurrences(of: "schedule", with: "book", options: .caseInsensitive))
            variations.append(expectedInput.replacingOccurrences(of: "schedule", with: "plan", options: .caseInsensitive))
        }

        return Array(Set(variations)).filter { !$0.isEmpty && $0 != expectedInput }
    }

    private func iconForIntent(_ intent: CommandIntent) -> String {
        switch intent {
        case .generateDocument: return "doc.text.fill"
        case .sendEmail: return "envelope.fill"
        case .scheduleCalendar: return "calendar.badge.plus"
        case .performSearch: return "magnifyingglass"
        case .uploadStorage: return "icloud.and.arrow.up.fill"
        case .downloadStorage: return "icloud.and.arrow.down.fill"
        case .createNote: return "note.text"
        case .setReminder: return "bell.fill"
        case .weatherQuery: return "cloud.sun.fill"
        case .newsQuery: return "newspaper.fill"
        case .calculation: return "function"
        case .translation: return "translate"
        case .general: return "bubble.left.fill"
        case .unknown: return "questionmark.circle.fill"
        }
    }
}

// MARK: - Parameter Editor View

struct ParameterEditorView: View {
    @Binding var key: String
    @Binding var value: String
    @Binding var parameters: [String: String]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Parameter Key")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    TextField("Enter parameter key", text: $key)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .colorScheme(.dark)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Parameter Value")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))

                    TextField("Enter parameter value", text: $value)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .colorScheme(.dark)
                }

                Spacer()
            }
            .padding()
            .background(Color.black)
            .navigationTitle("Add Parameter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        parameters[key] = value
                        key = ""
                        value = ""
                        dismiss()
                    }
                    .foregroundColor(.green)
                    .disabled(key.isEmpty || value.isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview

struct StepEditorView_Previews: PreviewProvider {
    static var previews: some View {
        StepEditorView(
            step: .constant(nil),
            isNewStep: true
        ) { _ in }
        .preferredColorScheme(.dark)
    }
}
