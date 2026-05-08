import CRDesign
import SwiftUI

struct GameDetailsView: View {
    @Bindable var viewModel: GameSetupViewModel
    @FocusState private var opponentFocused: Bool

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                VStack(spacing: 0) {
                    opponentRow
                    divider
                    dateRow
                    divider
                    locationRow
                }
                .crSurfaceCard()
            }
            .padding()
        }
    }

    private var opponentRow: some View {
        HStack {
            Text("Opponent")
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            TextField("Team name", text: $viewModel.opponent)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Color.crTextPrimary)
                .tint(Color.crAccent)
                .focused($opponentFocused)
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture { opponentFocused = true }
    }

    private var dateRow: some View {
        HStack {
            Text("Date")
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            DatePicker("", selection: $viewModel.date, displayedComponents: .date)
                .labelsHidden()
                .colorScheme(.dark)
                .tint(Color.crAccent)
        }
        .padding()
    }

    private var locationRow: some View {
        HStack {
            Text("Location")
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            Picker("", selection: $viewModel.isHome) {
                Text("Home").tag(true)
                Text("Away").tag(false)
            }
            .pickerStyle(.menu)
            .tint(Color.crAccent)
        }
        .padding()
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(height: 1)
            .padding(.horizontal)
    }
}

#Preview {
    GameDetailsView(
        viewModel: GameSetupViewModel(formatDefaults: .default, players: [])
    )
    .background(Color.crBackground)
}
