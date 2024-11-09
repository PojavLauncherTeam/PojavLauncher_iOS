import Foundation
import SwiftUI

// https://stackoverflow.com/a/61002589
func ??<T>(lhs: Binding<Optional<T>>, rhs: T) -> Binding<T> {
    Binding(
        get: { lhs.wrappedValue ?? rhs },
        set: { lhs.wrappedValue = $0 }
    )
}

// https://gist.github.com/ConfusedVorlon/276bd7ac6c41a99ea0514a34ee9afc3d?permalink_comment_id=4096859#gistcomment-4096859
private class PublishedWrapper<T> {
    @Published private(set) var value: T
    init(_ value: Published<T>) {
        _value = value
    }
}

extension Published {
    var unofficialValue: Value {
        PublishedWrapper(self).value
    }
}

extension Published: Decodable where Value: Decodable {
    public init(from decoder: Decoder) throws {
        self.init(wrappedValue: try .init(from: decoder))
    }
}

extension Published: Encodable where Value: Encodable {
    public func encode(to encoder: Encoder) throws {
        try unofficialValue.encode(to: encoder)
    }
}

// Fix decoding optional variables for @Published & Codable
extension KeyedDecodingContainer {
    func decode<T: Decodable>(_ type: Published<T?>.Type, forKey key: Self.Key) throws -> Published<T?> {
        let value = try decodeIfPresent(type, forKey: key)
        return value ?? Published(initialValue: nil)
    }
}

// https://stackoverflow.com/a/46627527
extension String {
    subscript (bounds: CountableClosedRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start...end])
    }
    
    subscript (bounds: CountableRange<Int>) -> String {
        let start = index(startIndex, offsetBy: bounds.lowerBound)
        let end = index(startIndex, offsetBy: bounds.upperBound)
        return String(self[start..<end])
    }
}
