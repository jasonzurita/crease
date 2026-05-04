import Foundation

public extension FileManagerClient {
    static func live() -> FileManagerClient {
        .init(
            attributesOfItem: { try FileManager.default.attributesOfItem(atPath: $0) },
            fileExistsAtPath: { FileManager.default.fileExists(atPath: $0) },
            contentsOfDirectory: { path in
                try FileManager.default.contentsOfDirectory(atPath: path)
            },
            contentsOfDirectoryUrls: { url, keys, options in
                try FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: options)
            },
            contents: { FileManager.default.contents(atPath: $0) },
            removeItem: { url in
                try FileManager.default.removeItem(at: url)
            },
            createDirectory: { url, withIntermediateDirectories in
                try FileManager.default.createDirectory(
                    at: url,
                    withIntermediateDirectories: withIntermediateDirectories,
                    attributes: nil
                )
            },
            getCreationDate: { url in
                if let date = try FileManager.default.attributesOfItem(atPath: url.path)[.creationDate] as? Date {
                    return date
                } else {
                    throw FileManagerClientError.creationDateIsNil
                }
            },
            url: { try FileManager.default.url(for: $0, in: $1, appropriateFor: $2, create: $3) },
            copyItem: { from, to in
                try FileManager.default.copyItem(at: from, to: to)
            },
            writeData: { data, url in
                try data.write(to: url, options: [])
            }
        )
    }
}
