// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Document generation view for testing MCP document generation services
 * Issues & Complexity Summary: UI form for document generation with format selection and MCP integration
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~250
 *   - Core Algorithm Complexity: Medium (Form validation, async operations)
 *   - Dependencies: 3 New (SwiftUI, LiveKitManager, DocumentSharing)
 *   - State Management Complexity: Medium (Form state, generation progress, error handling)
 *   - Novelty/Uncertainty Factor: Low (Standard SwiftUI form with async operations)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 75%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 75%
 * Justification for Estimates: Standard form UI with async MCP integration and file handling
 * Final Code Complexity (Actual %): 78%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: File sharing integration requires platform-specific handling
 * Last Updated: 2025-06-26
 */

import SwiftUI

struct DocumentGenerationView: View {
    @ObservedObject var liveKitManager: LiveKitManager
    @Environment(\.dismiss) private var dismiss

    // Form state
    @State private var documentContent: String = ""
    @State private var selectedFormat: DocumentFormat = .pdf
    @State private var documentTitle: String = ""
    @State private var documentAuthor: String = ""
    @State private var documentKeywords: String = ""

    // Generation state
    @State private var isGenerating: Bool = false
    @State private var generationResult: String = ""
    @State private var generationError: String = ""
    @State private var showingShareSheet: Bool = false
    @State private var generatedDocumentURL: URL?

    // Sample content templates
    private let sampleContents = [
        ("Meeting Notes", "# Meeting Notes\n\n**Date:** \(DateFormatter.mediumDate.string(from: Date()))\n**Attendees:** \n\n## Agenda\n1. Project updates\n2. Action items\n3. Next steps\n\n## Discussion\n\n## Action Items\n- [ ] Task 1\n- [ ] Task 2\n\n## Next Meeting\n**Date:** TBD"),
        ("Project Report", "# Project Status Report\n\n**Project:** \n**Date:** \(DateFormatter.mediumDate.string(from: Date()))\n**Status:** In Progress\n\n## Executive Summary\n\n## Progress Update\n\n## Challenges\n\n## Next Steps\n\n## Timeline\n"),
        ("Technical Specification", "# Technical Specification\n\n**Version:** 1.0\n**Date:** \(DateFormatter.mediumDate.string(from: Date()))\n\n## Overview\n\n## Requirements\n### Functional Requirements\n### Non-Functional Requirements\n\n## Architecture\n\n## Implementation Details\n\n## Testing Strategy\n"),
    ]

    enum DocumentFormat: String, CaseIterable {
        case pdf = "pdf"
        case docx = "docx"
        case html = "html"
        case markdown = "markdown"
        case txt = "txt"

        var displayName: String {
            switch self {
            case .pdf: return "PDF Document"
            case .docx: return "Word Document"
            case .html: return "HTML Page"
            case .markdown: return "Markdown File"
            case .txt: return "Text File"
            }
        }

        var icon: String {
            switch self {
            case .pdf: return "doc.richtext.fill"
            case .docx: return "doc.text.fill"
            case .html: return "globe"
            case .markdown: return "text.book.closed.fill"
            case .txt: return "doc.plaintext.fill"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Background matching main app
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.1, green: 0.2, blue: 0.4),
                        Color(red: 0.2, green: 0.1, blue: 0.3),
                        Color(red: 0.1, green: 0.1, blue: 0.2),
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        documentCard {
                            VStack(spacing: 10) {
                                HStack {
                                    Image(systemName: "doc.text.fill")
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                    Text("Document Generator")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                }

                                Text("Generate documents using MCP services")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .padding()
                        }

                        // Document metadata
                        documentCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(.cyan)
                                    Text("Document Information")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Title")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Enter document title", text: $documentTitle)
                                        .textFieldStyle(DocumentTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Author")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("Enter author name", text: $documentAuthor)
                                        .textFieldStyle(DocumentTextFieldStyle())
                                }

                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Keywords (comma-separated)")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.8))

                                    TextField("keyword1, keyword2, keyword3", text: $documentKeywords)
                                        .textFieldStyle(DocumentTextFieldStyle())
                                }
                            }
                            .padding()
                        }

                        // Format selection
                        documentCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "doc.badge.gearshape.fill")
                                        .foregroundColor(.orange)
                                    Text("Document Format")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                                    ForEach(DocumentFormat.allCases, id: \.self) { format in
                                        Button(action: {
                                            selectedFormat = format
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: format.icon)
                                                    .font(.title2)
                                                    .foregroundColor(selectedFormat == format ? .white : .gray)

                                                Text(format.displayName)
                                                    .font(.caption)
                                                    .foregroundColor(selectedFormat == format ? .white : .gray)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(height: 60)
                                            .frame(maxWidth: .infinity)
                                            .background(
                                                selectedFormat == format
                                                    ? Color.blue.opacity(0.3)
                                                    : Color.white.opacity(0.1)
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        selectedFormat == format
                                                            ? Color.blue
                                                            : Color.white.opacity(0.3),
                                                        lineWidth: selectedFormat == format ? 2 : 1
                                                    )
                                            )
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding()
                        }

                        // Sample content templates
                        documentCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "doc.text.magnifyingglass")
                                        .foregroundColor(.green)
                                    Text("Quick Templates")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                ForEach(sampleContents.indices, id: \.self) { index in
                                    let (title, content) = sampleContents[index]

                                    Button(action: {
                                        documentContent = content
                                        if documentTitle.isEmpty {
                                            documentTitle = title
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "doc.fill")
                                                .foregroundColor(.green)
                                            Text(title)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .foregroundColor(.white.opacity(0.6))
                                                .font(.caption)
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.white.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                            }
                            .padding()
                        }

                        // Content input
                        documentCard {
                            VStack(alignment: .leading, spacing: 15) {
                                HStack {
                                    Image(systemName: "square.and.pencil")
                                        .foregroundColor(.purple)
                                    Text("Document Content")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Enter your document content (Markdown supported)")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.7))

                                    TextEditor(text: $documentContent)
                                        .frame(minHeight: 200)
                                        .padding(12)
                                        .background(Color.black.opacity(0.3))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                        )
                                        .foregroundColor(.white)
                                        .font(.system(.body, design: .monospaced))
                                }

                                if documentContent.isEmpty {
                                    Text("Document content is required")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            .padding()
                        }

                        // Generate button
                        Button(action: generateDocument) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Image(systemName: "doc.badge.plus")
                                }
                                Text(isGenerating ? "Generating..." : "Generate Document")
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                documentContent.isEmpty || isGenerating
                                    ? Color.gray.opacity(0.6)
                                    : Color.blue.opacity(0.8)
                            )
                            .cornerRadius(12)
                        }
                        .disabled(documentContent.isEmpty || isGenerating)
                        .padding(.horizontal)

                        // Result display
                        if !generationResult.isEmpty {
                            documentCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                        Text("Generation Result")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }

                                    Text(generationResult)
                                        .font(.body)
                                        .foregroundColor(.green)
                                        .padding(.vertical, 10)

                                    if generatedDocumentURL != nil {
                                        Button(action: {
                                            showingShareSheet = true
                                        }) {
                                            HStack {
                                                Image(systemName: "square.and.arrow.up")
                                                Text("Share Document")
                                            }
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(Color.green.opacity(0.8))
                                            .cornerRadius(8)
                                        }
                                    }
                                }
                                .padding()
                            }
                        }

                        // Error display
                        if !generationError.isEmpty {
                            documentCard {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text("Generation Error")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                    }

                                    Text(generationError)
                                        .font(.body)
                                        .foregroundColor(.red)
                                        .padding(.vertical, 10)
                                }
                                .padding()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Document Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = generatedDocumentURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    // MARK: - Document Card Helper

    @ViewBuilder
    private func documentCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
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
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
            )
    }

    // MARK: - Generation Logic

    private func generateDocument() {
        guard !documentContent.isEmpty, !isGenerating else { return }

        isGenerating = true
        generationResult = ""
        generationError = ""

        Task {
            do {
                let result = try await liveKitManager.generateDocumentViaMCP(
                    content: documentContent,
                    format: selectedFormat.rawValue
                )

                await MainActor.run {
                    generationResult = result
                    isGenerating = false

                    // In a real implementation, you would parse the result to get the actual file URL
                    // For now, we'll create a mock URL for demonstration
                    generatedDocumentURL = createMockDocumentURL()
                }
            } catch {
                await MainActor.run {
                    generationError = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }

    private func createMockDocumentURL() -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "\(documentTitle.isEmpty ? "Document" : documentTitle).\(selectedFormat.rawValue)"
        return tempDir.appendingPathComponent(filename)
    }
}

// MARK: - Document Text Field Style

struct DocumentTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
            )
            .foregroundColor(.white)
            .font(.system(.body, design: .default))
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Date Formatter Extension

extension DateFormatter {
    static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

// MARK: - Preview

struct DocumentGenerationView_Previews: PreviewProvider {
    static var previews: some View {
        DocumentGenerationView(liveKitManager: LiveKitManager())
            .preferredColorScheme(.dark)
    }
}
