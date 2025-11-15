//
//  Created by Ricardo Santos on 01/01/2023.
//  Copyright © 2024 - 2019 Ricardo Santos. All rights reserved.
//

import Foundation
import UIKit

public extension UICollectionView {
    /// Clears delegates to avoid retain cycles or memory leaks.
    func deinitialize() {
        dataSource = nil
        delegate = nil
        prefetchDataSource = nil
        dragDelegate = nil
        dropDelegate = nil
    }

    /// Safely selects an item if the indexPath exists and triggers the delegate method.
    func safelySelect(rowAt indexPath: IndexPath) {
        // Ensure main thread (required for all UICollectionView updates)
        let action = { [weak self] in
            guard let self else { return }

            // Validate section
            guard indexPath.section < numberOfSections else { return }

            // Validate row
            guard indexPath.item < numberOfItems(inSection: indexPath.section) else { return }

            // Perform the selection
            selectItem(at: indexPath,
                       animated: true,
                       scrollPosition: .centeredVertically)

            // Manually trigger delegate callback if implemented
            delegate?.collectionView?(self, didSelectItemAt: indexPath)
        }

        if Thread.isMainThread {
            action()
        } else {
            DispatchQueue.main.async(execute: action)
        }
    }
}
