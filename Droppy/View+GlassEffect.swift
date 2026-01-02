
import SwiftUI

extension View {
    /// Applies a glass effect background to the view.
    /// - Parameter material: The material to use for the glass effect (default is .regular).
    /// - Returns: A view with the glass effect applied.
    func glassEffect(_ material: Material = .regular) -> some View {
        self.background(material)
    }
}
