import CRDesign
import CRModel
import SwiftUI

public struct RotationOutputView: View {
    private enum GamePlanTab { case rotation, breakdown }

    @State private var viewModel: RotationOutputViewModel
    @State private var activeTab: GamePlanTab = .rotation
    @Environment(\.dismiss) private var dismiss
    private let showDoneButton: Bool
    private let onDone: (() -> Void)?

    private let labelWidth: CGFloat = 68
    private let colWidth: CGFloat = 96
    private let cellHeight: CGFloat = 52
    private let headerHeight: CGFloat = 36

    static let orderedPositions: [Position] = [.goalie, .attack, .midfield, .defense]

    public init(game: Game, players: [Player], store: SeasonStore, showDoneButton: Bool, onDone: (() -> Void)? = nil) {
        _viewModel = State(initialValue: RotationOutputViewModel(
            game: game,
            players: players,
            store: store
        ))
        self.showDoneButton = showDoneButton
        self.onDone = onDone
    }

    public var body: some View {
        ZStack {
            Color.crBackground.ignoresSafeArea()
            mainContent
            if viewModel.isRegenerating {
                GeneratingPlanOverlay()
            }
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
                onCancel: { viewModel.showBenchSwapSheet = false }
            )
            .presentationDetents([.medium])
        }
        .alert("Regenerate Plan?", isPresented: $viewModel.showRegenerateWarning) {
            Button("Regenerate", role: .destructive) { viewModel.confirmRegenerate() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("A new rotation plan will be generated. Locked cells are preserved; all other assignments will be replaced.")
        }
        .sheet(isPresented: $viewModel.showLineupCardOptions) {
            LineupCardOptionsSheet(viewModel: viewModel)
                .presentationDetents([.large])
        }
        .sheet(isPresented: $viewModel.showCompletionSheet) {
            CompletionSheet(presentPlayers: viewModel.presentPlayers) { stats in
                viewModel.markComplete(stats: stats)
            }
        }
        .sheet(isPresented: $viewModel.showFairnessEditor) {
            FairnessEditorSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .sheet(isPresented: $viewModel.showPositionCountsEditor) {
            PositionCountsEditorSheet(viewModel: viewModel)
                .presentationDetents([.medium])
        }
        .fullScreenCover(isPresented: $viewModel.showLiveMode) {
            LiveGameView(game: viewModel.game, players: viewModel.players) { stats in
                viewModel.saveLiveStats(stats)
            }
        }
        .onChange(of: viewModel.gameWasCompleted) { _, completed in
            if completed {
                if let onDone { onDone() } else { dismiss() }
            }
        }
    }

    @ViewBuilder
    private var mainContent: some View {
        if let plan = viewModel.plan {
            VStack(spacing: 0) {
                SummaryStripView(viewModel: viewModel)
                Divider().background(Color.crTextSecondary.opacity(0.15))
                tabPicker
                Divider().background(Color.crTextSecondary.opacity(0.15))
                if activeTab == .rotation {
                    rotationTabContent(plan)
                } else {
                    PlayingTimeBreakdownView(viewModel: viewModel)
                }
            }
        } else {
            emptyState
        }
    }

    private func rotationTabContent(_ plan: RotationPlan) -> some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    if !viewModel.activeViolations.isEmpty {
                        violationBannerStack
                    }
                    if viewModel.swapSourceCell != nil {
                        swapModeBanner
                    }
                    rotationGrid(plan)
                }
            }
            if viewModel.canUndo {
                undoButton
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeInOut(duration: 0.2), value: viewModel.canUndo)
            }
        }
    }

    private var tabPicker: some View {
        Picker("View", selection: $activeTab) {
            Text("Rotation").tag(GamePlanTab.rotation)
            Text("Breakdown").tag(GamePlanTab.breakdown)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.crSurface)
    }

    private var violationBannerStack: some View {
        VStack(spacing: 4) {
            ForEach(Array(viewModel.activeViolations.enumerated()), id: \.offset) { _, violation in
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

    private var swapModeBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "arrow.left.arrow.right.circle.fill")
                .foregroundStyle(Color.crAccent)
            Text("Tap another position to swap")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.crTextPrimary)
            Spacer()
            Button("Cancel") { viewModel.cancelSwap() }
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.crAccent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.crSurface)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.crAccent.opacity(0.3))
                .frame(height: 1)
        }
    }

    private func rotationGrid(_ plan: RotationPlan) -> some View {
        HStack(alignment: .top, spacing: 0) {
            // Frozen position labels column
            VStack(spacing: 0) {
                Color.clear.frame(height: headerHeight)
                ForEach(Self.orderedPositions, id: \.self) { position in
                    let rowCount = maxPlayerCount(position, in: plan)
                    positionGroupLabelDivider(for: position)
                    Text(position.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(positionAccentColor(position))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8)
                        .frame(height: CGFloat(rowCount) * cellHeight)
                }
                positionGroupLabelDivider(for: nil)
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

                    // Position rows (multi-player)
                    ForEach(Self.orderedPositions, id: \.self) { position in
                        let maxCount = maxPlayerCount(position, in: plan)
                        HStack(spacing: 0) {
                            ForEach(0 ..< plan.slots.count, id: \.self) { _ in
                                positionDividerCell(position: position, width: colWidth)
                            }
                        }
                        HStack(spacing: 0) {
                            ForEach(Array(plan.slots.enumerated()), id: \.offset) { index, slot in
                                let assignments = slot.assignments.filter { $0.position == position }
                                VStack(spacing: 0) {
                                    ForEach(0 ..< maxCount, id: \.self) { playerIdx in
                                        if playerIdx < assignments.count {
                                            let assignment = assignments[playerIdx]
                                            let cell = RotationOutputViewModel.CellID(slotIndex: index, position: position)
                                            RotationCellView(
                                                playerName: viewModel.playerName(for: assignment.playerID),
                                                jerseyNumber: viewModel.playerJerseyNumber(for: assignment.playerID),
                                                isSelected: viewModel.swapSourceCell == cell && viewModel.swapSourcePlayerID == assignment.playerID,
                                                isLocked: assignment.isLocked,
                                                inSwapMode: viewModel.swapSourceCell != nil,
                                                onTap: { viewModel.tapCell(slotIndex: index, position: position, playerID: assignment.playerID) }
                                            ) {
                                                Button("Swap Positions") {
                                                    viewModel.beginSwap(slotIndex: index, position: position, playerID: assignment.playerID)
                                                }
                                                if viewModel.hasBenchCandidates(slotIndex: index, position: position) {
                                                    Button("Swap from Bench") {
                                                        viewModel.initiateBenchSwap(slotIndex: index, position: position)
                                                    }
                                                }
                                                Button("Move to Bench", role: .destructive) {
                                                    viewModel.removePlayerDirect(slotIndex: index, position: position, playerID: assignment.playerID)
                                                }
                                                Button(assignment.isLocked ? "Unlock Cell" : "Lock Cell") {
                                                    viewModel.toggleLockDirect(slotIndex: index, position: position, playerID: assignment.playerID)
                                                }
                                            }
                                            .frame(width: colWidth, height: cellHeight)
                                        } else {
                                            Color.clear
                                                .frame(width: colWidth, height: cellHeight)
                                                .overlay(alignment: .trailing) {
                                                    Rectangle()
                                                        .fill(Color.crTextSecondary.opacity(0.1))
                                                        .frame(width: 1)
                                                }
                                                .overlay(alignment: .bottom) {
                                                    Rectangle()
                                                        .fill(Color.crTextSecondary.opacity(0.1))
                                                        .frame(height: 1)
                                                }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    HStack(spacing: 0) {
                        ForEach(0 ..< plan.slots.count, id: \.self) { _ in
                            positionDividerCell(position: nil, width: colWidth)
                        }
                    }
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

    private func positionGroupLabelDivider(for position: Position?) -> some View {
        ZStack(alignment: .bottom) {
            Color.crTextSecondary.opacity(0.06)
                .frame(maxWidth: .infinity)
                .frame(height: 4)
            Rectangle()
                .fill(position.map(positionAccentColor) ?? Color.crTextSecondary.opacity(0.3))
                .frame(maxWidth: .infinity)
                .frame(height: 1)
        }
    }

    private func positionDividerCell(position: Position?, width: CGFloat) -> some View {
        ZStack(alignment: .bottom) {
            Color.crTextSecondary.opacity(0.06)
                .frame(width: width, height: 4)
            Rectangle()
                .fill(position.map(positionAccentColor) ?? Color.crTextSecondary.opacity(0.3))
                .frame(width: width, height: 1)
        }
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(Color.crTextSecondary.opacity(0.15))
                .frame(width: 1)
        }
    }

    private func positionAccentColor(_ position: Position) -> Color {
        switch position {
        case .goalie: return Color.crWarning.opacity(0.6)
        case .attack: return Color.crAccent.opacity(0.6)
        case .midfield: return Color.crSuccess.opacity(0.6)
        case .defense: return Color.crTextSecondary.opacity(0.4)
        }
    }

    private func maxPlayerCount(_ position: Position, in plan: RotationPlan) -> Int {
        max(1, plan.slots.map { $0.assignments.filter { $0.position == position }.count }.max() ?? 1)
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
        ToolbarItem(placement: .topBarTrailing) {
            menuButton
        }
        if showDoneButton {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    if let onDone { onDone() } else { dismiss() }
                }
                .fontWeight(.semibold)
                .foregroundStyle(Color.crAccent)
            }
        }
    }

    private var menuButton: some View {
        Menu {
            Button {
                viewModel.requestRegenerate()
            } label: {
                Label("Regenerate Plan", systemImage: "arrow.clockwise")
            }
            if viewModel.plan != nil {
                Divider()
                Button {
                    viewModel.openPositionCountsEditor()
                } label: {
                    Label("Field Setup", systemImage: "person.3")
                }
                Button {
                    viewModel.openFairnessEditor()
                } label: {
                    Label("Playing Time Targets", systemImage: "slider.horizontal.3")
                }
                Divider()
                Button {
                    viewModel.showLiveMode = true
                } label: {
                    Label("Live Mode", systemImage: "play.circle.fill")
                }
                Divider()
                Button {
                    viewModel.showLineupCardOptions = true
                } label: {
                    Label("Share Lineup Card", systemImage: "square.and.arrow.up")
                }
                if viewModel.game.status != .complete {
                    Button {
                        viewModel.showCompletionSheet = true
                    } label: {
                        Label("Record Final Stats", systemImage: "checkmark.circle")
                    }
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
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
