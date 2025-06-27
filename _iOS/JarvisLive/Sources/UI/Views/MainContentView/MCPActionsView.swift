// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: MCP actions interface with buttons, progress indicators, and result display
 * Issues & Complexity Summary: Complex extracted component handling MCP action UI and state
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~140
 *   - Core Algorithm Complexity: Medium (action handling, progress tracking, results)
 *   - Dependencies: 3 (SwiftUI, LiveKitManager via closures, MCP state)
 *   - State Management Complexity: High (action progress, results, button states)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 80%
 * Problem Estimate (Inherent Problem Difficulty %): 80%
 * Initial Code Complexity Estimate %: 85%
 * Justification for Estimates: Complex component with multiple action types and state management
 * Final Code Complexity (Actual %): 87%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: Action handlers need to be passed via closures to maintain separation
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct MCPActionsView: View {
    let mcpActionInProgress: Bool
    let mcpActionResult: String
    let onDocumentGeneration: () -> Void
    let onSendEmail: () -> Void
    let onSearch: () -> Void
    let onCreateEvent: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "gearshape.2.fill")
                    .foregroundColor(.mint)
                Text("MCP Actions")
                    .font(.headline)
                    .foregroundColor(.white)
            }

            // Action buttons grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                // Document Generation Button
                Button(action: onDocumentGeneration) {
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Generate\nDocument")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(12)
                }
                .accessibilityIdentifier("GenerateDocumentButton")

                // Quick Email Button
                Button(action: onSendEmail) {
                    VStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Send\nEmail")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(mcpActionInProgress)
                .accessibilityIdentifier("SendEmailButton")

                // Search Button
                Button(action: onSearch) {
                    VStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Search")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.orange.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(mcpActionInProgress)
                .accessibilityIdentifier("SearchButton")

                // Calendar Event Button
                Button(action: onCreateEvent) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                            .foregroundColor(.purple)
                        Text("Create\nEvent")
                            .font(.caption)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .frame(height: 60)
                    .frame(maxWidth: .infinity)
                    .background(Color.purple.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(mcpActionInProgress)
                .accessibilityIdentifier("CreateEventButton")
            }

            // Action progress indicator
            if mcpActionInProgress {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                    Text("Processing MCP action...")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
            }

            // Action result display
            if !mcpActionResult.isEmpty {
                ScrollView {
                    Text(mcpActionResult)
                        .font(.caption)
                        .foregroundColor(.mint)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                }
                .frame(maxHeight: 60)
                .accessibilityIdentifier("MCPActionResult")
            }
        }
        .modifier(GlassViewModifier())
    }
}

struct MCPActionsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            MCPActionsView(
                mcpActionInProgress: false,
                mcpActionResult: "",
                onDocumentGeneration: {},
                onSendEmail: {},
                onSearch: {},
                onCreateEvent: {}
            )

            MCPActionsView(
                mcpActionInProgress: true,
                mcpActionResult: "",
                onDocumentGeneration: {},
                onSendEmail: {},
                onSearch: {},
                onCreateEvent: {}
            )

            MCPActionsView(
                mcpActionInProgress: false,
                mcpActionResult: "Email sent successfully to test@example.com",
                onDocumentGeneration: {},
                onSendEmail: {},
                onSearch: {},
                onCreateEvent: {}
            )
        }
        .preferredColorScheme(.dark)
    }
}
