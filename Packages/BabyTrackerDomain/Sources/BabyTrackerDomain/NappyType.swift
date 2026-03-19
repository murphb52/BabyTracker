import Foundation

public enum NappyType: String, CaseIterable, Codable, Sendable {
    case dry
    case wee
    case poo
    case mixed
}
