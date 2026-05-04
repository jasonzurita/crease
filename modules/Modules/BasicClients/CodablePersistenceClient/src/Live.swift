import FileManagerClient
import Foundation

public extension CodablePersistenceClient {
    static func `default`(
        storingIn url: URL,
        using fileManagerClient: FileManagerClient
    ) throws -> Self {
        if !fileManagerClient.fileExistsAtPath(url.path) {
            try fileManagerClient.createDirectory(url, true)
        }
        return .init(
            save: { item, fileName in
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(item)
                let fileUrl = url.appending(component: fileName)
                try data.write(to: fileUrl, options: [])
            },
            getAll: {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let urls = try fileManagerClient.contentsOfDirectoryUrls(url, nil, .skipsHiddenFiles)
                return try urls
                    .compactMap { fileManagerClient.contents($0.path) }
                    .map { try decoder.decode(A.self, from: $0) }
            },
            delete: { id in
                try fileManagerClient.removeItem(url.appending(component: id))
            }
        )
    }
}
