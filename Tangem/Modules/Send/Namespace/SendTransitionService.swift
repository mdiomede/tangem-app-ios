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

    var transitionToAmountView: AnyTransition {
        .offset(y: amountContentOffset.y)
            .animation(.easeOut(duration: SendView.Constants.animationDuration / 2))
    }

    var transitionToAmountCompactView: AnyTransition {
        .offset(y: amountContentOffset.y)
            .animation(.easeOut(duration: SendView.Constants.animationDuration / 2))
    }
}

extension SendTransitionService {
    enum Constants {
        static let summaryViewTransition: AnyTransition = .asymmetric(insertion: .identity, removal: .opacity)
    }
}
