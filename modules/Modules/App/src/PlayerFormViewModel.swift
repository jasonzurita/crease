import CRModel
import Foundation
import Observation

@Observable
@MainActor
public final class PlayerFormViewModel {
    public enum Mode {
        case add
        case edit(Player)
    }

    public var name: String = ""
    public var jerseyNumber: String = ""
    public var positions: Set<Position> = []
    public var tier: Tier = .developing

    public var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && Int(jerseyNumber) != nil
            && !positions.isEmpty
    }

    private let mode: Mode

    public init(mode: Mode) {
        self.mode = mode
        if case let .edit(player) = mode {
            name = player.name
            jerseyNumber = String(player.jerseyNumber)
            positions = player.positions
            tier = player.tier
        }
    }

    public func save(in store: SeasonStore) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard let number = Int(jerseyNumber) else { return }

        switch mode {
        case .add:
            let player = Player(
                id: UUID(),
                name: trimmedName,
                jerseyNumber: number,
                positions: positions,
                tier: tier
            )
            try store.createPlayer(player)
        case let .edit(existing):
            let updated = Player(
                id: existing.id,
                name: trimmedName,
                jerseyNumber: number,
                positions: positions,
                tier: tier
            )
            try store.updatePlayer(updated)
        }
    }
}
