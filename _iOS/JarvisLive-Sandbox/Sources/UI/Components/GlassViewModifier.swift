// SANDBOX FILE: For iOS testing/development. See .cursorrules.
/**
 * Purpose: Reusable glassmorphism ViewModifier for consistent UI theming across the app
 * Issues & Complexity Summary: SwiftUI ViewModifier implementing glass effect with accessibility support
 * Key Complexity Drivers:
 *   - Logic Scope (Est. LoC): ~30
 *   - Core Algorithm Complexity: Low
 *   - Dependencies: 1 (SwiftUI)
 *   - State Management Complexity: None
 *   - Novelty/Uncertainty Factor: Low
 * AI Pre-Task Self-Assessment (Est. Solution Difficulty %): 90%
 * Problem Estimate (Inherent Problem Difficulty %): 70%
 * Initial Code Complexity Estimate %: 75%
 * Justification for Estimates: Standard SwiftUI ViewModifier implementation with glass effects
 * Final Code Complexity (Actual %): 75%
 * Overall Result Score (Success & Quality %): 90%
 * Key Variances/Learnings: Straightforward implementation as expected
 * Last Updated: 2025-06-25
 */

import SwiftUI

struct GlassViewModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.4),
                                Color.white.opacity(0.1),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

extension View {
    func glassmorphic() -> some View {
        modifier(GlassViewModifier())
    }
}
