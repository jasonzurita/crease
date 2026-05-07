import Foundation

enum ZIPCreator {
    static func createArchive(containing files: [(name: String, data: Data)]) -> Data {
        var archive = Data()
        var centralDirectory = Data()
        var offsets: [UInt32] = []

        for (name, data) in files {
            let nameData = name.data(using: .utf8) ?? Data()
            let crc = crc32(data)
            offsets.append(UInt32(archive.count))

            archive += le32(0x0403_4B50)
            archive += le16(20)
            archive += le16(0)
            archive += le16(0)
            archive += le16(0)
            archive += le16(0)
            archive += le32(crc)
            archive += le32(UInt32(data.count))
            archive += le32(UInt32(data.count))
            archive += le16(UInt16(nameData.count))
            archive += le16(0)
            archive += nameData
            archive += data

            centralDirectory += le32(0x0201_4B50)
            centralDirectory += le16(20)
            centralDirectory += le16(20)
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le32(crc)
            centralDirectory += le32(UInt32(data.count))
            centralDirectory += le32(UInt32(data.count))
            centralDirectory += le16(UInt16(nameData.count))
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le16(0)
            centralDirectory += le32(0)
            centralDirectory += le32(offsets.last!)
            centralDirectory += nameData
        }

        let cdOffset = UInt32(archive.count)
        archive += centralDirectory
        archive += le32(0x0605_4B50)
        archive += le16(0)
        archive += le16(0)
        archive += le16(UInt16(files.count))
        archive += le16(UInt16(files.count))
        archive += le32(UInt32(centralDirectory.count))
        archive += le32(cdOffset)
        archive += le16(0)

        return archive
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0 ..< 8 {
                crc = (crc >> 1) ^ (crc & 1 == 1 ? 0xEDB8_8320 : 0)
            }
        }
        return ~crc
    }

    private static func le16(_ v: UInt16) -> Data {
        withUnsafeBytes(of: v.littleEndian) { Data($0) }
    }

    private static func le32(_ v: UInt32) -> Data {
        withUnsafeBytes(of: v.littleEndian) { Data($0) }
    }
}
