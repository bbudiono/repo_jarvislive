// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Header component with sandbox watermark and navigation buttons
 * Issues & Complexity Summary: Extracted modular component for better maintainability
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~50
 *   - Core Algorithm Complexity: Low (UI layout)
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: Low (button actions passed via closures)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 90%
 * Problem Estimate (Inherent Problem Difficulty %): 60%
 * Initial Code Complexity Estimate %: 70%
 * Justification for Estimates: Simple UI component extraction with clear separation of concerns
 * Final Code Complexity (Actual %): 75%
 * Overall Result Score (Success & Quality %): 95%
 * Key Variances/Learnings: Modular extraction improves testability and maintainability
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct HeaderView: View {
    let onConversationHistoryTap: () -> Void
    let onDocumentScannerTap: () -> Void
    let onSettingsTap: () -> Void

    var body: some View {
        HStack {
            Image(systemName: "flask.fill")
                .foregroundColor(.orange)
            Text("🧪 SANDBOX MODE")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.orange)

            Spacer()

            // Feature buttons
            HStack(spacing: 16) {
                // Conversation History Button
                Button(action: onConversationHistoryTap) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title2)
                        .foregroundColor(.purple)
                }
                .accessibilityIdentifier("ConversationHistoryButton")
                .accessibilityLabel("Open Conversation History")

                // Document Scanner Button
                Button(action: onDocumentScannerTap) {
                    Image(systemName: "doc.viewfinder.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .accessibilityIdentifier("DocumentScannerButton")
                .accessibilityLabel("Open Document Scanner")

                // Settings Button
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
                .accessibilityLabel("Settings")
            }
        }
        .modifier(GlassViewModifier())
        .padding(.top, 20)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(
            onConversationHistoryTap: {},
            onDocumentScannerTap: {},
            onSettingsTap: {}
        )
        .preferredColorScheme(.dark)
    }
}
