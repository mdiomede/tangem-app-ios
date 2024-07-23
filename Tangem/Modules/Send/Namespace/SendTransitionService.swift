//
//  SendTransitionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendTransitionService: ObservableObject {
    @Published var amountContentOffset: CGPoint = .zero

    func transitionToAmountStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -amountContentOffset.y) : .move(edge: .trailing)
    }

    var transitionToAmountCompactView: AnyTransition {
        .asymmetric(insertion: .offset().combined(with: .opacity), removal: .opacity)
    }
}

extension SendTransitionService {
    enum Constants {
        static let summaryViewTransition: AnyTransition = .asymmetric(insertion: .identity, removal: .opacity)
    }
}
