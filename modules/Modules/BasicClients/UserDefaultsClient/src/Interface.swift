import Foundation

public struct UserDefaultsClient: Sendable {
    /// Returns a String stored for the given key, or nil if absent.
    public var stringForKey: @Sendable (String) -> String?

    /// Returns a Bool stored for the given key, or false if absent.
    public var boolForKey: @Sendable (String) -> Bool

    /// Returns an Int stored for the given key, or 0 if absent.
    public var integerForKey: @Sendable (String) -> Int

    /// Returns Data stored for the given key, or nil if absent.
    public var dataForKey: @Sendable (String) -> Data?

    /// Returns an array stored for the given key, or nil if absent.
    /// `nonisolated(unsafe)` because `[Any]` is not Sendable; UserDefaults is thread-safe.
    public nonisolated(unsafe) var arrayForKey: (String) -> [Any]?

    /// Returns the raw value stored for the given key, or nil if absent.
    /// `nonisolated(unsafe)` because `Any` is not Sendable; UserDefaults is thread-safe.
    public nonisolated(unsafe) var valueForKey: (String) -> Any?

    /// Returns any object stored for the given key, or nil if absent.
    /// `nonisolated(unsafe)` because `Any` is not Sendable; UserDefaults is thread-safe.
    public nonisolated(unsafe) var objectForKey: (String) -> Any?

    /// Stores a String value for the given key.
    public var storeString: @Sendable (String, String) -> Void

    /// Stores a Bool value for the given key.
    public var storeBool: @Sendable (Bool, String) -> Void

    /// Stores a Data value for the given key.
    public var storeData: @Sendable (Data, String) -> Void

    /// Stores an Encodable value as JSON Data for the given key.
    /// `nonisolated(unsafe)` because `any Encodable` is not Sendable; UserDefaults is thread-safe.
    public nonisolated(unsafe) var storeEncodable: (any Encodable, String) -> Void

    /// Registers default values. These are used only when no value has been stored for a key.
    /// `nonisolated(unsafe)` because `[String: Any]` is not Sendable; UserDefaults is thread-safe.
    public nonisolated(unsafe) var registerDefaults: ([String: Any]) -> Void

    /// Removes the value for the given key.
    public var removeObjectForKey: @Sendable (String) -> Void

    public init(
        stringForKey: @escaping @Sendable (String) -> String?,
        boolForKey: @escaping @Sendable (String) -> Bool,
        integerForKey: @escaping @Sendable (String) -> Int,
        dataForKey: @escaping @Sendable (String) -> Data?,
        arrayForKey: @escaping (String) -> [Any]?,
        valueForKey: @escaping (String) -> Any?,
        objectForKey: @escaping (String) -> Any?,
        storeString: @escaping @Sendable (String, String) -> Void,
        storeBool: @escaping @Sendable (Bool, String) -> Void,
        storeData: @escaping @Sendable (Data, String) -> Void,
        storeEncodable: @escaping (any Encodable, String) -> Void,
        registerDefaults: @escaping ([String: Any]) -> Void,
        removeObjectForKey: @escaping @Sendable (String) -> Void
    ) {
        self.stringForKey = stringForKey
        self.boolForKey = boolForKey
        self.integerForKey = integerForKey
        self.dataForKey = dataForKey
        self.arrayForKey = arrayForKey
        self.valueForKey = valueForKey
        self.objectForKey = objectForKey
        self.storeString = storeString
        self.storeBool = storeBool
        self.storeData = storeData
        self.storeEncodable = storeEncodable
        self.registerDefaults = registerDefaults
        self.removeObjectForKey = removeObjectForKey
    }
}
