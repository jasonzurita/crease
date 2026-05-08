import CRDesign
import CRModel
import SwiftUI

struct PlayerAttendanceSheet: View {
    @State private var localAttendance: PlayerAttendance
    private let quarters: Int
    private let playerName: String
    private let onUpdate: (PlayerAttendance) -> Void
    @Environment(\.dismiss) private var dismiss

    init(attendance: PlayerAttendance, quarters: Int, playerName: String, onUpdate: @escaping (PlayerAttendance) -> Void) {
        _localAttendance = State(initialValue: attendance)
        self.quarters = quarters
        self.playerName = playerName
        self.onUpdate = onUpdate
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.crBackground.ignoresSafeArea()
                List {
                    Section {
                        Toggle("Present", isOn: Binding(
                            get: { localAttendance.isPresent },
                            set: { present in
                                localAttendance.isPresent = present
                                if !present {
                                    localAttendance.lateArrivalQuarter = nil
                                    localAttendance.earlyDepartureQuarter = nil
                                }
                                onUpdate(localAttendance)
                            }
                        ))
                        .tint(Color.crAccent)
                        .foregroundStyle(Color.crTextPrimary)
                        .listRowBackground(Color.crSurface)
                    }

                    if localAttendance.isPresent {
                        Section("Conflicts") {
                            Toggle("Late Arrival", isOn: Binding(
                                get: { localAttendance.lateArrivalQuarter != nil },
                                set: { on in
                                    localAttendance.lateArrivalQuarter = on ? 2 : nil
                                    onUpdate(localAttendance)
                                }
                            ))
                            .tint(Color.crAccent)
                            .foregroundStyle(Color.crTextPrimary)
                            .listRowBackground(Color.crSurface)

                            if localAttendance.lateArrivalQuarter != nil {
                                Picker("Arrives before quarter", selection: Binding(
                                    get: { localAttendance.lateArrivalQuarter ?? 2 },
                                    set: { q in
                                        localAttendance.lateArrivalQuarter = q
                                        onUpdate(localAttendance)
                                    }
                                )) {
                                    ForEach(1 ... max(1, quarters), id: \.self) { q in
                                        Text("Q\(q)").tag(q)
                                    }
                                }
                                .tint(Color.crAccent)
                                .foregroundStyle(Color.crTextPrimary)
                                .listRowBackground(Color.crSurface)
                            }

                            Toggle("Early Departure", isOn: Binding(
                                get: { localAttendance.earlyDepartureQuarter != nil },
                                set: { on in
                                    localAttendance.earlyDepartureQuarter = on ? max(1, quarters - 1) : nil
                                    onUpdate(localAttendance)
                                }
                            ))
                            .tint(Color.crAccent)
                            .foregroundStyle(Color.crTextPrimary)
                            .listRowBackground(Color.crSurface)

                            if localAttendance.earlyDepartureQuarter != nil {
                                Picker("Leaves after quarter", selection: Binding(
                                    get: { localAttendance.earlyDepartureQuarter ?? max(1, quarters - 1) },
                                    set: { q in
                                        localAttendance.earlyDepartureQuarter = q
                                        onUpdate(localAttendance)
                                    }
                                )) {
                                    ForEach(1 ... max(1, quarters), id: \.self) { q in
                                        Text("Q\(q)").tag(q)
                                    }
                                }
                                .tint(Color.crAccent)
                                .foregroundStyle(Color.crTextPrimary)
                                .listRowBackground(Color.crSurface)
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(playerName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.crSurface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Color.crAccent)
                }
            }
        }
    }
}
