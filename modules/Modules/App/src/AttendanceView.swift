import CRDesign
import CRModel
import SwiftUI

struct AttendanceView: View {
    var viewModel: GameSetupViewModel
    private let players: [Player]

    private let columns = [GridItem(.flexible()), GridItem(.flexible())]

    init(viewModel: GameSetupViewModel, players: [Player]) {
        self.viewModel = viewModel
        self.players = players
    }

    var body: some View {
        ScrollView {
            if players.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "person.2")
                        .font(.system(size: 40))
                        .foregroundStyle(Color.crTextSecondary)
                    Text("No players on roster")
                        .foregroundStyle(Color.crTextSecondary)
                }
                .padding(.top, 60)
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(players) { player in
                        if let index = viewModel.attendance.firstIndex(where: { $0.id == player.id }) {
                            AttendancePlayerCard(
                                player: player,
                                attendance: viewModel.attendance[index],
                                quarters: viewModel.format.quarters,
                                onTogglePresent: {
                                    viewModel.attendance[index].isPresent.toggle()
                                    if !viewModel.attendance[index].isPresent {
                                        viewModel.attendance[index].lateArrivalQuarter = nil
                                        viewModel.attendance[index].earlyDepartureQuarter = nil
                                    }
                                },
                                onUpdate: { updated in
                                    viewModel.attendance[index] = updated
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }
}
