//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos
//

import Foundation
import MapKit

public extension MKMapView {
    /// Deselects all currently selected annotations.
    /// - Parameter animated: Whether the deselection should be animated.
    func deselectAllAnnotations(animated: Bool = true) {
        let selected = selectedAnnotations
        guard !selected.isEmpty else { return }

        for annotation in selected {
            deselectAnnotation(annotation, animated: animated)
        }
    }
}
