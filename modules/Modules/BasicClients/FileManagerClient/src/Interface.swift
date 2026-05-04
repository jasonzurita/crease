import Foundation

public struct FileManagerClient: Sendable {
    /**
     A dictionary object that describes the attributes of the mounted file system on which path resides.
     */
    public var attributesOfItem: @Sendable (_ path: String) throws -> [FileAttributeKey: Any]

    /// Checks that a file at the specified path exists.
    public var fileExistsAtPath: @Sendable (_ path: String) -> Bool

    /// Performs a shallow search of the specified directory and returns the paths of any contained items.
    public var contentsOfDirectory: @Sendable (_ path: String) throws -> [String]

    /// Returns an Array of Urls identifying the directory entries
    public var contentsOfDirectoryUrls: @Sendable (URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL]

    /// Returns the contents in Data of the file path given.
    public var contents: @Sendable (_ path: String) -> Data?

    /// Remove the file at the given path
    public var removeItem: @Sendable (_ url: URL) throws -> Void

    /// Creates a directory on the given URL (recursively if true)
    public var createDirectory: @Sendable (_ url: URL, _ withIntermediateDirectories: Bool) throws -> Void

    /// Get the file or directory creation date by looking at its attributes
    public var getCreationDate: @Sendable (URL) throws -> Date

    /// Locates and optionally creates the specified common directory in a domain.
    public var url: @Sendable (
        _ directory: FileManager.SearchPathDirectory,
        _ domain: FileManager.SearchPathDomainMask,
        _ appropriateFor: URL?,
        _ shouldCreate: Bool
    ) throws -> URL

    /// Copies the item at the given source URL to the destination URL.
    public var copyItem: @Sendable (_ from: URL, _ to: URL) throws -> Void

    public init(
        attributesOfItem: @escaping @Sendable (_ path: String) throws -> [FileAttributeKey: Any],
        fileExistsAtPath: @escaping @Sendable (_ path: String) -> Bool,
        contentsOfDirectory: @escaping @Sendable (_ path: String) throws -> [String],
        contentsOfDirectoryUrls: @escaping @Sendable (URL, [URLResourceKey]?, FileManager.DirectoryEnumerationOptions) throws -> [URL],
        contents: @escaping @Sendable (_ path: String) -> Data?,
        removeItem: @escaping @Sendable (_ url: URL) throws -> Void,
        createDirectory: @escaping @Sendable (_ url: URL, _ withIntermediateDirectories: Bool) throws -> Void,
        getCreationDate: @escaping @Sendable (URL) throws -> Date,
        url: @escaping @Sendable (
            _ directory: FileManager.SearchPathDirectory,
            _ domain: FileManager.SearchPathDomainMask,
            _ appropriateFor: URL?,
            _ shouldCreate: Bool
        ) throws -> URL,
        copyItem: @escaping @Sendable (_ from: URL, _ to: URL) throws -> Void
    ) {
        self.attributesOfItem = attributesOfItem
        self.fileExistsAtPath = fileExistsAtPath
        self.contentsOfDirectory = contentsOfDirectory
        self.contentsOfDirectoryUrls = contentsOfDirectoryUrls
        self.contents = contents
        self.removeItem = removeItem
        self.createDirectory = createDirectory
        self.getCreationDate = getCreationDate
        self.url = url
        self.copyItem = copyItem
    }

    public enum FileManagerClientError: Error {
        case creationDateIsNil
    }
}
