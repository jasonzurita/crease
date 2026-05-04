import FileManagerClient
import Foundation

public extension CodablePersistenceClient {
    static func mock(
        save: @escaping (A, String) throws -> Void = { _, _ in },
        getAll: @escaping () throws -> [A] = { [] },
        delete: @escaping (String) throws -> Void = { _ in }
    ) -> Self {
        .init(save: save, getAll: getAll, delete: delete)
    }

    static func happyPath() -> Self { .mock() }
}
