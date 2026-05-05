import CRDesign
import SwiftUI

struct GameDetailsView: View {
    @Bindable var viewModel: GameSetupViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Opponent")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                        TextField("Team name", text: $viewModel.opponent)
                            .textFieldStyle(.plain)
                            .foregroundStyle(Color.crTextPrimary)
                            .padding(12)
                            .background(Color.crSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Date")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                        DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            .colorScheme(.dark)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Location")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                        Picker("Location", selection: $viewModel.isHome) {
                            Text("Home").tag(true)
                            Text("Away").tag(false)
                        }
                        .pickerStyle(.segmented)
                    }
                }
                .padding()
                .crSurfaceCard()
                .padding()
            }
        }
    }
}

#Preview {
    GameDetailsView(
        viewModel: GameSetupViewModel(formatDefaults: .default, players: [])
    )
    .background(Color.crBackground)
}
