import SwiftUI

public struct CRSurfaceCard: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(Color.crSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

public extension View {
    func crSurfaceCard() -> some View {
        modifier(CRSurfaceCard())
    }
}
