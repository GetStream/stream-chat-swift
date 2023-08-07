/// A differentiable section with model and array of elements.
///
/// Arrays are can not be identify each one and comparing whether has updated from other one.
/// ArraySection is a generic wrapper to hold a model to allow it.
struct ArraySection<Model: Differentiable, Element: Differentiable>: DifferentiableSection {
    /// The model of section for differentiated with other section.
    var model: Model
    /// The array of element in the section.
    var elements: [Element]

    /// An identifier value that of model for difference calculation.
    @inlinable
    var differenceIdentifier: Model.DifferenceIdentifier {
        return model.differenceIdentifier
    }

    /// Creates a section with the model and the elements.
    ///
    /// - Parameters:
    ///   - model: A differentiable model of section.
    ///   - elements: The collection of element in the section.
    init<C: Collection>(model: Model, elements: C) where C.Element == Element {
        self.model = model
        self.elements = Array(elements)
    }

    /// Creates a new section reproducing the given source section with replacing the elements.
    ///
    /// - Parameters:
    ///   - source: A source section to reproduce.
    ///   - elements: The collection of elements for the new section.
    @inlinable
    init<C: Collection>(source: ArraySection, elements: C) where C.Element == Element {
        self.init(model: source.model, elements: elements)
    }

    /// Indicate whether the content of `self` is equals to the content of
    /// the given source section.
    ///
    /// - Note: It's compared by the model of `self` and the specified section.
    ///
    /// - Parameters:
    ///   - source: A source section to compare.
    ///
    /// - Returns: A Boolean value indicating whether the content of `self` is equals
    ///            to the content of the given source section.
    @inlinable
    func isContentEqual(to source: ArraySection) -> Bool {
        return model.isContentEqual(to: source.model)
    }
}

extension ArraySection: Equatable where Model: Equatable, Element: Equatable {
    static func == (lhs: ArraySection, rhs: ArraySection) -> Bool {
        return lhs.model == rhs.model && lhs.elements == rhs.elements
    }
}

extension ArraySection: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
        ArraySection(
            model: \(model),
            elements: \(elements)
        )
        """
    }
}
