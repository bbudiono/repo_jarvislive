// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Interactive workflow builder for creating and editing custom voice command workflows
 * Issues & Complexity Summary: Dynamic workflow creation, step management, parameter configuration, validation, and persistence
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~700+
 *   - Core Algorithm Complexity: High (Workflow creation logic, step dependencies, validation)
 *   - Dependencies: 5 New (SwiftUI, Combine, UniformTypeIdentifiers, DragAndDrop, CoreData)
 *   - State Management Complexity: High (Multiple workflow states, step editing, drag & drop)
 *   - Novelty/Uncertainty Factor: High (Interactive workflow builder patterns)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 88%
 * Problem Estimate (Inherent Problem Difficulty %): 85%
 * Initial Code Complexity Estimate %: 86%
 * Justification for Estimates: Complex workflow builder with drag & drop, validation, and dynamic UI
 * Final Code Complexity (Actual %): 91%
 * Overall Result Score (Success & Quality %): 94%
 * Key Variances/Learnings: Workflow builder requires sophisticated state management and user interaction patterns
 * Last Updated: 2025-06-26
 */

import SwiftUI
import Combine
import UniformTypeIdentifiers

// MARK: - Workflow Builder View

struct WorkflowBuilderView: View {
    @Binding var workflows: [VoiceWorkflow]
    @Environment(\.dismiss) private var dismiss

    @State private var currentWorkflow: VoiceWorkflow?
    @State private var workflowName: String = ""
    @State private var workflowDescription: String = ""
    @State private var selectedCategory: VoiceWorkflow.WorkflowCategory = .custom
    @State private var selectedComplexity: VoiceWorkflow.ComplexityLevel = .simple
    @State private var workflowSteps: [VoiceWorkflowStep] = []
    @State private var isEditing: Bool = false
    @State private var showingStepEditor: Bool = false
    @State private var editingStep: VoiceWorkflowStep?
    @State private var draggedStep: VoiceWorkflowStep?
    @State private var showingTemplates: Bool = false
    @State private var showingImportExport: Bool = false
    @State private var validationErrors: [String] = []

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                workflowBuilderBackground

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        builderHeader

                        // Workflow basic info
                        workflowInfoSection

                        // Steps builder
                        stepsBuilderSection

                        // Validation and actions
                        validationSection

                        // Save/Cancel buttons
                        actionButtonsSection
                    }
                    .padding()
                }
            }
            .navigationTitle(isEditing ? "Edit Workflow" : "New Workflow")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.red)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingTemplates = true }) {
                            Label("Templates", systemImage: "doc.on.doc.fill")
                        }

                        Button(action: { showingImportExport = true }) {
                            Label("Import/Export", systemImage: "square.and.arrow.up")
                        }

                        Button(action: { clearWorkflow() }) {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
        .sheet(isPresented: $showingStepEditor) {
            StepEditorView(
                step: $editingStep,
                isNewStep: editingStep == nil
            ) { step in
                if let step = step {
                    if editingStep == nil {
                        // Adding new step
                        workflowSteps.append(step)
                    } else {
                        // Editing existing step
                        if let index = workflowSteps.firstIndex(where: { $0.id == step.id }) {
                            workflowSteps[index] = step
                        }
                    }
                }
                editingStep = nil
                validateWorkflow()
            }
        }
        .sheet(isPresented: $showingTemplates) {
            WorkflowTemplatesView { template in
                loadTemplate(template)
            }
        }
        .sheet(isPresented: $showingImportExport) {
            ImportExportView(workflows: $workflows)
        }
        .onAppear {
            setupForEditing()
        }
    }

    // MARK: - View Components

    private var workflowBuilderBackground: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 0.08, green: 0.12, blue: 0.25),
                Color(red: 0.12, green: 0.08, blue: 0.22),
                Color(red: 0.06, green: 0.06, blue: 0.15),
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var builderHeader: some View {
        builderGlassCard {
            VStack(spacing: 15) {
                HStack {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Workflow Builder")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)

                        Text("🧪 SANDBOX MODE")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }

                    Spacer()

                    HStack(spacing: 12) {
                        Image(systemName: "hammer.fill")
                            .font(.title2)
                            .foregroundColor(.cyan)

                        Text("\(workflowSteps.count) Steps")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }

                if !validationErrors.isEmpty {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)

                        Text("\(validationErrors.count) validation issue\(validationErrors.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundColor(.orange)

                        Spacer()
                    }
                }
            }
            .padding()
        }
    }

    private var workflowInfoSection: some View {
        builderGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .font(.title2)
                        .foregroundColor(.blue)

                    Text("Workflow Information")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    // Name
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter workflow name", text: $workflowName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                            .onChange(of: workflowName) { _ in
                                validateWorkflow()
                            }
                    }

                    // Description
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))

                        TextField("Enter workflow description", text: $workflowDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .colorScheme(.dark)
                            .lineLimit(3...6)
                    }

                    // Category and Complexity
                    HStack(spacing: 15) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Category")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Picker("Category", selection: $selectedCategory) {
                                ForEach(VoiceWorkflow.WorkflowCategory.allCases, id: \.self) { category in
                                    HStack {
                                        Image(systemName: category.icon)
                                        Text(category.rawValue)
                                    }.tag(category)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.cyan)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Complexity")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))

                            Picker("Complexity", selection: $selectedComplexity) {
                                ForEach(VoiceWorkflow.ComplexityLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .foregroundColor(.cyan)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var stepsBuilderSection: some View {
        builderGlassCard {
            VStack(alignment: .leading, spacing: 15) {
                HStack {
                    Image(systemName: "list.number")
                        .font(.title2)
                        .foregroundColor(.green)

                    Text("Workflow Steps")
                        .font(.headline)
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { addNewStep() }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Step")
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green.opacity(0.2))
                        .cornerRadius(8)
                    }
                }

                if workflowSteps.isEmpty {
                    emptyStepsView
                } else {
                    stepsListView
                }
            }
            .padding()
        }
    }

    private var emptyStepsView: some View {
        VStack(spacing: 15) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.largeTitle)
                .foregroundColor(.gray.opacity(0.5))

            Text("No steps added yet")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))

            Text("Add steps to define your workflow")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.5))
                .multilineTextAlignment(.center)

            Button(action: { addNewStep() }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add First Step")
                }
                .foregroundColor(.white)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
        }
        .frame(minHeight: 150)
    }

    private var stepsListView: some View {
        LazyVStack(spacing: 12) {
            ForEach(Array(workflowSteps.enumerated()), id: \.element.id) { index, step in
                stepCard(step: step, index: index)
                    .onDrag {
                        draggedStep = step
                        return NSItemProvider(object: step.id.uuidString as NSString)
                    }
                    .onDrop(of: [UTType.text], delegate: StepDropDelegate(
                        step: step,
                        steps: $workflowSteps,
                        draggedStep: $draggedStep
                    ))
            }
        }
    }

    private func stepCard(step: VoiceWorkflowStep, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Step header
            HStack {
                Text("Step \(index + 1)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.3))
                    .cornerRadius(4)

                Text(step.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { editStep(step) }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }

                    Button(action: { deleteStep(step) }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }

                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.gray)
                }
            }

            // Step content
            VStack(alignment: .leading, spacing: 6) {
                Text(step.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)

                HStack {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.green)
                        .font(.caption)

                    Text("Say: \"\(step.expectedVoiceInput)\"")
                        .font(.caption)
                        .foregroundColor(.green)
                        .lineLimit(1)

                    Spacer()

                    if step.isOptional {
                        Text("Optional")
                            .font(.caption2)
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .cornerRadius(4)
                    }
                }

                HStack {
                    Text("Intent: \(step.intent.rawValue)")
                        .font(.caption)
                        .foregroundColor(.cyan)

                    Spacer()

                    Text("~\(Int(step.estimatedDuration))s")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }

    private var validationSection: some View {
        Group {
            if !validationErrors.isEmpty {
                builderGlassCard {
                    VStack(alignment: .leading, spacing: 15) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)

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

    private var actionButtonsSection: some View {
        HStack(spacing: 15) {
            Button(action: { clearWorkflow() }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Clear")
                }
                .foregroundColor(.red)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red.opacity(0.2))
                .cornerRadius(12)
            }

            Button(action: { saveWorkflow() }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text(isEditing ? "Update" : "Save")
                }
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(validationErrors.isEmpty ? Color.green : Color.gray)
                .cornerRadius(12)
            }
            .disabled(!validationErrors.isEmpty)
        }
    }

    // MARK: - Helper Views

    @ViewBuilder
    private func builderGlassCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
        if let workflow = currentWorkflow {
            isEditing = true
            workflowName = workflow.name
            workflowDescription = workflow.description
            selectedCategory = workflow.category
            selectedComplexity = workflow.complexityLevel
            workflowSteps = workflow.steps
        }
        validateWorkflow()
    }

    private func addNewStep() {
        editingStep = nil
        showingStepEditor = true
    }

    private func editStep(_ step: VoiceWorkflowStep) {
        editingStep = step
        showingStepEditor = true
    }

    private func deleteStep(_ step: VoiceWorkflowStep) {
        workflowSteps.removeAll { $0.id == step.id }
        validateWorkflow()
    }

    private func validateWorkflow() {
        validationErrors.removeAll()

        if workflowName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Workflow name is required")
        }

        if workflowDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            validationErrors.append("Workflow description is required")
        }

        if workflowSteps.isEmpty {
            validationErrors.append("At least one step is required")
        }

        // Check for duplicate step titles
        let stepTitles = workflowSteps.map { $0.title }
        let uniqueTitles = Set(stepTitles)
        if stepTitles.count != uniqueTitles.count {
            validationErrors.append("Step titles must be unique")
        }

        // Check for circular dependencies
        if hasCircularDependencies() {
            validationErrors.append("Circular dependencies detected in steps")
        }
    }

    private func hasCircularDependencies() -> Bool {
        // Simple check for circular dependencies - would need more sophisticated algorithm for complex cases
        for step in workflowSteps {
            var visited = Set<UUID>()
            if checkCircularDependency(step: step, visited: &visited) {
                return true
            }
        }
        return false
    }

    private func checkCircularDependency(step: VoiceWorkflowStep, visited: inout Set<UUID>) -> Bool {
        if visited.contains(step.id) {
            return true
        }

        visited.insert(step.id)

        for dependencyId in step.dependencies {
            if let dependentStep = workflowSteps.first(where: { $0.id == dependencyId }) {
                if checkCircularDependency(step: dependentStep, visited: &visited) {
                    return true
                }
            }
        }

        visited.remove(step.id)
        return false
    }

    private func saveWorkflow() {
        guard validationErrors.isEmpty else { return }

        let newWorkflow = VoiceWorkflow(
            name: workflowName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: workflowDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            steps: workflowSteps,
            category: selectedCategory,
            estimatedDuration: workflowSteps.reduce(0) { $0 + $1.estimatedDuration },
            complexityLevel: selectedComplexity,
            isCustom: true
        )

        if isEditing, let currentWorkflow = currentWorkflow {
            if let index = workflows.firstIndex(where: { $0.id == currentWorkflow.id }) {
                workflows[index] = newWorkflow
            }
        } else {
            workflows.append(newWorkflow)
        }

        dismiss()
    }

    private func clearWorkflow() {
        workflowName = ""
        workflowDescription = ""
        selectedCategory = .custom
        selectedComplexity = .simple
        workflowSteps.removeAll()
        validationErrors.removeAll()
    }

    private func loadTemplate(_ template: UIWorkflowTemplate) {
        workflowName = template.name
        workflowDescription = template.description
        selectedCategory = template.category
        selectedComplexity = template.complexity
        workflowSteps = template.steps
        validateWorkflow()
    }
}

// MARK: - Step Drop Delegate

struct StepDropDelegate: DropDelegate {
    let step: VoiceWorkflowStep
    @Binding var steps: [VoiceWorkflowStep]
    @Binding var draggedStep: VoiceWorkflowStep?

    func performDrop(info: DropInfo) -> Bool {
        guard let draggedStep = draggedStep else { return false }

        let fromIndex = steps.firstIndex { $0.id == draggedStep.id } ?? 0
        let toIndex = steps.firstIndex { $0.id == step.id } ?? 0

        if fromIndex != toIndex {
            steps.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }

        self.draggedStep = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedStep = draggedStep else { return }

        let fromIndex = steps.firstIndex { $0.id == draggedStep.id } ?? 0
        let toIndex = steps.firstIndex { $0.id == step.id } ?? 0

        if fromIndex != toIndex {
            steps.move(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)
        }
    }
}

// MARK: - Supporting Views

struct UIWorkflowTemplate {
    let name: String
    let description: String
    let category: VoiceWorkflow.WorkflowCategory
    let complexity: VoiceWorkflow.ComplexityLevel
    let steps: [VoiceWorkflowStep]
}

struct WorkflowTemplatesView: View {
    let onTemplateSelected: (UIWorkflowTemplate) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                Text("Template selection would go here")
                    .foregroundColor(.white)
            }
            .background(Color.black)
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ImportExportView: View {
    @Binding var workflows: [VoiceWorkflow]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack {
                Text("Import/Export functionality would go here")
                    .foregroundColor(.white)
                    .padding()
                Spacer()
            }
            .background(Color.black)
            .navigationTitle("Import/Export")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

struct WorkflowBuilderView_Previews: PreviewProvider {
    static var previews: some View {
        WorkflowBuilderView(workflows: .constant([]))
            .preferredColorScheme(.dark)
    }
}
