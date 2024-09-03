//
//  View+Debug.swift
//  Common
//
//  Created by Ricardo Santos on 03/09/2024.
//

import Foundation
import SwiftUI

public extension View {
    func debug() -> some View {
#if DEBUG
        debugBordersDefault()
        .renderTimeTracker()
        .displaySize()
#else
self
#endif
    }
}


// 
// MARK: - Preview
//

#if canImport(SwiftUI) && DEBUG
@available(iOS 17, *)
#Preview {
    VStack {
        Circle()
            .foregroundColor(.red)
            .padding(20)
            .frame(screenWidth * 0.5)
            .debug()
    }.padding()
}

#endif
