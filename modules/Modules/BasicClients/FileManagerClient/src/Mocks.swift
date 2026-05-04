import Foundation

public extension FileManagerClient {
    static func mock(
        attributesOfItem: @escaping @Sendable (_ path: String) throws -> [FileAttributeKey: Any] = { _ in [:] },
        fileExistsAtPath: @escaping @Sendable (_ path: String) -> Bool = { _ in true },
        contentsOfDirectory: @escaping @Sendable (_ path: String) throws -> [String] = { _ in [] },
        contentsOfDirectoryUrls: @escaping @Sendable (URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL] = { _, _, _ in [] },
        contents: @escaping @Sendable (_ path: String) -> Data? = { _ in nil },
        removeItem: @escaping @Sendable (_ url: URL) throws -> Void = { _ in },
        createDirectory: @escaping @Sendable (_ url: URL, _ withIntermediateDirectories: Bool) throws -> Void = { _, _ in },
        getCreationDate: @escaping @Sendable (URL) throws -> Date = { _ in Date() },
        url: @escaping @Sendable (FileManager.SearchPathDirectory, FileManager.SearchPathDomainMask, URL?, Bool) throws -> URL = { _, _, _, _ in URL(fileURLWithPath: "") },
        copyItem: @escaping @Sendable (_ from: URL, _ to: URL) throws -> Void = { _, _ in },
        writeData: @escaping @Sendable (_ data: Data, _ url: URL) throws -> Void = { _, _ in }
    ) -> Self {
        .init(
            attributesOfItem: attributesOfItem,
            fileExistsAtPath: fileExistsAtPath,
            contentsOfDirectory: contentsOfDirectory,
            contentsOfDirectoryUrls: contentsOfDirectoryUrls,
            contents: contents,
            removeItem: removeItem,
            createDirectory: createDirectory,
            getCreationDate: getCreationDate,
            url: url,
            copyItem: copyItem,
            writeData: writeData
        )
    }

    static func happyPath() -> Self {
        .mock()
    }
}
