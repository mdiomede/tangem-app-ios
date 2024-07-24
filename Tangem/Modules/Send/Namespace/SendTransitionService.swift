//
//  SendTransitionService.swift
//  Tangem
//
//  Created by Sergey Balashov on 23.07.2024.
//  Copyright © 2024 Tangem AG. All rights reserved.
//

import Foundation
import SwiftUI

class SendTransitionService {
    var destinationContentOffset: CGPoint = .zero
    var amountContentOffset: CGPoint = .zero

    var feeContentOffset: CGPoint = .zero {
        didSet {
            print("->> feeContentOffset", feeContentOffset)
        }
    }

    var selectedFeeContentOffset: CGPoint = .zero {
        didSet {
            print("->> selectedFeeContentOffset", selectedFeeContentOffset)
        }
    }

    // MARK: - Destination

    func transitionToDestinationStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -destinationContentOffset.y) : .move(edge: .leading)
    }

    var transitionToDestinationCompactView: AnyTransition {
        .asymmetric(insertion: .offset().combined(with: .opacity), removal: .opacity)
    }

    // MARK: - Amount

    func transitionToAmountStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -amountContentOffset.y) : .move(edge: .trailing)
    }

    var transitionToAmountCompactView: AnyTransition {
        .asymmetric(insertion: .offset().combined(with: .opacity), removal: .opacity)
    }

    // MARK: - Validators

    // MARK: - Fee

    func transitionToFeeStep(isEditMode: Bool) -> AnyTransition {
        isEditMode ? .offset(y: -feeContentOffset.y) : .move(edge: .trailing)
    }

    var transitionToFeeCompactView: AnyTransition {
        let startAnimationPointCompactView: CGFloat = -selectedFeeContentOffset.y + feeContentOffset.y
        print("->> startAnimationPointCompactView", startAnimationPointCompactView)
        return .asymmetric(
            insertion: .offset(y: startAnimationPointCompactView),
            removal: .opacity
        )
    }

    // MARK: - Summary

    var summaryViewTransition: AnyTransition {
        .asymmetric(insertion: .identity, removal: .opacity)
    }
}
