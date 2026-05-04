import Foundation

public extension UserDefaultsClient {
    static var live: Self {
        Self(
            stringForKey: { key in UserDefaults.standard.string(forKey: key) },
            boolForKey: { key in UserDefaults.standard.bool(forKey: key) },
            integerForKey: { key in UserDefaults.standard.integer(forKey: key) },
            dataForKey: { key in UserDefaults.standard.data(forKey: key) },
            arrayForKey: { key in UserDefaults.standard.array(forKey: key) },
            valueForKey: { key in UserDefaults.standard.value(forKey: key) },
            objectForKey: { key in UserDefaults.standard.object(forKey: key) },
            storeString: { value, key in UserDefaults.standard.set(value, forKey: key) },
            storeBool: { value, key in UserDefaults.standard.set(value, forKey: key) },
            storeData: { value, key in UserDefaults.standard.set(value, forKey: key) },
            storeEncodable: { value, key in
                let data = try? JSONEncoder().encode(value)
                UserDefaults.standard.set(data, forKey: key)
            },
            registerDefaults: { defaults in UserDefaults.standard.register(defaults: defaults) },
            removeObjectForKey: { key in UserDefaults.standard.removeObject(forKey: key) }
        )
    }
}
