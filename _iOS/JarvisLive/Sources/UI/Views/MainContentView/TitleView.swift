// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Main title card component for Jarvis Live with sandbox watermark
 * Issues & Complexity Summary: Extracted modular component for app title and branding
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~30
 *   - Core Algorithm Complexity: Low (static UI layout)
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: None (static content)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 50%
 * Initial Code Complexity Estimate %: 60%
 * Justification for Estimates: Simple static UI component with no logic
 * Final Code Complexity (Actual %): 65%
 * Overall Result Score (Success & Quality %): 96%
 * Key Variances/Learnings: Static components are ideal candidates for modular extraction
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct TitleView: View {
    var body: some View {
        VStack(spacing: 15) {
            Text("Jarvis Live")
                .font(.system(size: 32, weight: .ultraLight, design: .rounded))
                .foregroundColor(.white)

            Text("AI Voice Assistant")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))

            // SANDBOX WATERMARK - P0 REQUIREMENT
            Text("SANDBOX MODE")
                .font(.caption)
                .foregroundColor(.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                )
                .accessibilityIdentifier("SandboxWatermark")
        }
        .modifier(GlassViewModifier())
    }
}

struct TitleView_Previews: PreviewProvider {
    static var previews: some View {
        TitleView()
            .preferredColorScheme(.dark)
    }
}
