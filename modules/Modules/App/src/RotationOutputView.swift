import CRDesign
import CRModel
import SwiftUI

public struct RotationOutputView: View {
    @State private var viewModel: RotationOutputViewModel
    @Environment(\.dismiss) private var dismiss
    private let showDoneButton: Bool

    private let labelWidth: CGFloat = 68
    private let colWidth: CGFloat = 96
    private let cellHeight: CGFloat = 54
    private let headerHeight: CGFloat = 36

    static let orderedPositions: [Position] = [.goalie, .attack, .midfield, .defense]

    public init(game: Game, players: [Player], store: SeasonStore, showDoneButton: Bool) {
        _viewModel = State(initialValue: RotationOutputViewModel(
            game: game,
            players: players,
            store: store
        ))
        self.showDoneButton = showDoneButton
    }

    public var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            mainContent
        }
        .navigationTitle("vs. \(viewModel.game.opponent)")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.crSurface, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar { toolbarContent }
        .sheet(isPresented: $viewModel.showBenchSwapSheet) {
            BenchSwapSheet(
                candidates: viewModel.benchSwapCandidates,
                onSelect: { viewModel.confirmBenchSwap(benchPlayerID: $0) },
                onCancel: {
                    viewModel.showBenchSwapSheet = false
                }
            )
            .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Cell Options",
            isPresented: Binding(
                get: { viewModel.cellOptionsTarget != nil },
                set: { if !$0 { viewModel.clearCellOptions() } }
            ),
            titleVisibility: .hidden
        ) {
            if let cell = viewModel.cellOptionsTarget {
                Button(viewModel.isCellLocked(cell) ? "Unlock Cell" : "Lock Cell") {
                    viewModel.toggleLock(cell: cell)
                    viewModel.clearCellOptions()
                }
                Button("Swap from Bench") {
                    viewModel.clearCellOptions()
                    viewModel.initiateBenchSwap(slotIndex: cell.slotIndex, position: cell.position)
                }
                Button("Remove Player", role: .destructive) {
                    viewModel.removePlayer(at: cell)
                    viewModel.clearCellOptions()
                }
                Button("Cancel", role: .cancel) {}
            }
        }
        .alert("Regenerate Plan?", isPresented: $viewModel.showRegenerateWarning) {
            Button("Regenerate", role: .destructive) { viewModel.confirmRegenerate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Unlocked manual changes will be lost. Locked cells are preserved.")
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let plan = viewModel.plan {
            VStack(spacing: 0) {
                if !viewModel.activeViolations.isEmpty {
                    violationBannerStack
                }
                rotationGrid(plan)
                Divider().background(Color.crTextSecondary.opacity(0.2))
                PlayingTimeBarsView(viewModel: viewModel)
                SummaryStripView(viewModel: viewModel)
            }
            .overlay(alignment: .bottom) {
                if viewModel.canUndo {
                    undoButton
                        .padding(.bottom, 80)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .animation(.easeInOut(duration: 0.2), value: viewModel.canUndo)
                }
            }
        } else {
            emptyState
        }
    }

    private var violationBannerStack: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 4) {
                ForEach(Array(viewModel.activeViolations.enumerated()), id: \.offset) { index, violation in
                    ViolationBannerView(
                        violation: violation,
                        players: viewModel.players
                    ) {
                        if let actualIndex = viewModel.game.rotationPlan?.violations.firstIndex(of: violation) {
                            viewModel.dismissViolation(at: actualIndex)
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .frame(maxHeight: 110)
    }

    private func rotationGrid(_ plan: RotationPlan) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            HStack(alignment: .top, spacing: 0) {
                // Frozen position labels column
                VStack(spacing: 0) {
                    Color.clear.frame(height: headerHeight)
                    ForEach(Self.orderedPositions, id: \.self) { position in
                        Text(position.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.crTextSecondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                            .frame(height: cellHeight)
                    }
                    Text("Bench")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.crTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                        .padding(.top, 10)
                }
                .frame(width: labelWidth)
                .background(Color.crBackground)
                .overlay(alignment: .trailing) {
                    Rectangle()
                        .fill(Color.crTextSecondary.opacity(0.2))
                        .frame(width: 1)
                }

                // Scrollable slot columns
                ScrollView(.horizontal, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header row
                        HStack(spacing: 0) {
                            ForEach(Array(plan.slots.enumerated()), id: \.offset) { index, slot in
                                slotHeaderCell(slot: slot, index: index)
                                    .frame(width: colWidth, height: headerHeight)
                            }
                        }

                        // Position rows
                        ForEach(Self.orderedPositions, id: \.self) { position in
                            HStack(spacing: 0) {
                                ForEach(Array(plan.slots.enumerated()), id: \.offset) { index, slot in
                                    let cell = RotationOutputViewModel.CellID(slotIndex: index, position: position)
                                    RotationCellView(
                                        playerName: slot.assignments.first { $0.position == position }
                                            .map { viewModel.playerName(for: $0.playerID) },
                                        isSelected: viewModel.selectedCell == cell,
                                        isLocked: slot.assignments.first { $0.position == position }?.isLocked ?? false,
                                        onTap: { viewModel.tapCell(slotIndex: index, position: position) },
                                        onLongPress: { viewModel.showCellOptions(slotIndex: index, position: position) }
                                    )
                                    .frame(width: colWidth, height: cellHeight)
                                }
                            }
                        }

                        // Bench row
                        HStack(alignment: .top, spacing: 0) {
                            ForEach(Array(plan.slots.enumerated()), id: \.offset) { index, slot in
                                benchCell(slot: slot, slotIndex: index)
                                    .frame(width: colWidth)
                            }
                        }
                    }
                }
            }
            .padding(.bottom, 8)
        }
    }

    private func slotHeaderCell(slot: RotationSlot, index: Int) -> some View {
        Text(viewModel.slotHeader(for: slot))
            .font(.caption.weight(.bold))
            .foregroundStyle(Color.crTextPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(index % 2 == 0 ? Color.crSurface : Color.crBackground)
            .overlay(alignment: .trailing) {
                Rectangle()
                    .fill(Color.crTextSecondary.opacity(0.2))
                    .frame(width: 1)
            }
    }

    private func benchCell(slot: RotationSlot, slotIndex: Int) -> some View {
        let isExpanded = viewModel.expandedBenchSlots.contains(slotIndex)
        let count = slot.bench.count

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                viewModel.toggleBenchExpansion(slotIndex: slotIndex)
            } label: {
                HStack(spacing: 4) {
                    Text(count == 0 ? "—" : "\(count)")
                        .font(.caption2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(count == 0 ? Color.crTextSecondary.opacity(0.4) : Color.crTextSecondary)
                    if count > 0 {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 8))
                            .foregroundStyle(Color.crTextSecondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(slot.bench, id: \.self) { playerID in
                        Text(viewModel.playerName(for: playerID))
                            .font(.caption2)
                            .foregroundStyle(Color.crAccent)
                            .lineLimit(1)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 1)
                    }
                }
                .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(slotIndex % 2 == 0 ? Color.crSurface.opacity(0.5) : Color.clear)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.15))
                .frame(width: 1)
        }
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.15))
                .frame(height: 1)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(Color.crTextSecondary)
            Text("No rotation plan yet")
                .font(.headline)
                .foregroundStyle(Color.crTextPrimary)
            Button {
                viewModel.requestRegenerate()
            } label: {
                Text("Generate Plan")
                    .font(.headline)
                    .foregroundStyle(Color.crBackground)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
                    .background(Color.crAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
            }
        }
        .multilineTextAlignment(.center)
        .padding()
    }

    private var undoButton: some View {
        Button {
            withAnimation { viewModel.undo() }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward")
                Text("Undo")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.crBackground)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color.crTextPrimary)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        if showDoneButton {
            ToolbarItem(placement: .primaryAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.crAccent)
            }
        }
        ToolbarItem(placement: showDoneButton ? .secondaryAction : .primaryAction) {
            Button {
                viewModel.requestRegenerate()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .foregroundStyle(Color.crAccent)
        }
    }
}

#Preview {
    let store = SeasonStore(fileManagerClient: .mock(), userDefaultsClient: .noop)
    RotationOutputView(
        game: Game(
            id: UUID(),
            opponent: "Hawks",
            date: Date(),
            isHome: true,
            status: .ready,
            attendance: [],
            format: .default,
            rotationStyle: .byQuarter,
            fairnessTargets: .default,
            competitivenessMode: .balanced,
            boostedPlayerIDs: [],
            createdAt: Date()
        ),
        players: [],
        store: store,
        showDoneButton: false
    )
}
