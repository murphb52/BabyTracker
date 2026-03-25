import Foundation

/// A single atomic domain action with a typed input and output.
///
/// Conform to this protocol to define a focused, independently-testable business operation.
/// Concrete implementations are structs that receive their dependencies via initializer injection.
/// UseCases may compose other UseCases to coordinate multi-step operations.
@MainActor
public protocol UseCase<Input, Output> {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) throws -> Output
}
