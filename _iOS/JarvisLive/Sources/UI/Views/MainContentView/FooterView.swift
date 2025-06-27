// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Footer component displaying development build information
 * Issues & Complexity Summary: Simple footer component for build version display
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~20
 *   - Core Algorithm Complexity: Low (static content display)
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: None (static content)
 *   - Novelty/Uncertainty Factor: Low (extracted existing code)
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 95%
 * Problem Estimate (Inherent Problem Difficulty %): 40%
 * Initial Code Complexity Estimate %: 50%
 * Justification for Estimates: Simple static footer component
 * Final Code Complexity (Actual %): 55%
 * Overall Result Score (Success & Quality %): 97%
 * Key Variances/Learnings: Static components are the easiest to extract
 * Last Updated: 2025-06-27
 */

import SwiftUI

struct FooterView: View {
    var body: some View {
        VStack(spacing: 5) {
            Text("Development Build")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))

            Text("Version 1.0.0-sandbox")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.5))
        }
        .modifier(GlassViewModifier())
        .padding(.bottom, 20)
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
            .preferredColorScheme(.dark)
    }
}
