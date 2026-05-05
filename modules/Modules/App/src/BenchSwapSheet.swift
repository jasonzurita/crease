import CRDesign
import CRModel
import SwiftUI

struct BenchSwapSheet: View {
    let candidates: [Player]
    let onSelect: (UUID) -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                if candidates.isEmpty {
                    Text("No eligible players on the bench")
                        .font(.subheadline)
                        .foregroundStyle(Color.crTextSecondary)
                } else {
                    List {
                        ForEach(candidates) { player in
                            Button {
                                onSelect(player.id)
                            } label: {
                                HStack(spacing: 12) {
                                    Text("#\(player.jerseyNumber)")
                                        .font(.caption.weight(.semibold).monospacedDigit())
                                        .foregroundStyle(Color.crTextSecondary)
                                        .frame(width: 36, alignment: .leading)
                                    Text(player.name)
                                        .foregroundStyle(Color.crTextPrimary)
                                    Spacer()
                                    Text(player.tier.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(Color.crTextSecondary)
                                }
                            }
                            .listRowBackground(Color.crSurface)
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Swap in from Bench")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundStyle(Color.crTextSecondary)
                }
            }
        }
    }
}
