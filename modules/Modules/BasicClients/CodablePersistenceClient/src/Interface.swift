import Foundation

public struct CodablePersistenceClient<A: Codable> {
    public var save: (A, String) throws -> Void
    public var getAll: () throws -> [A]
    public var delete: (String) throws -> Void

    public init(
        save: @escaping (A, String) throws -> Void,
        getAll: @escaping () throws -> [A],
        delete: @escaping (String) throws -> Void
    ) {
        self.save = save
        self.getAll = getAll
        self.delete = delete
    }
}
