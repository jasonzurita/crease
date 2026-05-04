import Foundation

public extension UserDefaultsClient {
    static var noop: Self {
        Self(
            stringForKey: { _ in nil },
            boolForKey: { _ in false },
            integerForKey: { _ in 0 },
            dataForKey: { _ in nil },
            arrayForKey: { _ in nil },
            valueForKey: { _ in nil },
            objectForKey: { _ in nil },
            storeString: { _, _ in },
            storeBool: { _, _ in },
            storeData: { _, _ in },
            storeEncodable: { _, _ in },
            registerDefaults: { _ in },
            removeObjectForKey: { _ in }
        )
    }

    static var memoryStorage: Self {
        let storage = MemoryStorage()
        return Self(
            stringForKey: { key in storage.get(key) as? String },
            boolForKey: { key in storage.get(key) as? Bool ?? false },
            integerForKey: { key in storage.get(key) as? Int ?? 0 },
            dataForKey: { key in storage.get(key) as? Data },
            arrayForKey: { key in storage.get(key) as? [Any] },
            valueForKey: { key in storage.get(key) },
            objectForKey: { key in storage.get(key) },
            storeString: { value, key in storage.set(key, value) },
            storeBool: { value, key in storage.set(key, value) },
            storeData: { value, key in storage.set(key, value) },
            storeEncodable: { value, key in storage.set(key, value) },
            registerDefaults: { defaults in
                for (key, value) in defaults where storage.get(key) == nil {
                    storage.set(key, value)
                }
            },
            removeObjectForKey: { key in storage.remove(key) }
        )
    }
}

/// Thread-safe in-memory backing store for the mock client.
private final class MemoryStorage: @unchecked Sendable {
    private var values: [String: Any] = [:]
    private let lock = NSLock()

    func get(_ key: String) -> Any? {
        lock.withLock { values[key] }
    }

    func set(_ key: String, _ value: Any) {
        lock.withLock { values[key] = value }
    }

    func remove(_ key: String) {
        lock.withLock { values[key] = nil }
    }
}
